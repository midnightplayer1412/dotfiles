import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "categories" as Categories
import ".."

// Fullscreen settings panel: left category nav + right content area.
// Mirrors Overview's window/focus/ESC pattern.
PanelWindow {
    id: root
    required property var screen

    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"

    // Categories: extend this list to add panes later.
    readonly property var categories: [
        { key: "appearance", label: "Appearance", glyph: "\u{F0479}" }, // nf-md-palette
        { key: "lock", label: "Lock Screen", glyph: "\u{F033E}" }       // nf-md-lock
    ]

    HyprlandFocusGrab {
        active: true
        windows: [root]
        onCleared: SettingsState.close()
    }

    // Dim backdrop; click outside the card closes.
    Rectangle {
        anchors.fill: parent
        color: "#99000000"
        MouseArea { anchors.fill: parent; onClicked: SettingsState.close() }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(1100, parent.width - 120)
        height: Math.min(720, parent.height - 120)
        radius: 18
        color: Theme.surface
        border.color: Theme.outline
        border.width: 1

        // Swallow clicks so they don't fall through to the backdrop.
        MouseArea { anchors.fill: parent }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 18

            // ── Nav sidebar ──
            ColumnLayout {
                // A ColumnLayout nested in a RowLayout defaults Layout.fillWidth to
                // true, which would let the sidebar expand and crush the content
                // area — pin it to a fixed width.
                Layout.fillWidth: false
                Layout.preferredWidth: 180
                Layout.minimumWidth: 180
                Layout.maximumWidth: 180
                Layout.fillHeight: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 12
                    spacing: 8
                    Text {
                        text: "\u{F08BB}"   // nf-md-cog
                        color: Theme.primary
                        font.family: Theme.glyphFont
                        font.pixelSize: 22
                    }
                    Text {
                        text: "Settings"
                        color: Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        font.bold: true
                    }
                }

                Repeater {
                    model: root.categories
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 9
                        color: SettingsState.activeCategory === modelData.key
                            ? Theme.surfaceContainer
                            : (navMouse.containsMouse ? Theme.surfaceContainer : "transparent")
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            spacing: 10
                            Text {
                                text: modelData.glyph
                                color: SettingsState.activeCategory === modelData.key ? Theme.primary : Theme.surfaceText
                                font.family: Theme.glyphFont
                                font.pixelSize: 16
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: SettingsState.activeCategory === modelData.key ? Theme.primary : Theme.surfaceText
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                            }
                        }
                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SettingsState.activeCategory = modelData.key
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // Divider
            Rectangle { Layout.fillHeight: true; Layout.preferredWidth: 1; color: Theme.outline }

            // ── Content area ──
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Categories.LockScreenPane {
                    anchors.fill: parent
                    visible: SettingsState.activeCategory === "lock"
                }

                Categories.ThemePane {
                    anchors.fill: parent
                    visible: SettingsState.activeCategory === "appearance"
                }
            }
        }
    }

    // ESC to close.
    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: SettingsState.close()
    }
}
