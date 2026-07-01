import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."
import "../ui" as Ui
import "../audio"

// Right-side container. Hosts EITHER the unified connection layout
// (wifi/bluetooth/vpn) or the audio panel, chosen by ConnectionState.openPanel.
// Click-outside (focus grab) closes it.
PanelWindow {
    id: root

    required property var screen

    anchors { top: true; right: true; bottom: true }

    // Clear the bar on whichever edge it occupies so the container never overlays it.
    margins {
        top:    BarConfig.clearance("top",    Theme.hubMargin)
        right:  BarConfig.clearance("right",  Theme.hubMargin)
        bottom: BarConfig.clearance("bottom", Theme.hubMargin)
    }
    implicitWidth: Theme.drawerWidth

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: Ui.Surfaces.blurNamespace

    HyprlandFocusGrab {
        active: true
        windows: [root]
        onCleared: ConnectionState.close()
    }

    Ui.Surface {
        id: surface
        anchors.fill: parent
        level: 0
        radius: Theme.drawerRadius
        clip: true

        x: 40
        opacity: 0
        Component.onCompleted: entryAnim.start()
        ParallelAnimation {
            id: entryAnim
            NumberAnimation { target: surface; property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { target: surface; property: "x";       from: 40; to: 0; duration: 200; easing.type: Easing.OutCubic }
        }

        Loader {
            anchors.fill: parent
            anchors.margins: 16
            sourceComponent: ConnectionState.openPanel === "audio" ? audioPanel
                           : ConnectionState.openPanel === "connection" ? connLayout
                           : null
        }

        Component { id: connLayout; ConnLayout {} }
        Component { id: audioPanel; AudioPanel {} }
    }
}
