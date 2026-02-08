import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import ".."

Item {
    id: trayItemRoot
    width: Theme.barWidth - 8
    height: width

    required property SystemTrayItem item
    required property var barWindow

    Rectangle {
        id: bg
        anchors.fill: parent
        anchors.margins: 2
        radius: Theme.barRadius - 4
        color: mouseArea.containsMouse ? Theme.surfaceContainer : "transparent"

        Behavior on color { ColorAnimation { duration: 100 } }

        Image {
            anchors.centerIn: parent
            width: Theme.iconSize
            height: Theme.iconSize
            source: Quickshell.iconPath(trayItemRoot.item.icon)
            sourceSize.width: Theme.iconSize
            sourceSize.height: Theme.iconSize
        }
    }

    // Tooltip on hover
    Rectangle {
        id: tooltip
        visible: mouseArea.containsMouse && trayItemRoot.item.tooltipTitle !== ""
        x: trayItemRoot.width + 4
        y: (trayItemRoot.height - height) / 2
        width: tooltipText.implicitWidth + 12
        height: tooltipText.implicitHeight + 8
        radius: 4
        color: Theme.surfaceContainer

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: trayItemRoot.item.tooltipTitle
            color: Theme.onSurface
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: function(event) {
            if (event.button === Qt.LeftButton) {
                trayItemRoot.item.activate()
            } else if (event.button === Qt.MiddleButton) {
                trayItemRoot.item.secondaryActivate()
            }
        }
    }
}
