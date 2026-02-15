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

    margins {
      left: Theme.barMargin
      top: Theme.barMargin
      bottom: Theme.barMargin
    }

    implicitWidth: Theme.barWidth
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
                Layout.margins: Theme.barMargin
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

            Battery {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                Layout.fillWidth: true
            }
        }
    }
}
