import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."

PanelWindow {
    id: barWindow

    anchors {
        left: true
        top: true
        bottom: true
    }

    implicitWidth: Theme.barWidth
    margins.left: Theme.barMargin
    margins.top: Theme.barMargin
    margins.bottom: Theme.barMargin

    exclusionMode: ExclusionMode.Auto
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: Theme.barRadius
        color: Theme.surface

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4

            Workspaces {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                Layout.fillWidth: true
                barScreen: barWindow.screen
            }

            Item { Layout.fillHeight: true }

            Clock {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
            }

            Item { Layout.fillHeight: true }

            Tray {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                Layout.fillWidth: true
                barWindow: barWindow
            }
        }
    }
}
