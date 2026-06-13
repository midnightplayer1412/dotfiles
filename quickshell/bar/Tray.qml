import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import ".."

// StatusNotifierItem tray. Left-click activates the item; right-click opens its
// native context menu. Flows with the bar orientation.
GridLayout {
    id: tray
    property bool horizontal: false
    rows: horizontal ? 1 : -1
    columns: horizontal ? -1 : 1
    rowSpacing: 10
    columnSpacing: 10

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: item
            required property var modelData
            implicitWidth: Theme.barIconSize
            implicitHeight: Theme.barIconSize
            Layout.alignment: Qt.AlignCenter

            Image {
                anchors.fill: parent
                source: item.modelData.icon
                sourceSize.width: Theme.barIconSize
                sourceSize.height: Theme.barIconSize
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton)
                        item.modelData.activate();
                    else
                        item.modelData.display(item, mouse.x, mouse.y);
                }
            }
        }
    }
}
