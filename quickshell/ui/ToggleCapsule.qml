import QtQuick
import ".."

// Capsule toggle — the WiFi/Bluetooth panel style: pill track, circular sliding
// knob, fills with primary when on. Controlled: owner sets `checked`, click
// emits toggled(!checked).
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
        width: parent.height - 6
        height: parent.height - 6
        radius: width / 2
        color: root.checked ? Theme.surface : Theme.primary
        Behavior on color { ColorAnimation { duration: 150 } }
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 3 : 3
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
