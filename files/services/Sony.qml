pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.I18n

// Client for sonyd (github.com/marconvcm/sony-device-center) over its Unix socket,
// using the structured JSON protocol: one request line per connection.
Singleton {
    id: root

    readonly property string socketPath: `${Quickshell.env("XDG_RUNTIME_DIR") || `/tmp/sony-device-center-${uid}`}/sony-device-center.sock`
    property string uid

    // Daemon
    property bool installed: true
    property bool daemonOnline: false
    property string serviceState: "unknown"
    property bool busy: false
    property string pending // method currently being written
    property string lastError

    // Device
    property var snap: null
    property list<var> devices: []
    readonly property bool connected: daemonOnline && (snap?.connected ?? false)
    readonly property string connectionState: snap?.connectionState ?? "disconnected"
    readonly property string name: snap?.name || Tr.tr("Sony headphones")
    readonly property string address: snap?.address ?? ""
    readonly property var caps: snap?.capabilities ?? ({})
    readonly property var battery: snap?.battery ?? ({})
    readonly property bool isTws: battery.left !== null && battery.left !== undefined
    readonly property int batteryLevel: {
        if (!connected)
            return -1;
        if (isTws) {
            const buds = [battery.left, battery.right].filter(v => v !== null && v !== undefined);
            return buds.length ? Math.min(...buds) : -1;
        }
        return battery.main ?? -1;
    }
    readonly property bool charging: battery.charging ?? false
    readonly property string noiseMode: snap?.noiseControl?.mode ?? "off" // off | cancelling | ambient
    readonly property int ambientLevel: (snap?.noiseControl?.ambientLevel ?? 0) || lastAmbient
    property int lastAmbient: 10 // sonyd reports 0 outside ambient mode
    readonly property bool focusOnVoice: snap?.noiseControl?.focusOnVoice ?? false
    readonly property var eq: snap?.equalizer ?? ({ preset: 0, presetName: "Off", clearBass: 0, bands: [] })
    readonly property bool tenBand: caps.tenBandEqualizer ?? false

    readonly property list<var> presets: tenBand ? [
        { id: 0x00, name: Tr.tr("Off") },
        { id: 0xa0, name: Tr.tr("Custom") }
    ] : [
        { id: 0x00, name: Tr.tr("Off") },
        { id: 0x16, name: Tr.tr("Bass Boost") },
        { id: 0x15, name: Tr.tr("Treble Boost") },
        { id: 0x14, name: Tr.tr("Vocal") },
        { id: 0x10, name: Tr.tr("Bright") },
        { id: 0x11, name: Tr.tr("Excited") },
        { id: 0x12, name: Tr.tr("Mellow") },
        { id: 0x13, name: Tr.tr("Relaxed") },
        { id: 0x17, name: Tr.tr("Speech") },
        { id: 0xa0, name: Tr.tr("Manual") }
    ]
    readonly property list<string> bandLabels: tenBand ? ["31", "63", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"] : ["400", "1k", "2.5k", "6.3k", "16k"]
    readonly property list<string> autoPowerOffLabels: [Tr.tr("Off"), Tr.tr("5 min"), Tr.tr("15 min"), Tr.tr("30 min"), Tr.tr("1 h"), Tr.tr("3 h")]

    // UI state kept here so it survives the popout unloading
    property string page: "sound" // sound | eq | device | settings
    property alias settings: settingsAdapter

    property int nextId: 1
    property bool lowBatteryWarned

    function available(feature: string): bool {
        return connected && (caps[feature] ?? false);
    }

    // Whether a reading is confirmed: unknown, unsupported, valid or stale
    function featureState(feature: string): string {
        return snap?.features?.[feature]?.availability ?? "unknown";
    }

    function batteryText(value: var): string {
        return value === null || value === undefined ? "–" : `${value}%`;
    }

    function fail(message: string): void {
        lastError = message;
        if (settings.notifications)
            Toaster.toast(Tr.tr("Sony headphones"), message, "headset_off", Toast.Error);
    }

    // Sends one JSON request; onDone(ok, data, error) runs once
    function call(method: string, params: var, onDone: var): void {
        const sock = requestComp.createObject(root, {
            payload: JSON.stringify({
                version: 1,
                id: nextId++,
                method,
                params: params ?? {}
            }),
            onDone: onDone ?? null
        });
        sock.connected = true;
    }

    // State-changing request: show pending state, apply the returned snapshot
    function act(method: string, params: var): void {
        pending = method;
        call(method, params, (ok, data, error) => {
            pending = "";
            if (ok) {
                lastError = "";
                if (data && typeof data === "object" && "connected" in data)
                    snap = data;
                else
                    refresh();
            } else {
                fail(error);
                refresh();
            }
        });
    }

    function refresh(): void {
        serviceCheck.running = true;
        call("snapshot", null, (ok, data, error) => {
            const wasConnected = connected;
            daemonOnline = ok || error !== "unreachable";
            if (ok) {
                snap = data;
                if ((data?.noiseControl?.ambientLevel ?? 0) > 0)
                    lastAmbient = data.noiseControl.ambientLevel;
            } else if (!daemonOnline)
                snap = null;
            if (settings.notifications && wasConnected !== connected && snap)
                Toaster.toast(connected ? Tr.tr("Headphones connected") : Tr.tr("Headphones disconnected"), name, connected ? "headphones" : "headset_off", Toast.Info);
            checkBattery();
        });
    }

    function refreshDevices(): void {
        call("devices", null, (ok, data) => {
            if (ok)
                devices = (data ?? []).map(d => ({
                            name: d.name || d.address,
                            address: d.address,
                            paired: d.paired,
                            systemConnected: d.systemConnected
                        }));
        });
    }

    function checkBattery(): void {
        if (batteryLevel < 0 || charging) {
            lowBatteryWarned = false;
            return;
        }
        if (batteryLevel <= settings.lowBattery && !lowBatteryWarned) {
            lowBatteryWarned = true;
            if (settings.notifications)
                Toaster.toast(Tr.tr("Headphone battery low"), Tr.tr("%1 is at %2%").arg(name).arg(batteryLevel), "battery_alert", Toast.Warning);
        } else if (batteryLevel > settings.lowBattery + 5) {
            lowBatteryWarned = false;
        }
    }

    // ---------- Actions ----------

    function setNoiseMode(mode: string): void {
        if (mode === "cancelling")
            act("anc", {
                enabled: true
            });
        else if (mode === "ambient")
            act("ambient", {
                level: Math.max(1, ambientLevel),
                focusOnVoice
            });
        else
            act("anc", {
                enabled: false
            });
    }

    function cycleNoiseMode(): void {
        const modes = ["cancelling", "ambient", "off"].filter(m => m === "off" || (m === "cancelling" ? available("anc") : available("ambient")));
        setNoiseMode(modes[(modes.indexOf(noiseMode) + 1) % modes.length]);
    }

    function setAmbient(level: int, voice: bool): void {
        lastAmbient = Math.max(1, Math.min(20, level));
        act("ambient", {
            level: Math.max(1, Math.min(20, level)),
            focusOnVoice: voice
        });
    }

    function setPreset(id: int): void {
        act("eqPreset", {
            preset: id
        });
    }

    function setCustomEq(clearBass: int, bands: var): void {
        act("eqCustom", tenBand ? {
            bands
        } : {
            clearBass,
            bands
        });
    }

    function setToggle(method: string, enabled: bool): void {
        act(method, {
            enabled
        });
    }

    function setAutoPowerOff(index: int): void {
        act("autoPowerOff", {
            index
        });
    }

    function connectTo(address: string, deviceName: string): void {
        act("connect", {
            address,
            name: deviceName
        });
    }

    function disconnect(): void {
        act("disconnect", null);
    }

    function setDaemonRunning(running: bool): void {
        busy = true;
        daemonProc.command = ["systemctl", "--user", running ? "start" : "stop", "sonyd.service"];
        daemonProc.running = true;
    }

    function openApp(): void {
        Quickshell.execDetached(["sony-device-center"]);
    }

    Component {
        id: requestComp

        Socket {
            id: sock

            property string payload
            property var onDone
            property bool finished

            function finish(ok: bool, data: var, error: string): void {
                if (finished)
                    return;
                finished = true;
                timeout.stop();
                onDone?.(ok, data, error);
                connected = false;
                Qt.callLater(() => sock.destroy());
            }

            path: root.socketPath

            onConnectedChanged: {
                if (connected) {
                    write(payload + "\n");
                    flush();
                } else if (!finished) {
                    finish(false, null, Tr.tr("Connection closed by sonyd"));
                }
            }
            onError: finish(false, null, "unreachable")

            parser: SplitParser {
                onRead: line => {
                    let res = null;
                    try {
                        res = JSON.parse(line);
                    } catch (e) {
                        return sock.finish(false, null, Tr.tr("Invalid reply from sonyd"));
                    }
                    if (res.ok)
                        sock.finish(true, res.data, "");
                    else
                        sock.finish(false, null, res.error?.message || res.error?.code || Tr.tr("Request failed"));
                }
            }

            property Timer timeout: Timer {
                interval: 35000
                running: true
                onTriggered: sock.finish(false, null, Tr.tr("sonyd did not answer in time"))
            }
        }
    }

    FileView {
        id: settingsFile

        path: `${Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"}/caelestia/sony.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: settingsAdapter

            property bool showBattery: true
            property bool notifications: true
            property int lowBattery: 20
            property bool hideWhenOff: false
        }
    }

    Process {
        running: true
        command: ["id", "-u"]
        stdout: StdioCollector {
            onStreamFinished: root.uid = text.trim()
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v sonyd"]
        onExited: code => root.installed = code === 0
    }

    Process {
        id: serviceCheck

        command: ["systemctl", "--user", "is-active", "sonyd.service"]
        stdout: StdioCollector {
            onStreamFinished: root.serviceState = text.trim() || "unknown"
        }
    }

    Process {
        id: daemonProc

        onExited: {
            root.busy = false;
            delayedRefresh.restart();
        }
    }

    Timer {
        id: delayedRefresh

        interval: 1500
        onTriggered: {
            root.refresh();
            root.refreshDevices();
        }
    }

    Timer {
        interval: root.connected ? 5000 : 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
