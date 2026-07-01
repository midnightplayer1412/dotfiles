import QtQuick
import QtQuick.Layouts
import "../ui" as Ui
import ".."

// Thin wrapper: "Bluetooth" title header + on/off toggle over BtSection.
Item {
    id: root

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

        BtSection {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
