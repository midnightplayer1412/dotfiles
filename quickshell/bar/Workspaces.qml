import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    id: root
    spacing: 6

    required property var barScreen

    Repeater {
        model: 10

        WorkspaceIndicator {
            required property int index

            Layout.alignment: Qt.AlignHCenter
            workspaceId: index + 1
            monitor: Hyprland.monitorFor(root.barScreen)
        }
    }
}
