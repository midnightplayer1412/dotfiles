import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."
import "../ui" as Ui

PanelWindow {
    id: root

    required property var screen

    anchors {
        top: true
        right: true
        bottom: true
    }

    // Clear the bar on whichever edge it sits on.
    margins {
        top:    BarConfig.clearance("top")
        right:  BarConfig.clearance("right")
        bottom: BarConfig.clearance("bottom")
    }

    implicitWidth: 400

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: Ui.Surfaces.blurNamespace

    HyprlandFocusGrab {
        active: true
        windows: [root]
        onCleared: NotificationCenterState.close()
    }

    Ui.Surface {
        id: panel
        level: 0
        radius: 16

        width: parent.width - 10
        height: parent.height - 20
        anchors.verticalCenter: parent.verticalCenter

        clip: true

        // slide-in from right
        x: 40
        opacity: 0
        Component.onCompleted: entryAnim.start()
        ParallelAnimation {
            id: entryAnim
            NumberAnimation { target: panel; property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { target: panel; property: "x"; from: 40; to: 0; duration: 200; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "Notifications"
                    color: Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.bold: true
                }

                // Do Not Disturb toggle
                Ui.IconButton {
                    bg: "filled"
                    active: NotificationService.doNotDisturb
                    // bell-off when silenced, bell when active
                    glyph: NotificationService.doNotDisturb ? "\u{F009C}" : "\u{F009A}"
                    glyphSize: 15
                    onClicked: NotificationService.toggleDoNotDisturb()
                }

                Ui.Button {
                    kind: "filled"
                    text: "Clear all"
                    onClicked: NotificationService.clearAll()
                }
            }

            // Media player (auto-hides when no MPRIS player)
            MediaPlayer {
                Layout.fillWidth: true
            }

            // Empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: NotificationService.notifications.values.length === 0

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "\u{F009D}"   // nf-md-bell-off-outline
                        color: Theme.outline
                        font.family: Theme.glyphFont
                        font.pixelSize: 40
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: NotificationService.doNotDisturb ? "Do Not Disturb" : "No notifications"
                        color: Theme.outline
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                    }
                }
            }

            // Grouped, scrollable history. Uses Flickable + Repeater (not ListView)
            // because the model is a reassigned JS array — see project notes on
            // ListView var-model rendering.
            Flickable {
                id: notifFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: groupCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                readonly property bool barVisible: contentHeight > height + 1
                ScrollBar.vertical: Ui.ScrollBar { visible: notifFlick.barVisible }
                visible: NotificationService.notifications.values.length > 0

                Column {
                    id: groupCol
                    width: notifFlick.width - (notifFlick.barVisible ? Theme.scrollGutter : 0)
                    spacing: 12

                    Repeater {
                        model: NotificationService.grouped

                        delegate: NotificationGroup {
                            required property var modelData
                            width: groupCol.width
                            group: modelData
                        }
                    }
                }
            }
        }
    }
}
