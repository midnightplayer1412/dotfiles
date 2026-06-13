import Quickshell.Services.UPower
import QtQuick
import ".."

Item {
    id: batteryRoot
    property bool horizontal: false

    property var battery: UPower.displayDevice
    property int percentage: (battery && battery.ready) ? Math.round((battery?.percentage ?? 0) * 100) : 0
    property bool isCharging: (battery && battery.ready) ? battery?.state === UPowerDeviceState.Charging || battery?.state === UPowerDeviceState.FullyCharged : false
    property color batteryColor: {
        if (batteryRoot.isCharging) return Theme.primary;
        if (batteryRoot.percentage > 50) return Theme.primary;
        if (batteryRoot.percentage > 20) return Qt.rgba(1.0, 0.7, 0.0, 1.0); // Orange
        return Qt.rgba(1.0, 0.3, 0.3, 1.0); // Red
    }

    // icon + percentage, sized from the text's own implicitWidth and positioned
    // with explicit x/y (no anchors/Layout — both mis-measured or conflicted on
    // the bold % text and let it collapse/overflow). Row when horizontal, column
    // when vertical.
    readonly property int gap: horizontal ? 6 : 2
    implicitWidth:  horizontal ? batteryIcon.width + gap + batteryText.implicitWidth
                               : Math.max(batteryIcon.width, batteryText.implicitWidth)
    implicitHeight: horizontal ? Math.max(batteryIcon.height, batteryText.implicitHeight)
                               : batteryIcon.height + gap + batteryText.implicitHeight

    // Battery icon (simple battery shape)
    Item {
        id: batteryIcon
        width: 20
        height: 10
        x: batteryRoot.horizontal ? 0 : (batteryRoot.width - width) / 2
        y: batteryRoot.horizontal ? (batteryRoot.height - height) / 2 : 0

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
        text: batteryRoot.percentage + "%"
        color: batteryRoot.batteryColor
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
        x: batteryRoot.horizontal ? batteryIcon.width + batteryRoot.gap
                                  : (batteryRoot.width - implicitWidth) / 2
        y: batteryRoot.horizontal ? (batteryRoot.height - implicitHeight) / 2
                                  : batteryIcon.height + batteryRoot.gap
    }
}
