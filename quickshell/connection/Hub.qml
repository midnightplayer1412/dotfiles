import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: root

    required property var screen

    anchors { top: true; right: true }
    margins {
        top:   Theme.hubMargin
        right: Theme.hubMargin
    }
    implicitWidth: Theme.hubWidth
    implicitHeight: Theme.hubHeight

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Component.onCompleted: ConnectionState.registerHub(root.screen, root)
    Component.onDestruction: {
        ConnectionState.unregisterHub(root.screen);
        ConnectionState.hubExited();   // clear hubHovered so leaveTimer can fire on the next hover
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: 14
        color: Theme.surface
        border.color: Theme.outline
        border.width: 1

        opacity: 0
        Component.onCompleted: fadeIn.start()
        NumberAnimation {
            id: fadeIn
            target: surface; property: "opacity"
            from: 0; to: 1
            duration: 120; easing.type: Easing.OutCubic
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 0

            // Tabs are driven by HubConfig (order + visibility), edited in the
            // Settings "Connection Hub" pane. Reactive: re-renders on config change.
            Repeater {
                model: HubConfig.enabledOrdered()
                delegate: HubTab {
                    required property var modelData
                    tabKey: modelData.key
                    parentScreen: root.screen
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton    // don't intercept HubTab clicks
            propagateComposedEvents: true
            onEntered: ConnectionState.hubEntered()
            onExited:  ConnectionState.hubExited()
        }
    }
}
