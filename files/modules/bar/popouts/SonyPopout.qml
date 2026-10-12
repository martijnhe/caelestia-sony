pragma ComponentBehavior: Bound

import "./sony"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    required property PopoutState popouts

    width: 380
    implicitWidth: 380
    spacing: Tokens.spacing.small

    Component.onCompleted: {
        Sony.refresh();
        if (Sony.devices.length === 0)
            Sony.refreshDevices();
    }

    // Header
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.padding.medium
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: Sony.connected ? (Sony.isTws ? "earbuds" : "headphones") : "headset_off"
            color: Sony.connected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            fill: 1
            fontStyle: Tokens.font.icon.large
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: Sony.connected ? Sony.name : Tr.tr("Sony headphones")
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: {
                    if (Sony.busy)
                        return Tr.tr("Working…");
                    if (!Sony.installed)
                        return Tr.tr("sonyd not installed");
                    if (!Sony.daemonOnline)
                        return Tr.tr("Daemon not running");
                    if (Sony.connectionState === "connecting")
                        return Tr.tr("Connecting…");
                    if (!Sony.connected)
                        return Tr.tr("Not connected");
                    const parts = [];
                    if (Sony.batteryLevel >= 0)
                        parts.push(Sony.charging ? Tr.tr("%1% charging").arg(Sony.batteryLevel) : `${Sony.batteryLevel}%`);
                    if (Sony.snap?.codec && Sony.snap.codec !== "Unknown")
                        parts.push(Sony.snap.codec);
                    parts.push(Sony.noiseMode === "cancelling" ? Tr.tr("Noise cancelling") : Sony.noiseMode === "ambient" ? Tr.tr("Ambient %1").arg(Sony.ambientLevel) : Tr.tr("Noise control off"));
                    return parts.join(" · ");
                }
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }

        IconButton {
            type: IconButton.Text
            icon: "settings"
            onClicked: Sony.page = Sony.page === "settings" ? "sound" : "settings"
        }

        StyledSwitch {
            checked: Sony.daemonOnline
            disabled: Sony.busy || !Sony.installed
            onToggled: Sony.setDaemonRunning(checked)
        }
    }

    // Tabs
    RowLayout {
        Layout.fillWidth: true
        visible: Sony.connected && Sony.page !== "settings"
        spacing: Tokens.spacing.extraSmall

        Repeater {
            model: [
                {
                    id: "sound",
                    label: Tr.tr("Sound"),
                    icon: "graphic_eq"
                },
                {
                    id: "eq",
                    label: Tr.tr("Equalizer"),
                    icon: "equalizer"
                },
                {
                    id: "device",
                    label: Tr.tr("Device"),
                    icon: "headphones"
                }
            ]

            SnChip {
                required property var modelData

                Layout.fillWidth: true
                visible: modelData.id !== "eq" || Sony.available("equalizer")
                text: modelData.label
                icon: modelData.icon
                checked: Sony.page === modelData.id
                onClicked: Sony.page = modelData.id
            }
        }
    }

    // Error banner
    StyledRect {
        Layout.fillWidth: true
        visible: Sony.lastError !== "" || (Sony.snap?.lastError ?? "") !== ""
        implicitHeight: errorRow.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.medium
        color: Colours.palette.m3errorContainer

        RowLayout {
            id: errorRow

            anchors.fill: parent
            anchors.margins: Tokens.padding.small
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "error"
                color: Colours.palette.m3onErrorContainer
            }

            StyledText {
                Layout.fillWidth: true
                text: Sony.lastError || Sony.snap?.lastError || ""
                color: Colours.palette.m3onErrorContainer
                font: Tokens.font.body.small
                wrapMode: Text.Wrap
            }

            IconButton {
                type: IconButton.Text
                icon: "close"
                visible: Sony.lastError !== ""
                onClicked: Sony.lastError = ""
            }
        }
    }

    // Not running or not connected
    StyledText {
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        visible: Sony.page !== "settings" && !Sony.daemonOnline
        text: Sony.installed ? Tr.tr("Turn on the switch to start sonyd, which keeps the Bluetooth link to your headphones.") : Tr.tr("Install sony-device-center (sonyd and sonyctl) to use this widget.")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
        wrapMode: Text.Wrap
    }

    // Page body
    Loader {
        Layout.fillWidth: true
        sourceComponent: {
            if (Sony.page === "settings")
                return settingsPage;
            if (!Sony.daemonOnline)
                return null;
            if (!Sony.connected)
                return devicePage;
            switch (Sony.page) {
            case "eq":
                return eqPage;
            case "device":
                return devicePage;
            }
            return soundPage;
        }
    }

    // Footer
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small
        spacing: Tokens.spacing.small

        IconTextButton {
            Layout.fillWidth: true
            inactiveColour: Colours.palette.m3primaryContainer
            inactiveOnColour: Colours.palette.m3onPrimaryContainer
            verticalPadding: Tokens.padding.extraSmall
            text: Tr.tr("Open Sony Device Center")
            icon: "open_in_new"
            onClicked: Sony.openApp()
        }

        IconButton {
            type: IconButton.Tonal
            icon: "noise_aware"
            visible: Sony.connected
            disabled: Sony.pending !== ""
            onClicked: Sony.cycleNoiseMode()
        }
    }

    Component {
        id: soundPage

        SnSoundPage {}
    }

    Component {
        id: eqPage

        SnEqPage {}
    }

    Component {
        id: devicePage

        SnDevicePage {}
    }

    Component {
        id: settingsPage

        SnSettingsPage {}
    }
}
