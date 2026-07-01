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
                text: "Forget device?"
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: BluetoothService.pendingForgetName
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 13
                elide: Text.ElideMiddle
            }

            Text {
                Layout.fillWidth: true
                text: "You'll need to pair it again to reconnect."
                color: Theme.outline
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
                    onClicked: BluetoothService.confirmForget(false)
                }

                Ui.Button {
                    kind: "danger"
                    text: "Forget"
                    onClicked: BluetoothService.confirmForget(true)
                }
            }
        }
    }
}
