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

            // Empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: NotificationService.notifications.values.length === 0

                Text {
                    anchors.centerIn: parent
                    text: "No notifications"
                    color: Theme.outline
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                }
            }

            // List
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                visible: NotificationService.notifications.values.length > 0

                model: NotificationService.notifications
                verticalLayoutDirection: ListView.BottomToTop

                delegate: Rectangle {
                    id: card
                    required property var modelData

                    width: ListView.view ? ListView.view.width : 0
                    height: itemContent.implicitHeight + 20
                    radius: 10
                    color: Theme.surfaceContainer

                    ColumnLayout {
                        id: itemContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 10
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: card.modelData?.appName || "Notification"
                                color: Theme.primary
                                font.family: Theme.fontFamily
                                font.bold: true
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "✕"
                                color: dismissMouse.containsMouse ? Theme.primary : Theme.outline
                                font.pixelSize: 12

                                MouseArea {
                                    id: dismissMouse
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NotificationService.dismiss(card.modelData)
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: card.modelData?.summary || ""
                            color: Theme.surfaceText
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.bold: true
                            wrapMode: Text.WordWrap
                            visible: text.length > 0
                        }

                        Text {
                            Layout.fillWidth: true
                            text: card.modelData?.body || ""
                            color: Theme.surfaceText
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            visible: text.length > 0
                        }
                    }
                }
            }
        }
    }
}
