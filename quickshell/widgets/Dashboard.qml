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

    // Content sized to the flow, centered. A swallow MouseArea sits UNDER the
    // flow so clicks on a tile (or in the spacing between tiles) don't fall
    // through to the backdrop and close the dashboard — clicks only close when
    // they land on the dark margin outside the content. Mirrors SettingsWindow's
    // card. Widget-internal MouseAreas (e.g. Media transport) sit above and still
    // receive their clicks.
    Item {
        id: content
        anchors.centerIn: parent
        width: flow.width
        height: flow.height

        MouseArea { anchors.fill: parent }

        Flow {
            id: flow
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
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: DashboardState.close()
    }
}
