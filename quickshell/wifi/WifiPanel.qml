import QtQuick
import QtQuick.Layouts
import "../ui" as Ui
import ".."

// Thin wrapper: "Wi-Fi" title header + on/off toggle over the reusable WifiSection.
// Used by the stacked connection layout and as a standalone panel.
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

        WifiSection {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
