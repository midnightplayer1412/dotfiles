import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."
import "../wifi"

PanelWindow {
    id: root

    required property var screen

    anchors { top: true; right: true; bottom: true }
    margins {
        top:    Theme.hubMargin + Theme.hubHeight + Theme.hubDrawerGap
        right:  Theme.hubMargin
        bottom: Theme.hubMargin
    }
    implicitWidth: Theme.drawerWidth

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    readonly property var hubWindow:
        ConnectionState.hubWindows[root.screen?.name ?? ""] ?? null

    HyprlandFocusGrab {
        active: true
        windows: root.hubWindow ? [root, root.hubWindow] : [root]
        onCleared: ConnectionState.close()
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Theme.drawerRadius
        color: Theme.surface
        border.color: Theme.outline
        border.width: 1
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
            sourceComponent: {
                switch (ConnectionState.activeTab) {
                case "wifi":      return wifiPanel;
                // bluetoothPanel and vpnPanel components added in Tasks 18 and 21
                }
                return null;
            }
        }

        Component { id: wifiPanel; WifiPanel {} }
    }
}
