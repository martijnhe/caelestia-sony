pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

// Device details, auto power-off and switching between paired Sony devices
ColumnLayout {
    id: root

    spacing: Tokens.spacing.small

    Component.onCompleted: Sony.refreshDevices()

    SnSection {
        visible: Sony.connected
        text: Tr.tr("Details")
    }

    Repeater {
        model: Sony.connected ? [
            [Tr.tr("Model"), Sony.name],
            [Tr.tr("Address"), Sony.address],
            [Tr.tr("Protocol"), Sony.snap?.protocol ?? "–"],
            [Tr.tr("Codec"), Sony.snap?.codec ?? "–"],
            [Tr.tr("Firmware"), Sony.snap?.firmware ?? "–"]
        ] : []

        RowLayout {
            id: info

            required property var modelData

            Layout.fillWidth: true
            Layout.rightMargin: Tokens.padding.extraSmall

            StyledText {
                Layout.preferredWidth: 80
                text: info.modelData[0]
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }

            StyledText {
                Layout.fillWidth: true
                text: info.modelData[1]
                font: Tokens.font.body.small
                elide: Text.ElideMiddle
            }
        }
    }

    SnSection {
        visible: Sony.available("autoPowerOff")
        text: Tr.tr("Auto power-off")
    }

    Flow {
        Layout.fillWidth: true
        visible: Sony.available("autoPowerOff")
        spacing: Tokens.spacing.extraSmall

        Repeater {
            model: Sony.autoPowerOffLabels

            SnChip {
                required property string modelData
                required property int index

                text: modelData
                checked: Sony.featureState("autoPowerOff") === "valid" && Sony.snap?.autoPowerOff === index
                busy: checked && Sony.pending === "autoPowerOff"
                disabled: Sony.pending !== ""
                onClicked: Sony.setAutoPowerOff(index)
            }
        }
    }

    SnSection {
        text: Tr.tr("Paired Sony devices")
    }

    StyledText {
        visible: Sony.devices.length === 0
        text: Tr.tr("No paired Sony devices found. Pair them in Bluetooth first.")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }

    Repeater {
        model: Sony.devices

        RowLayout {
            id: dev

            required property var modelData
            readonly property bool current: Sony.connected && Sony.address.toUpperCase() === modelData.address.toUpperCase()

            Layout.fillWidth: true
            Layout.rightMargin: Tokens.padding.extraSmall
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: /^WF|LinkBuds/i.test(dev.modelData.name) ? "earbuds" : "headphones"
                color: dev.current ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                fill: dev.current ? 1 : 0
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: dev.modelData.name
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: dev.current ? Tr.tr("Connected to sonyd") : dev.modelData.systemConnected ? Tr.tr("Bluetooth connected") : dev.modelData.address
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }
            }

            TextButton {
                type: dev.current ? TextButton.Text : TextButton.Tonal
                text: Sony.pending === "connect" && !dev.current ? Tr.tr("…") : dev.current ? Tr.tr("Disconnect") : Tr.tr("Connect")
                disabled: Sony.pending !== ""
                onClicked: dev.current ? Sony.disconnect() : Sony.connectTo(dev.modelData.address, dev.modelData.name)
            }
        }
    }
}
