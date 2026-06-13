import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: batteryRoot
    property bool horizontal: false

    // Size to the inner layout (plus padding) so a Loader in either bar
    // orientation gives it the right footprint.
    implicitWidth: lay.implicitWidth + 8
    implicitHeight: lay.implicitHeight + 8

    property var battery: UPower.displayDevice
    property int percentage: (battery && battery.ready) ? Math.round((battery?.percentage ?? 0) * 100) : 0
    property bool isCharging: (battery && battery.ready) ? battery?.state === UPowerDeviceState.Charging || battery?.state === UPowerDeviceState.FullyCharged : false
    property color batteryColor: {
        if (batteryRoot.isCharging) return Theme.primary;
        if (batteryRoot.percentage > 50) return Theme.primary;
        if (batteryRoot.percentage > 20) return Qt.rgba(1.0, 0.7, 0.0, 1.0); // Orange
        return Qt.rgba(1.0, 0.3, 0.3, 1.0); // Red
    }

    GridLayout {
        id: lay
        anchors.centerIn: parent
        // Row when the bar is horizontal, column when vertical.
        rows: batteryRoot.horizontal ? 1 : -1
        columns: batteryRoot.horizontal ? -1 : 1
        rowSpacing: 2
        columnSpacing: 6

        // Battery icon (simple battery shape)
        Item {
            id: batteryIcon
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            width: 20
            height: 10

            // Battery body
            Rectangle {
                id: batteryBody
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 8
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: batteryRoot.batteryColor

                // Battery fill level
                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 1.5
                    width: Math.max(0, (parent.width - 3) * (batteryRoot.percentage / 100))
                    height: parent.height - 3
                    radius: 1
                    color: batteryRoot.batteryColor
                }
            }

            // Battery tip
            Rectangle {
                anchors.left: batteryBody.right
                anchors.verticalCenter: parent.verticalCenter
                width: 2
                height: 4
                color: batteryRoot.batteryColor
            }

            // Charging indicator (lightning bolt overlay)
            Text {
                visible: batteryRoot.isCharging
                anchors.centerIn: batteryBody
                text: "⚡"
                font.pixelSize: 8
                color: Theme.primary
            }
        }

        // Battery percentage text
        Text {
            id: batteryText
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            text: batteryRoot.percentage + "%"
            color: batteryRoot.batteryColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
        }
    }
}
