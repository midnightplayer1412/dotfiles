import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: root

    required property var screen

    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    height: 4

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    color: "transparent"

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            if (!LauncherState.visible) {
                LauncherState.toggle(root.screen);
            }
        }
    }
}
