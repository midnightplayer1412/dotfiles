import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."

PanelWindow {
    id: root

    required property var screen

    anchors { left: true; right: true; top: true; bottom: true }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    color: "transparent"

    HyprlandFocusGrab {
        active: true
        windows: [root]
        onCleared: OverviewState.close()
    }

    // Click-outside-to-close
    MouseArea {
        anchors.fill: parent
        onClicked: OverviewState.close()
    }

    OverviewWidget {
        id: widget
        anchors.centerIn: parent
        opacity: 0
        transform: Scale {
            id: entryScale
            origin.x: widget.width / 2
            origin.y: widget.height / 2
            xScale: 0.95
            yScale: 0.95
        }

        Component.onCompleted: entryAnim.start()
        ParallelAnimation {
            id: entryAnim
            NumberAnimation { target: widget;      property: "opacity"; from: 0;    to: 1; duration: 160; easing.type: Easing.OutCubic }
            NumberAnimation { target: entryScale;  property: "xScale";  from: 0.95; to: 1; duration: 160; easing.type: Easing.OutCubic }
            NumberAnimation { target: entryScale;  property: "yScale";  from: 0.95; to: 1; duration: 160; easing.type: Easing.OutCubic }
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: OverviewState.close()
    }
}
