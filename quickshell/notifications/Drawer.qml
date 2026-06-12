import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."

PanelWindow {
    id: root

    required property var screen

    anchors {
        top: true
        right: true
        bottom: true
    }

    implicitWidth: 400

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    HyprlandFocusGrab {
        active: true
        windows: [root]
        onCleared: NotificationCenterState.close()
    }

    Rectangle {
        id: panel

        width: parent.width - 10
        height: parent.height - 20
        anchors.verticalCenter: parent.verticalCenter

        color: Theme.surface
        radius: 16
        border.color: Theme.outline
        border.width: 1
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
                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 14
                    color: NotificationService.doNotDisturb
                        ? Theme.primary
                        : (dndMouse.containsMouse ? Theme.surfaceContainer : "transparent")

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        // bell-off when silenced, bell when active
                        text: NotificationService.doNotDisturb ? "\u{F009C}" : "\u{F009A}"
                        color: NotificationService.doNotDisturb ? Theme.primaryText : Theme.surfaceText
                        font.family: Theme.glyphFont
                        font.pixelSize: 15
                    }

                    MouseArea {
                        id: dndMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationService.toggleDoNotDisturb()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: clearLabel.implicitWidth + 20
                    Layout.preferredHeight: 28
                    radius: 14
                    color: clearMouse.containsMouse ? Theme.primary : Theme.surfaceContainer

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Clear all"
                        color: clearMouse.containsMouse ? Theme.primaryText : Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationService.clearAll()
                    }
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
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: groupCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                visible: NotificationService.notifications.values.length > 0

                Column {
                    id: groupCol
                    width: parent.width
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
