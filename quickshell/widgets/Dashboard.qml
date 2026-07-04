import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."
import "../ui" as Ui

// SUPER+W command-center. Dimmed backdrop; enabled dashboard widgets auto-flow
// in configured order. Click-outside / ESC / SUPER+W closes (mirrors Settings).
PanelWindow {
    id: root
    required property var screen

    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: Ui.Surfaces.blurNamespace
    color: "transparent"

    Component.onCompleted: console.log("BUILD widgets-dashboard")

    readonly property var items: {
        const rd = WidgetsConfig.resolvedDashboard;
        return rd.order.filter(id => rd.enabled[id]);
    }

    HyprlandFocusGrab {
        active: true
        windows: [root]
        onCleared: DashboardState.close()
    }

    Rectangle {
        anchors.fill: parent
        color: "#cc000000"
        MouseArea { anchors.fill: parent; onClicked: DashboardState.close() }
    }

    Flow {
        anchors.centerIn: parent
        width: Math.min(root.width - 160, 980)
        spacing: 20

        Repeater {
            model: root.items
            delegate: WidgetFrame {
                required property var modelData
                widgetId: modelData
                content: WidgetRegistry.componentFor(modelData)
                enabled: true
            }
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: DashboardState.close()
    }
}
