import QtQuick
import ".."

// CSS/QML-drawn keyboard. A rounded chassis "deck" holding rows of beveled
// keycaps. Static physical layout; each KeyCap decides its own highlight/hover
// from the active app's binds. Media/brightness keys carry their XF86 keysyms
// so laptop Fn bindings light up too.
Rectangle {
    id: kb

    readonly property real unit: 58      // px per flex unit
    readonly property real spacing_: 6
    readonly property real deckPad: 16

    implicitWidth:  rows_.implicitWidth + deckPad * 2
    implicitHeight: rows_.implicitHeight + deckPad * 2

    radius: 16
    color: Qt.darker(Theme.surface, 1.35)
    border.width: 1
    border.color: Theme.outline

    // Rows of keys. sym must match the keymap `key` field (case-insensitive).
    readonly property var rows: [
        [
            { sym: "escape", label: "Esc", flex: 1.4 },
            { sym: "XF86MonBrightnessDown", label: "Bri-", flex: 1 },
            { sym: "XF86MonBrightnessUp",   label: "Bri+", flex: 1 },
            { sym: "XF86AudioMute",         label: "Mute", flex: 1 },
            { sym: "XF86AudioLowerVolume",  label: "Vol-", flex: 1 },
            { sym: "XF86AudioRaiseVolume",  label: "Vol+", flex: 1 },
            { sym: "XF86AudioMicMute",      label: "Mic",  flex: 1 },
            { sym: "XF86AudioPrev",         label: "Prev", flex: 1 },
            { sym: "XF86AudioPlay",         label: "Play", flex: 1 },
            { sym: "XF86AudioNext",         label: "Next", flex: 1 },
            { sym: "PRINT",                 label: "PrtSc", flex: 1.2 }
        ],
        [
            { sym: "grave", label: "`", flex: 1 },
            { sym: "1", label: "1", flex: 1 }, { sym: "2", label: "2", flex: 1 },
            { sym: "3", label: "3", flex: 1 }, { sym: "4", label: "4", flex: 1 },
            { sym: "5", label: "5", flex: 1 }, { sym: "6", label: "6", flex: 1 },
            { sym: "7", label: "7", flex: 1 }, { sym: "8", label: "8", flex: 1 },
            { sym: "9", label: "9", flex: 1 }, { sym: "0", label: "0", flex: 1 },
            { sym: "minus", label: "-", flex: 1 }, { sym: "equal", label: "=", flex: 1 },
            { sym: "BackSpace", label: "Bksp", flex: 1.8 }
        ],
        [
            { sym: "TAB", label: "Tab", flex: 1.5 },
            { sym: "Q", label: "Q", flex: 1 }, { sym: "W", label: "W", flex: 1 },
            { sym: "E", label: "E", flex: 1 }, { sym: "R", label: "R", flex: 1 },
            { sym: "T", label: "T", flex: 1 }, { sym: "Y", label: "Y", flex: 1 },
            { sym: "U", label: "U", flex: 1 }, { sym: "I", label: "I", flex: 1 },
            { sym: "O", label: "O", flex: 1 }, { sym: "P", label: "P", flex: 1 },
            { sym: "bracketleft", label: "[", flex: 1 }, { sym: "bracketright", label: "]", flex: 1 },
            { sym: "backslash", label: "\\", flex: 1.5 }
        ],
        [
            { sym: "SUPER", label: "Super", flex: 1.8, mod: true },
            { sym: "A", label: "A", flex: 1 }, { sym: "S", label: "S", flex: 1 },
            { sym: "D", label: "D", flex: 1 }, { sym: "F", label: "F", flex: 1 },
            { sym: "G", label: "G", flex: 1 }, { sym: "H", label: "H", flex: 1 },
            { sym: "J", label: "J", flex: 1 }, { sym: "K", label: "K", flex: 1 },
            { sym: "L", label: "L", flex: 1 }, { sym: "semicolon", label: ";", flex: 1 },
            { sym: "apostrophe", label: "'", flex: 1 },
            { sym: "RETURN", label: "Enter", flex: 1.8 }
        ],
        [
            { sym: "SHIFT", label: "Shift", flex: 2.3, mod: true },
            { sym: "Z", label: "Z", flex: 1 }, { sym: "X", label: "X", flex: 1 },
            { sym: "C", label: "C", flex: 1 }, { sym: "V", label: "V", flex: 1 },
            { sym: "B", label: "B", flex: 1 }, { sym: "N", label: "N", flex: 1 },
            { sym: "M", label: "M", flex: 1 }, { sym: "comma", label: ",", flex: 1 },
            { sym: "period", label: ".", flex: 1 }, { sym: "slash", label: "/", flex: 1 },
            { sym: "SHIFT", label: "Shift", flex: 2.3, mod: true }
        ],
        [
            { sym: "CTRL", label: "Ctrl", flex: 1.5, mod: true },
            { sym: "SUPER", label: "Super", flex: 1.4, mod: true },
            { sym: "ALT", label: "Alt", flex: 1.3, mod: true },
            { sym: "space", label: "Space", flex: 6.5 },
            { sym: "ALT", label: "Alt", flex: 1.3, mod: true },
            { sym: "CTRL", label: "Ctrl", flex: 1.5, mod: true }
        ]
    ]

    Column {
        id: rows_
        anchors.centerIn: parent
        spacing: kb.spacing_

        Repeater {
            model: kb.rows

            Row {
                required property var modelData
                spacing: kb.spacing_
                anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

                Repeater {
                    model: parent.modelData

                    KeyCap {
                        required property var modelData
                        sym: modelData.sym
                        label: modelData.label
                        flex: modelData.flex
                        isMod: modelData.mod === true
                        width: flex * kb.unit
                    }
                }
            }
        }
    }
}
