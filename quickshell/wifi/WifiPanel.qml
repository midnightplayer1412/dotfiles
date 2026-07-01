import QtQuick
import QtQuick.Layouts
import "../ui" as Ui
import ".."

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
                text: "Wi-Fi"
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.bold: true
            }

            Ui.Toggle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 24
                checked: WifiService.enabled
                onToggled: (v) => WifiService.setEnabled(v)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            visible: WifiService.connected
            radius: 12
            color: Theme.primaryContainer

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: WifiService.activeSsid
                        color: Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "Connected · " + WifiService.activeSignal + "%"
                        color: Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        opacity: 0.7
                    }
                }

                Ui.Button {
                    kind: "filled"
                    text: "Disconnect"
                    onClicked: WifiService.disconnect()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: errStripText.implicitHeight + 16
            visible: WifiService.lastError.length > 0 && WifiService.pendingPasswordSsid.length === 0
            radius: 8
            color: Qt.rgba(1.0, 0.4, 0.4, 0.15)
            border.color: Qt.rgba(1.0, 0.4, 0.4, 0.4)
            border.width: 1

            Text {
                id: errStripText
                anchors.fill: parent
                anchors.margins: 8
                text: WifiService.lastError
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: WifiService.clearError()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Available networks"
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
            }

            Ui.IconButton {
                bg: "bare"
                glyph: WifiService.scanning ? "…" : "↻"
                onClicked: WifiService.refresh()
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: WifiService.networks

            delegate: NetworkRow {
                width: ListView.view ? ListView.view.width : 0
                visible: !modelData.active
                height: visible ? 44 : 0
            }
        }

        Timer {
            interval: 10000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: WifiService.refresh()
        }
    }

    PasswordPrompt {
        anchors.fill: parent
        visible: WifiService.pendingPasswordSsid.length > 0
    }
}
