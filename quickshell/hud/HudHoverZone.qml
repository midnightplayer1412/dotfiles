import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: root

    required property var screen

    anchors.right: true
    anchors.top: false
    anchors.bottom: false
    implicitWidth: Theme.hudTriggerWidth
    implicitHeight: Theme.hudTriggerHeight

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    color: "transparent"

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            HudState.show(root.screen);
        }
    }
}
