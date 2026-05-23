import QtQuick
import QtQuick.Layouts
import ".."
import "../audio"

Item {
    id: root

    Component.onCompleted: AudioService.refresh()

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Text {
            text: "Audio Output"
            color: Theme.surfaceText
            font.family: Theme.fontFamily
            font.pixelSize: 18
            font.bold: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: errText.implicitHeight + 16
            visible: AudioService.lastError.length > 0
            radius: 8
            color: Qt.rgba(1.0, 0.4, 0.4, 0.15)
            border.color: Qt.rgba(1.0, 0.4, 0.4, 0.4)
            border.width: 1

            Text {
                id: errText
                anchors.fill: parent
                anchors.margins: 8
                text: AudioService.lastError
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: AudioService.clearError()
            }
        }

        Repeater {
            model: AudioService.sinks
            delegate: OutputRow { Layout.fillWidth: true }
        }

        Item { Layout.fillHeight: true }
    }
}
