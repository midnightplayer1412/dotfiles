import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../ui" as Ui
import ".."
import "../bluetooth"

Item {
    id: root

    // Filter helpers
    readonly property var paired:    BluetoothService.devices.filter(d => d.paired && !d.connected)
    readonly property var connected: BluetoothService.devices.filter(d => d.connected)
    readonly property var others:    BluetoothService.devices.filter(d => !d.paired)

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Bluetooth"
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.bold: true
            }

            Ui.Toggle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 24
                checked: BluetoothService.enabled
                onToggled: (v) => BluetoothService.setEnabled(v)
            }
        }

        // Error strip
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: btErrText.implicitHeight + 16
            visible: BluetoothService.lastError.length > 0
                && BluetoothService.pendingConfirmDevice.length === 0
                && BluetoothService.pendingForgetMac.length === 0
            radius: 8
            color: Qt.rgba(1.0, 0.4, 0.4, 0.15)
            border.color: Qt.rgba(1.0, 0.4, 0.4, 0.4)
            border.width: 1

            Text {
                id: btErrText
                anchors.fill: parent
                anchors.margins: 8
                text: BluetoothService.lastError
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: BluetoothService.clearError()
            }
        }

        // Section: connected devices
        Text {
            Layout.fillWidth: true
            text: "Connected"
            color: Theme.outline
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true
            visible: root.connected.length > 0
        }
        Repeater {
            model: root.connected
            delegate: DeviceRow { width: parent ? parent.width : 0 }
        }

        // Section: paired (not connected)
        Text {
            Layout.fillWidth: true
            text: "Paired"
            color: Theme.outline
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true
            visible: root.paired.length > 0
        }
        Repeater {
            model: root.paired
            delegate: DeviceRow { width: parent ? parent.width : 0 }
        }

        // Section: nearby (scan results) + scan toggle
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Nearby"
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
            }

            Text {
                text: BluetoothService.scanning ? "Stop scan" : "Scan"
                color: Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 11
                opacity: scanMouse.containsMouse ? 1.0 : 0.7

                MouseArea {
                    id: scanMouse
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BluetoothService.scanning
                        ? BluetoothService.stopScan()
                        : BluetoothService.startScan()
                }
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical: Ui.ScrollBar {}
            spacing: 4
            model: root.others
            delegate: DeviceRow { width: ListView.view ? ListView.view.width : 0 }
        }
    }

    PairConfirm {
        anchors.fill: parent
        visible: BluetoothService.pendingConfirmDevice.length > 0
    }

    ForgetConfirm {
        anchors.fill: parent
        visible: BluetoothService.pendingForgetMac.length > 0
    }
}
