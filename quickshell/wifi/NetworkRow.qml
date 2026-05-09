import QtQuick
import QtQuick.Layouts
import ".."
import "../wifi"

Rectangle {
    id: row
    required property var modelData

    height: 44
    radius: 8
    color: mouse.containsMouse ? Theme.surfaceContainer : "transparent"
    Behavior on color { ColorAnimation { duration: 100 } }

    readonly property bool secured: modelData?.security && modelData.security !== ""
    readonly property bool isPending: WifiService.pendingSsid === modelData?.ssid && WifiService.connecting

    function signalGlyph(s) {
        if (s > 75) return "\u{F0928}";  // wifi-strength-4
        if (s > 50) return "\u{F0925}";  // wifi-strength-3
        if (s > 25) return "\u{F0922}";  // wifi-strength-2
        return "\u{F091F}";              // wifi-strength-1
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        Text {
            text: row.signalGlyph(row.modelData?.signal ?? 0)
            font.family: "Monaspace Argon NF"
            font.pixelSize: 16
            color: Theme.primary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: row.modelData?.ssid ?? ""
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: row.modelData?.saved ? "saved"
                      : (row.secured ? "secured" : "open")
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        // Lock or spinner
        Text {
            visible: row.secured || row.isPending
            text: row.isPending ? "…" : "\u{F033E}"   // lock
            font.family: "Monaspace Argon NF"
            font.pixelSize: 14
            color: Theme.primary
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (e) => {
            if (e.button === Qt.LeftButton) {
                WifiService.connect(row.modelData.ssid);
            } else if (e.button === Qt.RightButton && row.modelData.saved) {
                WifiService.forget(row.modelData.ssid);
            }
        }
    }
}
