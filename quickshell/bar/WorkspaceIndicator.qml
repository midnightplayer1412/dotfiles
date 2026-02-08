import Quickshell.Hyprland
import QtQuick
import ".."

Rectangle {
    id: indicator

    required property int workspaceId
    required property var monitor

    readonly property var workspace: {
        let wsList = Hyprland.workspaces.values;
        for (let i = 0; i < wsList.length; i++) {
            if (wsList[i].id === workspaceId) return wsList[i];
        }
        return null;
    }

    readonly property bool isActive: monitor
        && monitor.activeWorkspace
        && monitor.activeWorkspace.id === workspaceId

    readonly property bool exists: workspace !== null

    width: Theme.workspaceDotSize
    height: isActive ? Theme.workspaceDotActiveSize : Theme.workspaceDotSize
    radius: width / 2

    color: {
        if (isActive) return Theme.primary
        if (exists) return Theme.outline
        return Theme.surfaceContainer
    }

    opacity: (isActive || exists) ? 1.0 : 0.4

    Behavior on height {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }
    Behavior on color {
        ColorAnimation { duration: 150 }
    }
    Behavior on opacity {
        NumberAnimation { duration: 150 }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Hyprland.dispatch("workspace " + workspaceId)
    }
}
