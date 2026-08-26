import QtQuick
import QtQuick.Layouts
import "../../ui" as Ui
import "../.."

// Input devices settings. Both switches write the same state file that
// hypr/scripts/apply-touchpad.sh reads — TouchpadConfig watches it, so the
// Super+Shift+T bind (which writes `enabled` directly) moves the master switch
// here live.
Item {
    id: pane

    // ── Inline helpers ────────────────────────────────────────────────
    // Icon + label + description + switch. Same shape as LockScreenPane's
    // ToggleRow, with the glyph and the second line this pane needs.
    component ToggleRow: RowLayout {
        id: trow
        property string glyph: ""
        property string label: ""
        property string description: ""
        property bool checked: false
        signal toggled(bool v)

        Layout.fillWidth: true
        spacing: 10

        Text {
            text: trow.glyph
            color: Theme.surfaceText
            font.family: Theme.glyphFont
            font.pixelSize: 18
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: trow.label
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 13
            }
            Text {
                text: trow.description
                color: Theme.surfaceText
                opacity: 0.7
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
        }
        Ui.Toggle {
            checked: trow.checked
            onToggled: (v) => trow.toggled(v)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Text {
            text: "Touchpad"
            color: Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.bold: true
        }

        ToggleRow {
            glyph: "\u{F0402}"   // nf-md-gesture-tap
            label: "Enable touchpad"
            description: "Off disables the built-in trackpad. External mice are unaffected."
            checked: TouchpadConfig.enabled
            onToggled: (v) => TouchpadConfig.setEnabled(v)
        }

        ToggleRow {
            glyph: "\u{F034F}"   // nf-md-cursor-default-click
            label: "Tap to click"
            description: "Off means only a physical press of the pad clicks — a light tap does nothing. Two-finger press stays right click."
            checked: TouchpadConfig.tapToClick
            onToggled: (v) => TouchpadConfig.setTapToClick(v)
            // Dimmed while the touchpad is off: the setting still persists, it
            // just has nothing to act on until the master switch is back on.
            opacity: TouchpadConfig.enabled ? 1.0 : 0.5
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 4
            text: "Shortcut: Super+Shift+T toggles the touchpad from anywhere. Both settings persist across reboots and Hyprland reloads."
            color: Theme.surfaceText
            opacity: 0.7
            wrapMode: Text.WordWrap
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        Item { Layout.fillHeight: true }
    }
}
