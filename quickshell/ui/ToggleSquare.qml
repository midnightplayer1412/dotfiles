import QtQuick
import ".."

// Square toggle — boxy variant: rounded-rectangle track with a rounded-square
// sliding knob. Same controlled API as ToggleCapsule.
Rectangle {
    id: root

    property bool checked: false
    signal toggled(bool value)

    implicitWidth: 44
    implicitHeight: 24
    radius: 6
    // On: filled primary, white knob. Off: transparent with a primary outline
    // and a primary knob.
    color: checked ? Theme.primary : "transparent"
    border.color: Theme.primary
    border.width: 2
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        width: parent.height - 8
        height: parent.height - 8
        radius: 4
        color: root.checked ? Theme.surface : Theme.primary
        Behavior on color { ColorAnimation { duration: 150 } }
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 4 : 4
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
