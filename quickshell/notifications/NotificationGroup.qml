import QtQuick
import ".."

// One app's notifications. A single notification renders as a bare card; two or
// more get a collapsible header (app name + count + chevron) stacking the cards.
Column {
    id: root

    required property var group   // { key, app, items: [Notification…] }
    width: parent ? parent.width : 0
    spacing: 8

    readonly property bool single: group.items.length === 1
    readonly property bool collapsed: {
        NotificationCenterState.collapsedRev;
        return !single && NotificationCenterState.collapsedApps.has(group.key);
    }

    // Group header — multi-item only
    Rectangle {
        id: header
        visible: !root.single
        width: parent.width
        height: 28
        radius: 8
        color: headerMouse.containsMouse ? Theme.surfaceContainer : "transparent"

        Behavior on color { ColorAnimation { duration: 100 } }

        Text {
            id: chevron
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: root.collapsed ? "\u{F0142}" : "\u{F0140}"   // chevron-right / chevron-down
            color: Theme.surfaceText
            font.family: Theme.glyphFont
            font.pixelSize: 14
        }

        Text {
            anchors.left: chevron.right
            anchors.leftMargin: 6
            anchors.right: countBadge.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.group.app
            color: Theme.primary
            font.bold: true
            font.pixelSize: 12
            font.family: Theme.fontFamily
            elide: Text.ElideRight
        }

        Rectangle {
            id: countBadge
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(18, countLabel.implicitWidth + 10)
            height: 18
            radius: 9
            color: Theme.primary

            Text {
                id: countLabel
                anchors.centerIn: parent
                text: root.group.items.length
                color: Theme.primaryText
                font.bold: true
                font.pixelSize: 10
                font.family: Theme.fontFamily
            }
        }

        MouseArea {
            id: headerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: NotificationCenterState.toggleCollapsed(root.group.key)
        }
    }

    // Card stack — hidden when this group is collapsed
    Column {
        width: parent.width
        spacing: 8
        visible: root.single || !root.collapsed

        Repeater {
            model: root.group.items

            delegate: NotificationCard {
                required property var modelData
                width: parent ? parent.width : 0
                notif: modelData
                compact: true
                borderColor: Theme.outline
                onDismissRequested: NotificationService.dismiss(modelData)
            }
        }
    }
}
