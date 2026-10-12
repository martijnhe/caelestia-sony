pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

// Equalizer presets plus custom bands (5 bands and Clear Bass at -10..10,
// or 10 raw bands at 0..12 on models like the WH-1000XM6)
ColumnLayout {
    id: root

    readonly property int bandMin: Sony.tenBand ? 0 : -10
    readonly property int bandMax: Sony.tenBand ? 12 : 10
    property list<int> draftBands: []
    property int draftClearBass: 0
    readonly property bool custom: Sony.eq.preset === 0xa0

    function resetDraft(): void {
        const bands = Sony.eq.bands ?? [];
        const count = Sony.bandLabels.length;
        draftBands = Array.from({
            length: count
        }, (_, i) => bands[i] ?? (Sony.tenBand ? 6 : 0));
        draftClearBass = Sony.eq.clearBass ?? 0;
    }

    function apply(): void {
        Sony.setCustomEq(draftClearBass, draftBands);
    }

    spacing: Tokens.spacing.small

    Component.onCompleted: resetDraft()

    Connections {
        function onEqChanged(): void {
            if (Sony.pending !== "eqCustom")
                root.resetDraft();
        }

        target: Sony
    }

    SnSection {
        text: Sony.featureState("equalizer") === "unknown" ? Tr.tr("Preset · reading…") : Tr.tr("Preset · %1").arg(Sony.eq.presetName ?? "")
    }

    Flow {
        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall

        Repeater {
            model: Sony.presets

            SnChip {
                required property var modelData

                text: modelData.name
                checked: Sony.eq.preset === modelData.id
                busy: checked && Sony.pending === "eqPreset"
                disabled: Sony.pending !== ""
                onClicked: Sony.setPreset(modelData.id)
            }
        }
    }

    SnSection {
        text: Sony.tenBand ? Tr.tr("Custom · 10 bands") : Tr.tr("Custom · 5 bands, ±10")
    }

    StyledText {
        Layout.fillWidth: true
        visible: !root.custom
        text: Tr.tr("Applying custom bands switches the preset to %1.").arg(Sony.tenBand ? Tr.tr("Custom") : Tr.tr("Manual"))
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
        wrapMode: Text.Wrap
    }

    BandRow {
        visible: !Sony.tenBand && (Sony.caps.clearBass ?? false)
        label: Tr.tr("Clear Bass")
        value: root.draftClearBass
        onMoved: v => root.draftClearBass = v
    }

    Repeater {
        model: Sony.bandLabels

        BandRow {
            required property string modelData
            required property int index

            label: `${modelData} Hz`
            value: root.draftBands[index] ?? 0
            minimum: root.bandMin
            maximum: root.bandMax
            onMoved: v => {
                const bands = [...root.draftBands];
                bands[index] = v;
                root.draftBands = bands;
            }
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignRight
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        TextButton {
            type: TextButton.Text
            text: Tr.tr("Flat")
            onClicked: {
                root.draftBands = root.draftBands.map(() => Sony.tenBand ? 6 : 0);
                root.draftClearBass = 0;
            }
        }

        TextButton {
            type: TextButton.Text
            text: Tr.tr("Reset")
            onClicked: root.resetDraft()
        }

        TextButton {
            text: Sony.pending === "eqCustom" ? Tr.tr("Applying…") : Tr.tr("Apply")
            disabled: Sony.pending !== ""
            onClicked: root.apply()
        }
    }

    component BandRow: RowLayout {
        id: band

        required property string label
        property int value
        property int minimum: -10
        property int maximum: 10

        signal moved(v: int)

        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        StyledText {
            Layout.preferredWidth: 72
            text: band.label
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
        }

        StyledSlider {
            Layout.fillWidth: true
            implicitHeight: Tokens.padding.medium * 2
            from: band.minimum
            to: band.maximum
            stepSize: 1
            value: band.value
            onInteraction: v => band.moved(Math.round(v))
        }

        StyledText {
            Layout.preferredWidth: 28
            horizontalAlignment: Text.AlignRight
            text: !Sony.tenBand && band.value > 0 ? `+${band.value}` : `${band.value}`
            font: Tokens.font.body.small
        }
    }
}
