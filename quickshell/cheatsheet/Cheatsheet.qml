import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."
import "../ui" as Ui

// Full-screen overlay hosting the keybinding cheatsheet. Mirrors the Overview
// window: layer-shell overlay, exclusive keyboard focus, click-outside / Esc
// to close.
PanelWindow {
    id: root

    required property var screen

    anchors { left: true; right: true; top: true; bottom: true }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: Ui.Surfaces.blurNamespace

    color: "transparent"

    HyprlandFocusGrab {
        active: true
        windows: [root]
        onCleared: CheatsheetState.close()
    }

    // Dim backdrop; click outside the card closes.
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.45
        MouseArea {
            anchors.fill: parent
            onClicked: CheatsheetState.close()
        }
    }

    CheatsheetWidget {
        id: widget
        anchors.centerIn: parent
        opacity: 0
        transform: Scale {
            id: entryScale
            origin.x: widget.width / 2
            origin.y: widget.height / 2
            xScale: 0.96
            yScale: 0.96
        }

        Component.onCompleted: entryAnim.start()
        ParallelAnimation {
            id: entryAnim
            NumberAnimation { target: widget;     property: "opacity"; from: 0;    to: 1; duration: 160; easing.type: Easing.OutCubic }
            NumberAnimation { target: entryScale; property: "xScale";  from: 0.96; to: 1; duration: 160; easing.type: Easing.OutCubic }
            NumberAnimation { target: entryScale; property: "yScale";  from: 0.96; to: 1; duration: 160; easing.type: Easing.OutCubic }
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: CheatsheetState.close()
    }
}
