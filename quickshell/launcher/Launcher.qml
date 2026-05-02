import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."

PanelWindow {
    id: root

    required property var screen

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    color: "transparent"

    HyprlandFocusGrab {
        id: focusGrab
        active: true
        windows: [root]
        onCleared: LauncherState.close()
    }

    // Click-outside-to-close: covers the whole screen, sits behind the panel
    MouseArea {
        anchors.fill: parent
        onClicked: LauncherState.close()
    }

    Rectangle {
        id: content

        width: Theme.launcherWidth
        height: Theme.launcherHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.launcherMargin
        opacity: 0

        Component.onCompleted: entryAnim.start()

        transform: Translate { id: slideTransform; y: 30 }

        ParallelAnimation {
            id: entryAnim
            NumberAnimation { target: content; property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { target: slideTransform; property: "y"; from: 30; to: 0; duration: 200; easing.type: Easing.OutCubic }
        }
        radius: Theme.launcherRadius
        color: Theme.surface
        border.color: Theme.outline
        border.width: 1
        clip: true

        // Absorb clicks on the panel's empty padding so they don't bubble to the outer click-catcher
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

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
                            text: searchInput.text.startsWith("/") ? "  Type a command..."
                                : searchInput.text.startsWith("!") ? "  Type a shell command..."
                                : "Search applications..."
                            color: Theme.outline
                            font: searchInput.font
                            visible: !searchInput.text || searchInput.text === "/" || searchInput.text === "!"
                            verticalAlignment: Text.AlignVCenter
                        }

                        Keys.priority: Keys.BeforeItem
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Down
                                    || (event.key === Qt.Key_J && (event.modifiers & Qt.ControlModifier))) {
                                resultsList.incrementCurrentIndex();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Tab) {
                                if (searchInput.text.startsWith("/") && !searchInput.text.includes(" ")
                                        && resultsList.currentIndex >= 0
                                        && resultsList.currentIndex < filteredModel.values.length) {
                                    const item = filteredModel.values[resultsList.currentIndex];
                                    searchInput.text = item.name + (item.takesArgs ? " " : "");
                                    searchInput.cursorPosition = searchInput.text.length;
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up
                                    || (event.key === Qt.Key_K && (event.modifiers & Qt.ControlModifier))) {
                                resultsList.decrementCurrentIndex();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (searchInput.text.startsWith("/")) {
                                    Commands.execute(searchInput.text);
                                    LauncherState.close();
                                } else if (searchInput.text.startsWith("!")) {
                                    Commands.runShell(searchInput.text);
                                    LauncherState.close();
                                } else if (resultsList.currentIndex >= 0 && resultsList.currentIndex < filteredModel.values.length) {
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
                        const text = searchInput.text;

                        // Command mode
                        if (text.startsWith("/")) {
                            return Commands.filter(text);
                        }

                        // Shell mode
                        if (text.startsWith("!")) {
                            return Commands.filterShell(text);
                        }

                        // App mode
                        const blacklist = new Set([
                            "avahi-discover",
                            "bvnc",
                            "bssh",
                            "xfce4-about",
                            "kcm_fcitx5",
                            "cmake-gui",
                            "uuctl",
                            "imv",
                        ]);

                        const seen = new Set();
                        const apps = DesktopEntries.applications.values.filter(app => {
                            if (blacklist.has(app.id)) return false;
                            if (seen.has(app.id)) return false;
                            seen.add(app.id);
                            return true;
                        });
                        const query = text.toLowerCase().trim();

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
                        if (searchInput.text.startsWith("/")) {
                            Commands.execute(searchInput.text);
                        } else if (searchInput.text.startsWith("!")) {
                            Commands.runShell(searchInput.text);
                        } else {
                            modelData.execute();
                        }
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
