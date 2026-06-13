import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import ".."

GridLayout {
    id: root
    // Row when the bar is horizontal (top/bottom), column when vertical.
    property bool horizontal: false
    rows: horizontal ? 1 : -1
    columns: horizontal ? -1 : 1
    rowSpacing: 6
    columnSpacing: 6

    required property var barScreen

    Repeater {
        model: 10

        WorkspaceIndicator {
            required property int index

            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            workspaceId: index + 1
            monitor: Hyprland.monitorFor(root.barScreen)
        }
    }
}
