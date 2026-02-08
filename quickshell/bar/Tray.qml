import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    id: trayRoot
    spacing: 4

    required property var barWindow

    Repeater {
        model: SystemTray.items

        TrayItem {
            required property var modelData

            Layout.alignment: Qt.AlignHCenter
            item: modelData
            barWindow: trayRoot.barWindow
        }
    }
}
