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
    visible: NotificationService.activePopupCount > 0

    Column {
        id: column
        width: parent.width
        spacing: 10

        Repeater {
            model: NotificationService.notifications

            delegate: Item {
                id: delegateRoot

                required property var modelData
                readonly property bool popupActive: {
                    NotificationService.dismissedRev;
                    return modelData != null
                        && !NotificationService.dismissedPopups.has(modelData);
                }

                width: 400
                height: popupActive ? card.height : 0
                visible: popupActive

                Connections {
                    target: delegateRoot.modelData
                    function onClosed(reason) {
                        // Drop set entry so it doesn't outlive the QObject.
                        NotificationService.dismissedPopups.delete(delegateRoot.modelData);
                    }
                }

                Rectangle {
                    id: card

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
                                    text: delegateRoot.modelData?.appName || "Notification"
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
                                    onClicked: NotificationService.markPopupDismissed(delegateRoot.modelData)
                                }
                            }
                        }

                        Text {
                            text: delegateRoot.modelData?.summary || ""
                            color: Theme.surfaceText
                            font.pixelSize: 14
                            font.bold: true
                            wrapMode: Text.WordWrap
                            width: parent.width
                            visible: text.length > 0
                        }

                        Text {
                            text: delegateRoot.modelData?.body || ""
                            color: Theme.surfaceText
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            width: parent.width
                            visible: text.length > 0
                        }
                    }
                }

                Timer {
                    interval: 5000
                    running: delegateRoot.popupActive
                    onTriggered: NotificationService.markPopupDismissed(delegateRoot.modelData)
                }
            }
        }
    }
}
