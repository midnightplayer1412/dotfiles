import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."

PanelWindow {
    id: root

    required property var screen

    anchors.bottom: true
    width: Theme.launcherWidth
    height: Theme.launcherHeight
    margins.bottom: Theme.launcherMargin

    // Center horizontally
    margins.left: (screen.width - Theme.launcherWidth) / 2
    margins.right: (screen.width - Theme.launcherWidth) / 2

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    color: "transparent"

    HyprlandFocusGrab {
        id: focusGrab
        active: true
        windows: [root]
        onCleared: LauncherState.close()
    }

    Rectangle {
        id: content

        width: parent.width
        height: parent.height
        opacity: 0
        y: 30

        Component.onCompleted: entryAnim.start()

        ParallelAnimation {
            id: entryAnim
            NumberAnimation { target: content; property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { target: content; property: "y"; from: 30; to: 0; duration: 200; easing.type: Easing.OutCubic }
        }
        radius: Theme.launcherRadius
        color: Theme.surface
        border.color: Theme.outline
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.launcherMargin
            spacing: 8

            // Search bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.launcherSearchHeight
                radius: Theme.launcherSearchHeight / 2
                color: Theme.surfaceContainer

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 8

                    Image {
                        source: Quickshell.iconPath("search", 16)
                        sourceSize.width: 16
                        sourceSize.height: 16
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                    }

                    TextInput {
                        id: searchInput

                        Layout.fillWidth: true
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: Theme.primary
                        clip: true
                        focus: true

                        Text {
                            anchors.fill: parent
                            text: "Search applications..."
                            color: Theme.outline
                            font: searchInput.font
                            visible: !searchInput.text
                            verticalAlignment: Text.AlignVCenter
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                                resultsList.incrementCurrentIndex();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                resultsList.decrementCurrentIndex();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (resultsList.currentIndex >= 0 && resultsList.currentIndex < filteredModel.values.length) {
                                    filteredModel.values[resultsList.currentIndex].execute();
                                    LauncherState.close();
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                LauncherState.close();
                                event.accepted = true;
                            }
                        }
                    }
                }
            }

            // Results list
            ListView {
                id: resultsList

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                currentIndex: 0
                highlightMoveDuration: 100

                model: ScriptModel {
                    id: filteredModel

                    values: {
                        const apps = DesktopEntries.applications.values;
                        const query = searchInput.text.toLowerCase().trim();

                        if (!query) {
                            return [...apps].sort((a, b) => a.name.localeCompare(b.name));
                        }

                        const matches = apps.filter(app => {
                            const name = app.name.toLowerCase();
                            const comment = (app.comment ?? "").toLowerCase();
                            return name.includes(query) || comment.includes(query);
                        });

                        // Prefix matches first, then sort alphabetically within groups
                        const prefix = [];
                        const rest = [];
                        for (const app of matches) {
                            if (app.name.toLowerCase().startsWith(query)) {
                                prefix.push(app);
                            } else {
                                rest.push(app);
                            }
                        }
                        prefix.sort((a, b) => a.name.localeCompare(b.name));
                        rest.sort((a, b) => a.name.localeCompare(b.name));
                        return prefix.concat(rest);
                    }
                }

                delegate: LauncherItem {
                    required property var modelData
                    required property int index

                    width: resultsList.width
                    entry: modelData
                    selected: index === resultsList.currentIndex

                    onClicked: {
                        modelData.execute();
                        LauncherState.close();
                    }

                    onHoveredChanged: {
                        if (hovered) resultsList.currentIndex = index;
                    }
                }
            }
        }
    }
}
