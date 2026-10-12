pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils

ColumnLayout {
    id: root

    spacing: Tokens.spacing.small

    // Battery
    SnSection {
        visible: Sony.available("battery")
        text: Sony.charging ? Tr.tr("Battery · charging") : Tr.tr("Battery")
    }

    RowLayout {
        Layout.fillWidth: true
        visible: Sony.available("battery")
        spacing: Tokens.spacing.small

        Repeater {
            model: Sony.isTws ? [
                {
                    label: Tr.tr("Left"),
                    value: Sony.battery.left
                },
                {
                    label: Tr.tr("Right"),
                    value: Sony.battery.right
                },
                {
                    label: Tr.tr("Case"),
                    value: Sony.battery.case
                }
            ] : [
                {
                    label: Sony.name,
                    value: Sony.battery.main
                }
            ]

            StyledRect {
                id: tile

                required property var modelData
                readonly property bool known: modelData.value !== null && modelData.value !== undefined
                readonly property bool low: known && modelData.value <= Sony.settings.lowBattery && !Sony.charging

                Layout.fillWidth: true
                implicitHeight: tileRow.implicitHeight + Tokens.padding.small * 2
                radius: Tokens.rounding.medium
                color: Colours.tPalette.m3surfaceContainerHigh

                RowLayout {
                    id: tileRow

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.small
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: tile.known ? Icons.getBatteryIcon(tile.modelData.value / 100, Sony.charging) : "battery_unknown"
                        color: tile.low ? Colours.palette.m3error : Colours.palette.m3primary
                        fill: 1
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: Sony.batteryText(tile.modelData.value)
                            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                            color: tile.low ? Colours.palette.m3error : Colours.palette.m3onSurface
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: tile.modelData.label
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    // Noise control
    SnSection {
        visible: Sony.available("anc") || Sony.available("ambient")
        text: Sony.featureState("noiseControl") === "unknown" ? Tr.tr("Noise control · reading…") : Tr.tr("Noise control")
    }

    RowLayout {
        Layout.fillWidth: true
        visible: Sony.available("anc") || Sony.available("ambient")
        spacing: Tokens.spacing.extraSmall

        Repeater {
            model: [
                {
                    id: "cancelling",
                    label: Tr.tr("Noise cancelling"),
                    icon: "noise_control_off",
                    ok: Sony.available("anc")
                },
                {
                    id: "ambient",
                    label: Tr.tr("Ambient"),
                    icon: "hearing",
                    ok: Sony.available("ambient")
                },
                {
                    id: "off",
                    label: Tr.tr("Off"),
                    icon: "do_not_disturb_on",
                    ok: true
                }
            ]

            SnChip {
                required property var modelData

                Layout.fillWidth: true
                visible: modelData.ok
                text: modelData.label
                icon: modelData.icon
                checked: Sony.noiseMode === modelData.id
                busy: checked && (Sony.pending === "anc" || Sony.pending === "ambient")
                disabled: Sony.pending !== ""
                onClicked: Sony.setNoiseMode(modelData.id)
            }
        }
    }

    // Ambient level and voice focus
    ColumnLayout {
        Layout.fillWidth: true
        visible: Sony.noiseMode === "ambient" && Sony.available("ambient")
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: Tokens.padding.extraSmall
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: "hearing"
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledSlider {
                id: ambientSlider

                Layout.fillWidth: true
                implicitHeight: Tokens.padding.medium * 3
                from: 1
                to: 20
                stepSize: 1
                value: Sony.ambientLevel
                interactionOnMove: false
                onInteraction: v => Sony.setAmbient(Math.round(v), Sony.focusOnVoice)
            }

            StyledText {
                Layout.preferredWidth: 24
                horizontalAlignment: Text.AlignRight
                text: Math.round(ambientSlider.value)
                font: Tokens.font.body.small
            }
        }

        SnToggle {
            visible: Sony.caps.focusOnVoice ?? false
            label: Tr.tr("Focus on voice")
            description: Tr.tr("Let voices through, reduce other ambient sound")
            isOn: Sony.focusOnVoice
            busy: Sony.pending === "ambient"
            onToggled: value => Sony.setAmbient(Sony.ambientLevel, value)
        }
    }

    // Audio features
    SnSection {
        visible: Sony.available("dsee") || Sony.available("speakToChat") || Sony.available("adaptiveVolume")
        text: Tr.tr("Audio")
    }

    SnToggle {
        visible: Sony.available("dsee")
        label: Tr.tr("DSEE Extreme")
        description: Tr.tr("Upscale compressed music")
        isOn: Sony.snap?.dsee ?? false
        busy: Sony.pending === "dsee"
        onToggled: value => Sony.setToggle("dsee", value)
    }

    SnToggle {
        visible: Sony.available("speakToChat")
        label: Tr.tr("Speak-to-Chat")
        description: Tr.tr("Pause music when you start talking")
        isOn: Sony.snap?.speakToChat ?? false
        busy: Sony.pending === "speakToChat"
        onToggled: value => Sony.setToggle("speakToChat", value)
    }

    SnToggle {
        visible: Sony.available("adaptiveVolume")
        label: Tr.tr("Adaptive volume")
        description: Tr.tr("Adjust volume to your surroundings")
        isOn: Sony.snap?.adaptiveVolume ?? false
        busy: Sony.pending === "adaptiveVolume"
        onToggled: value => Sony.setToggle("adaptiveVolume", value)
    }
}
