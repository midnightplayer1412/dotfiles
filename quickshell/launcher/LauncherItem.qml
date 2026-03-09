import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: root

    required property var entry
    required property bool selected
    property bool hovered: false

    signal clicked()

    height: Theme.launcherItemHeight
    radius: 8
    color: selected ? Theme.primaryContainer
         : hovered  ? Theme.surfaceContainer
         :             "transparent"

    Behavior on color { ColorAnimation { duration: 100 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.launcherMargin
        anchors.rightMargin: Theme.launcherMargin
        spacing: 12

        Image {
            id: iconImage
            property string iconName: root.entry.icon ?? ""
            property string resolvedPath: iconName.startsWith("/") ? iconName : Quickshell.iconPath(iconName, 28)
            source: resolvedPath

            sourceSize.width: 28
            sourceSize.height: 28
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            asynchronous: true

            // Fallback: if Quickshell.iconPath() returns empty, find icon via shell
            onResolvedPathChanged: {
                if (resolvedPath === "" && iconName !== "") {
                    iconFinder.running = true;
                }
            }

            Component.onCompleted: {
                if (resolvedPath === "" && iconName !== "") {
                    iconFinder.running = true;
                }
            }

            Process {
                id: iconFinder
                command: ["find", "/usr/share/icons/Papirus/32x32", "/usr/share/icons/Papirus/48x48", "/usr/share/icons/Papirus/24x24", "/usr/share/icons/hicolor/scalable", "/usr/share/icons/hicolor/48x48", "-name", iconImage.iconName + ".*", "-print", "-quit"]
                running: false
                stdout: SplitParser {
                    onRead: data => {
                        const path = data.trim();
                        if (path) {
                            iconImage.source = path;
                        }
                    }
                }
            }
        }

        Text {
            text: root.entry.name
            color: Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.bold: root.selected
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            text: root.entry.comment ?? ""
            color: Theme.outline
            font.family: Theme.fontFamily
            font.pixelSize: 12
            elide: Text.ElideRight
            Layout.maximumWidth: 200
            visible: text !== ""
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: root.clicked()
    }
}
