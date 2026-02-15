import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Rectangle {
    id: root

    required property var entry
    required property bool selected
    property bool hovered: false

    signal clicked()

    height: Theme.launcherItemHeight
    radius: 8
    color: selected ? Theme.primaryContainer
         : hovered  ? Theme.surfaceContainer
         :             "transparent"

    Behavior on color { ColorAnimation { duration: 100 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.launcherMargin
        anchors.rightMargin: Theme.launcherMargin
        spacing: 12

        Image {
            source: Quickshell.iconPath(root.entry.icon, 28)
            sourceSize.width: 28
            sourceSize.height: 28
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
        }

        Text {
            text: root.entry.name
            color: Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.bold: root.selected
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            text: root.entry.comment ?? ""
            color: Theme.outline
            font.family: Theme.fontFamily
            font.pixelSize: 12
            elide: Text.ElideRight
            Layout.maximumWidth: 200
            visible: text !== ""
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: root.clicked()
    }
}
