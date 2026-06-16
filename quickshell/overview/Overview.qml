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
    // Both modes grab the keyboard. Sticky uses it for Escape; armed uses it to
    // catch the Super-key RELEASE in QML (Hyprland can't dispatch a bind on a
    // modifier-key release — verified). Tab cycling still runs via the Hyprland
    // submap, which fires from compositor-level binds regardless of this grab.
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
        Keys.onEscapePressed: OverviewState.altTabCancel()

        // Armed alt-tab commits when Super is released. The Hyprland submap
        // consumes key PRESSES (driving Tab cycling), but RELEASES fall through
        // to this focused surface — so we catch the Super release here, which
        // Hyprland itself can't bind. Note Qt delivers the Super key as
        // Key_Meta (Super_L/R covered defensively for other keyboards).
        Keys.onReleased: (event) => {
            if (OverviewState.armed
                && (event.key === Qt.Key_Meta
                 || event.key === Qt.Key_Super_L
                 || event.key === Qt.Key_Super_R)) {
                OverviewState.altTabCommit();
                event.accepted = true;
            }
        }
    }
}
