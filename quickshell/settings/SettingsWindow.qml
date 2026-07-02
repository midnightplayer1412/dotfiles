import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "categories" as Categories
import "../ui" as Ui
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
    WlrLayershell.namespace: Ui.Surfaces.blurNamespace
    color: "transparent"

    // Categories: extend this list to add panes later. Icons are Papirus
    // *symbolic* (monochrome) SVGs, tinted to the accent by Ui.Icon — uniform
    // sizes by construction, unlike font glyphs.
    readonly property string sym: "/usr/share/icons/Papirus/16x16/symbolic"
    readonly property var categories: [
        { key: "appearance", label: "Appearance",     icon: sym + "/categories/applications-graphics-symbolic.svg" },
        { key: "bar",        label: "Bar",            icon: sym + "/actions/sidebar-show-symbolic.svg" },
        { key: "overview",   label: "Window Switcher", icon: sym + "/actions/view-app-grid-symbolic.svg" },
        { key: "lock",       label: "Lock Screen",    icon: sym + "/actions/system-lock-screen-symbolic.svg" },
        { key: "launcher",   label: "Launcher",       icon: sym + "/categories/applications-all-symbolic.svg" }
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

    Ui.Surface {
        id: card
        level: 0
        anchors.centerIn: parent
        width: Math.min(1100, parent.width - 120)
        height: Math.min(720, parent.height - 120)
        radius: 18

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
                    Ui.Icon {
                        source: root.sym + "/categories/preferences-system-symbolic.svg"
                        color: Theme.primary
                        size: 22
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
                    delegate: NavButton {
                        required property var modelData
                        entry: modelData
                    }
                }

                Item { Layout.fillHeight: true }

                // "About" is pinned to the bottom, set apart from the functional
                // tabs by a divider — system/hardware info, not a setting.
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    Layout.bottomMargin: 6
                    color: Theme.outline
                }
                NavButton {
                    entry: ({ key: "about", label: "About", icon: root.sym + "/actions/help-about-symbolic.svg" })
                }
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

                Categories.BarPane {
                    anchors.fill: parent
                    visible: SettingsState.activeCategory === "bar"
                }

                Categories.OverviewPane {
                    anchors.fill: parent
                    visible: SettingsState.activeCategory === "overview"
                }

                Categories.LauncherPane {
                    anchors.fill: parent
                    visible: SettingsState.activeCategory === "launcher"
                }

                Categories.SystemInfoPane {
                    anchors.fill: parent
                    visible: SettingsState.activeCategory === "about"
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

    // Sidebar entry, shared by the category Repeater and the pinned "About" item.
    component NavButton: Ui.SelectableRow {
        property var entry: ({ key: "", label: "", glyph: "" })
        readonly property bool active: SettingsState.activeCategory === entry.key
        Layout.fillWidth: true
        Layout.preferredHeight: 38
        selected: active
        onClicked: SettingsState.activeCategory = entry.key
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            spacing: 10
            Ui.Icon {
                source: entry.icon
                color: active ? Theme.primary : Theme.surfaceText
                size: 18
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                Layout.fillWidth: true
                text: entry.label
                color: active ? Theme.primary : Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 13
            }
        }
    }
}
