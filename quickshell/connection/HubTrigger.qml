import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: root

    required property var screen

    anchors { top: true; right: true }
    implicitWidth: Theme.hubTriggerWidth
    implicitHeight: Theme.hubTriggerHeight

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: ConnectionState.triggerEntered(root.screen)
        onExited:  ConnectionState.triggerExited()
    }
}
