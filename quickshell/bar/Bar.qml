import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."

PanelWindow {
    id: barWindow

    readonly property bool horizontal: BarConfig.horizontal

    // Dock to the configured edge. Vertical bars (left/right) span top↔bottom;
    // horizontal bars (top/bottom) span left↔right.
    anchors {
        left:   BarConfig.position === "left"   || barWindow.horizontal
        right:  BarConfig.position === "right"  || barWindow.horizontal
        top:    BarConfig.position === "top"    || !barWindow.horizontal
        bottom: BarConfig.position === "bottom" || !barWindow.horizontal
    }

    margins {
        left: Theme.barMargin
        right: Theme.barMargin
        top: Theme.barMargin
        bottom: Theme.barMargin
    }

    // Thickness lives on the cross-axis; the spanned axis is sized by anchors.
    implicitWidth: barWindow.horizontal ? 0 : Theme.barWidth
    implicitHeight: barWindow.horizontal ? Theme.barWidth : 0
    exclusionMode: ExclusionMode.Auto
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: Theme.barRadius
        color: Theme.surface

        // start ─ spacer ─ center ─ spacer ─ end, flipped Row/Column with the bar.
        GridLayout {
            anchors.fill: parent
            anchors.margins: 4
            rows: barWindow.horizontal ? 1 : -1
            columns: barWindow.horizontal ? -1 : 1
            rowSpacing: 4
            columnSpacing: 4

            BarZone {
                zone: "start"
                horizontal: barWindow.horizontal
                barScreen: barWindow.screen
                Layout.alignment: Qt.AlignCenter
            }
            Item {
                Layout.fillWidth: barWindow.horizontal
                Layout.fillHeight: !barWindow.horizontal
            }
            BarZone {
                zone: "center"
                horizontal: barWindow.horizontal
                barScreen: barWindow.screen
                Layout.alignment: Qt.AlignCenter
            }
            Item {
                Layout.fillWidth: barWindow.horizontal
                Layout.fillHeight: !barWindow.horizontal
            }
            BarZone {
                zone: "end"
                horizontal: barWindow.horizontal
                barScreen: barWindow.screen
                Layout.alignment: Qt.AlignCenter
            }
        }
    }
}
