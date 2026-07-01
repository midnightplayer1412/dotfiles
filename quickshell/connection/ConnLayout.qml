import QtQuick
import "../ui"
import "layouts"

// Dispatcher: renders the connection layout variant chosen in
// UiStyle.connectionLayout. All variants consume the same WifiSection /
// BtSection / VpnSection, so behavior is identical — only arrangement differs.
Item {
    id: root

    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: UiStyle.connectionLayout === "accordion" ? cAccordion
                       : UiStyle.connectionLayout === "stacked"   ? cStacked
                       : cTiles
    }

    Component { id: cTiles;     ConnTiles {} }
    Component { id: cAccordion; ConnAccordion {} }
    Component { id: cStacked;   ConnStacked {} }
}
