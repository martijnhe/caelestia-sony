import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    spacing: Tokens.spacing.small

    SnSection {
        text: Tr.tr("Settings")
    }

    SnToggle {
        label: Tr.tr("Battery in bar")
        description: Tr.tr("Show the level under the icon")
        isOn: Sony.settings.showBattery
        onToggled: value => Sony.settings.showBattery = value
    }

    SnToggle {
        label: Tr.tr("Hide when disconnected")
        description: Tr.tr("Remove the icon from the bar when no headphones are connected")
        isOn: Sony.settings.hideWhenOff
        onToggled: value => Sony.settings.hideWhenOff = value
    }

    SnToggle {
        label: Tr.tr("Notifications")
        description: Tr.tr("Connect, disconnect, low battery and errors")
        isOn: Sony.settings.notifications
        onToggled: value => Sony.settings.notifications = value
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall

        StyledText {
            Layout.fillWidth: true
            text: Tr.tr("Low battery warning at")
        }

        StyledSpinBox {
            from: 5
            to: 50
            stepSize: 5
            value: Sony.settings.lowBattery
            onValueModified: Sony.settings.lowBattery = value
        }
    }

    SnSection {
        text: Tr.tr("Daemon")
    }

    Repeater {
        model: [
            [Tr.tr("sonyd"), Sony.installed ? Tr.tr("installed") : Tr.tr("not found in PATH")],
            [Tr.tr("Service"), Sony.serviceState],
            [Tr.tr("Socket"), Sony.socketPath]
        ]

        RowLayout {
            id: info

            required property var modelData

            Layout.fillWidth: true
            Layout.rightMargin: Tokens.padding.extraSmall

            StyledText {
                Layout.preferredWidth: 64
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
}
