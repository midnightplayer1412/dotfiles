import QtQuick
import QtQuick.Layouts
import "../ui" as Ui
import ".."
import "../bluetooth"

Rectangle {
    id: root

    color: Qt.rgba(0, 0, 0, 0.6)
    radius: Theme.drawerRadius

    Ui.Surface {
        level: 0
        anchors.centerIn: parent
        width: parent.width - 40
        radius: 12
        height: contentCol.implicitHeight + 32

        ColumnLayout {
            id: contentCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 16
            }
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: "Confirm pairing"
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: BluetoothService.pendingConfirmDevice
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideMiddle
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: BluetoothService.pendingConfirmCode
                color: Theme.primary
                font.family: "Monaspace Argon NF"
                font.pixelSize: 28
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: "Does this code match the one on the device?"
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                Ui.Button {
                    kind: "ghost"
                    text: "Cancel"
                    onClicked: BluetoothService.confirmPair(false)
                }

                Ui.Button {
                    kind: "primary"
                    text: "Pair"
                    onClicked: BluetoothService.confirmPair(true)
                }
            }
        }
    }
}
