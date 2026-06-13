import QtQuick
import ".."

// Notch toggle — outline variant: the track is an outlined ring when off
// (transparent + outline border, small muted knob) and fills solid primary when
// on. Same controlled API as ToggleCapsule.
Rectangle {
    id: root

    property bool checked: false
    signal toggled(bool value)

    implicitWidth: 44
    implicitHeight: 24
    radius: height / 2
    // On: filled primary, white knob. Off: transparent with a primary outline
    // and a primary knob.
    color: checked ? Theme.primary : "transparent"
    border.color: Theme.primary
    border.width: 2
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        width: parent.height - 10
        height: parent.height - 10
        radius: width / 2
        color: root.checked ? Theme.surface : Theme.primary
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 5 : 5
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
