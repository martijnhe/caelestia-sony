import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Headphones icon with battery level. Filled while noise cancelling is on,
// outlined in ambient mode, dimmed when disconnected.
Item {
    id: root

    required property color colour
    readonly property bool hidden: Sony.settings.hideWhenOff && !Sony.connected

    visible: !hidden
    implicitWidth: hidden ? 0 : layout.implicitWidth
    implicitHeight: hidden ? 0 : layout.implicitHeight

    ColumnLayout {
        id: layout

        spacing: 0

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            animate: true
            text: {
                if (!Sony.connected)
                    return "headset_off";
                return Sony.isTws ? "earbuds" : "headphones";
            }
            color: Sony.connected && Sony.batteryLevel >= 0 && Sony.batteryLevel <= Sony.settings.lowBattery && !Sony.charging ? Colours.palette.m3error : root.colour
            opacity: Sony.connected ? 1 : 0.5
            fill: Sony.connected && Sony.noiseMode === "cancelling" ? 1 : 0
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            visible: Sony.settings.showBattery && Sony.connected && Sony.batteryLevel >= 0
            text: Sony.charging ? `${Sony.batteryLevel}+` : `${Sony.batteryLevel}`
            color: root.colour
            font: Tokens.font.label.small
        }
    }
}
