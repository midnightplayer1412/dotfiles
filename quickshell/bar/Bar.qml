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
    implicitWidth: barWindow.horizontal ? 0 : BarConfig.thickness
    implicitHeight: barWindow.horizontal ? BarConfig.thickness : 0
    exclusionMode: ExclusionMode.Auto
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: BarConfig.radius
        // Fade only the background (not the widgets) via the surface colour's alpha.
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, BarConfig.bgOpacity)

        // Content area with end padding along the bar's length; the thin
        // cross-axis keeps a fixed 4px inset.
        Item {
            id: content
            anchors.fill: parent
            anchors.leftMargin:   barWindow.horizontal ? BarConfig.endPadding : 4
            anchors.rightMargin:  barWindow.horizontal ? BarConfig.endPadding : 4
            anchors.topMargin:    barWindow.horizontal ? 4 : BarConfig.endPadding
            anchors.bottomMargin: barWindow.horizontal ? 4 : BarConfig.endPadding

            // Three zones positioned by explicit x/y (NOT conditional anchors —
            // those leave stale anchors from the other orientation that don't
            // clear, which mis-placed the end zone off-screen). start pins to the
            // leading edge, end to the trailing edge, center locked to the bar's
            // TRUE center so it never drifts when a side zone changes width.
            BarZone {
                id: startZone
                zone: "start"
                horizontal: barWindow.horizontal
                barScreen: barWindow.screen
                x: barWindow.horizontal ? 0 : (content.width - width) / 2
                y: barWindow.horizontal ? (content.height - height) / 2 : 0
            }
            BarZone {
                id: centerZone
                zone: "center"
                horizontal: barWindow.horizontal
                barScreen: barWindow.screen
                x: (content.width - width) / 2
                y: (content.height - height) / 2
            }
            BarZone {
                id: endZone
                zone: "end"
                horizontal: barWindow.horizontal
                barScreen: barWindow.screen
                x: barWindow.horizontal ? (content.width - width) : (content.width - width) / 2
                y: barWindow.horizontal ? (content.height - height) / 2 : (content.height - height)
            }
        }
    }
}
