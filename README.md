# Caelestia Sony headphones widget

A bar icon and popout for the [Caelestia shell](https://github.com/caelestia-dots/shell) that controls
Sony headphones through [Sony Device Center](https://github.com/marconvcm/sony-device-center)'s
`sonyd` daemon. Pure QML: it speaks sonyd's structured JSON protocol over its Unix socket
(`$XDG_RUNTIME_DIR/sony-device-center.sock`). No extra binaries.

Built against `caelestia-shell` 2.5.0, `quickshell-git` 0.3.1 and sonyd's IPC protocol version 1.

## Features

**Bar icon**: headphones or earbuds icon with battery level underneath. Filled while noise
cancelling is on, red when the battery is low, dimmed (or hidden, optional) when disconnected.

**Header**: device name, battery, codec and noise mode; switch to start/stop the `sonyd` user
service; settings.

**Sound**
- battery: one tile for headphones, left / right / case tiles for earbuds, charging state
- noise control: Noise cancelling / Ambient / Off
- ambient level 1–20 and Focus on voice
- DSEE Extreme, Speak-to-Chat, Adaptive volume

**Equalizer**
- presets (Off, Bass Boost, Treble Boost, Vocal, Bright, Excited, Mellow, Relaxed, Speech, Manual)
- custom 5-band EQ with Clear Bass (±10), or 10 bands (0–12) on models like the WH-1000XM6
- Flat, Reset and Apply

**Device**: model, address, protocol, codec, firmware; auto power-off (Off, 5/15/30 min, 1/3 h);
switch between paired Sony devices or disconnect.

**Footer**: open the full Sony Device Center app; cycle noise mode.

**Notifications**: connected/disconnected, low battery (threshold configurable), failed actions.

**Settings** (in the popout, stored in `~/.config/caelestia/sony.json`): battery in bar, hide when
disconnected, notifications, low battery threshold.

Only controls the connected model supports are shown. Readings the daemon hasn't confirmed yet
show as "reading…" or "–".

## Requirements

`sonyd` from Sony Device Center in your `PATH` (build it from the repo above).

## Install

```bash
./install.sh
kill $(pgrep -x qs); qs -c caelestia -n -d
```

This adds the widget to the user copy of the Caelestia config at `~/.config/quickshell/caelestia`
(created from `/etc/xdg/quickshell/caelestia` if missing), patches four existing files with marked
lines, adds its icon to a shared widget group above the clock (bar entry `plugins` in
`~/.config/caelestia/shell.json`), and installs and enables a
`sonyd` systemd user service if you don't have one.

It coexists with other widgets installed the same way (like
[caelestia-syncthing](../caelestia-syncthing)). After a `caelestia-shell` update:

```bash
rm -rf ~/.config/quickshell/caelestia
~/Projects/caelestia-syncthing/install.sh
~/Projects/caelestia-sony/install.sh
~/Projects/caelestia-tailscale/install.sh
~/Projects/caelestia-webcam/install.sh
~/Projects/caelestia-screens/install.sh
```

Every install checks the shared **plugins** bar section (the widget group above the clock) and
creates or repairs it if any part is missing: the group file, the two edits in `Bar.qml` (restored
from Caelestia's own copy if they were mangled), and an enabled `plugins` entry in `bar.entries`.
It ends with `Plugins bar section: OK`, or stops and says what's wrong.

## Uninstall

```bash
./uninstall.sh
```

Removes the widget's files and marked edits, the `sony` bar entry, and the sonyd user service if
this installer created it. Other widgets stay.

## Files

| File | Purpose |
| --- | --- |
| `files/services/Sony.qml` | Singleton: socket client, state, actions, settings |
| `files/modules/bar/components/status/SonyStatus.qml` | Bar icon |
| `files/modules/bar/popouts/SonyPopout.qml` | Popout: header, tabs, footer |
| `files/modules/bar/popouts/sony/` | Sound, Equalizer, Device and Settings pages, small components |
| `patch.py` | Adds/removes the marked edits to Caelestia files |
