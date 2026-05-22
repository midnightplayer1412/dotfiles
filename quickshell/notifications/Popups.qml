import QtQuick
import Quickshell
import Quickshell.Services.Notifications
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

                NotificationCard {
                    id: card
                    width: delegateRoot.width
                    notif: delegateRoot.modelData
                    compact: false
                    onDismissRequested: NotificationService.markPopupDismissed(delegateRoot.modelData)

                    opacity: 0
                    Component.onCompleted: opacity = 1
                    Behavior on opacity {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }
                }

                Timer {
                    interval: 5000
                    running: delegateRoot.popupActive
                        && delegateRoot.modelData
                        && delegateRoot.modelData.urgency !== NotificationUrgency.Critical
                    onTriggered: NotificationService.markPopupDismissed(delegateRoot.modelData)
                }
            }
        }
    }
}
