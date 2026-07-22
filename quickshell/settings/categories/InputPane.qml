import QtQuick
import QtQuick.Layouts
import "../../ui" as Ui
import "../.."

// Input devices settings. Currently just the touchpad master switch, which
// shares its state file with the Super+Shift+T bind — TouchpadConfig watches
// the file, so toggling from the keyboard moves this switch live.
Item {
    id: pane

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

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "\u{F0402}"   // nf-md-gesture-tap
                color: Theme.surfaceText
                font.family: Theme.glyphFont
                font.pixelSize: 18
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: "Enable touchpad"
                    color: Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
                Text {
                    text: "Off disables the built-in trackpad. External mice are unaffected."
                    color: Theme.surfaceText
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
            }
            Ui.Toggle {
                checked: TouchpadConfig.enabled
                onToggled: (v) => TouchpadConfig.setEnabled(v)
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 4
            text: "Shortcut: Super+Shift+T toggles the touchpad from anywhere. The setting persists across reboots and Hyprland reloads."
            color: Theme.surfaceText
            opacity: 0.7
            wrapMode: Text.WordWrap
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        Item { Layout.fillHeight: true }
    }
}
