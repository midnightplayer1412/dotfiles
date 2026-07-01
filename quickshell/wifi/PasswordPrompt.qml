import QtQuick
import QtQuick.Layouts
import "../ui" as Ui
import ".."
import "../wifi"

Rectangle {
    id: root
    color: Qt.rgba(0, 0, 0, 0.55)
    radius: 16

    property string targetSsid: WifiService.pendingPasswordSsid
    onTargetSsidChanged: {
        pwField.text = "";
        if (targetSsid.length > 0) pwField.input.forceActiveFocus();
    }

    Ui.Surface {
        level: 1
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: contentCol.implicitHeight + 28
        radius: 16

        ColumnLayout {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Connect to " + root.targetSsid
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
            }

            Ui.TextField {
                id: pwField
                Layout.fillWidth: true
                variant: "field"
                placeholder: "Password"
                echoMode: TextInput.Password
                onAccepted: WifiService.connectWithPassword(root.targetSsid, pwField.text)
            }

            Text {
                Layout.fillWidth: true
                visible: WifiService.lastError.length > 0
                text: WifiService.lastError
                color: "#ff6b6b"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 8

                Item { Layout.fillWidth: true }

                Ui.Button {
                    kind: "ghost"
                    text: "Cancel"
                    onClicked: WifiService.cancelPasswordPrompt()
                }

                Ui.Button {
                    kind: "primary"
                    text: WifiService.connecting ? "Connecting…" : "Connect"
                    busy: WifiService.connecting
                    onClicked: WifiService.connectWithPassword(root.targetSsid, pwField.text)
                }
            }
        }
    }
}
