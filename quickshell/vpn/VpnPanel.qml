import QtQuick
import QtQuick.Layouts
import ".."

// Thin wrapper: "VPN" title header over VpnSection (VPN has no global toggle).
Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Text {
            Layout.fillWidth: true
            text: "VPN"
            color: Theme.surfaceText
            font.family: Theme.fontFamily
            font.pixelSize: 18
            font.bold: true
        }

        VpnSection {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
