import QtQuick
import Quickshell
import ".."

PanelWindow {
    id: root

    required property var screen

    anchors {
        top: true
        right: true
    }

    margins.top: 50
    margins.right: 20

    implicitWidth: 420
    implicitHeight: Math.max(1, column.implicitHeight)

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: NotificationService.popups.length > 0

    Column {
        id: column
        width: parent.width
        spacing: 10

        Repeater {
            model: NotificationService.popups

            delegate: Rectangle {
                id: card

                required property var modelData

                width: 400
                height: content.implicitHeight + 24
                radius: 10
                color: Theme.surfaceContainer
                border.color: Theme.primary
                border.width: 1

                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }

                Column {
                    id: content
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4

                    Item {
                        width: parent.width
                        height: appRow.height

                        Row {
                            id: appRow
                            spacing: 8
                            anchors.left: parent.left

                            Text {
                                text: card.modelData.appName || "Notification"
                                color: Theme.primary
                                font.bold: true
                                font.pixelSize: 12
                                font.family: Theme.fontFamily
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "✕"
                            color: Theme.surfaceText
                            font.pixelSize: 14

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationService.dismissPopup(card.modelData)
                            }
                        }
                    }

                    Text {
                        text: card.modelData.summary
                        color: Theme.surfaceText
                        font.pixelSize: 14
                        font.bold: true
                        wrapMode: Text.WordWrap
                        width: parent.width
                        visible: text.length > 0
                    }

                    Text {
                        text: card.modelData.body
                        color: Theme.surfaceText
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        width: parent.width
                        visible: text.length > 0
                    }
                }

                Timer {
                    interval: 5000
                    running: true
                    onTriggered: NotificationService.dismissPopup(card.modelData)
                }
            }
        }
    }
}
