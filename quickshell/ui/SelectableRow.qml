import QtQuick
import ".."

// Shared full-width selectable/hover row: a themed background that lights up when
// `selected` or hovered, a click signal, and a default content slot. Callers put
// their own RowLayout inside and can tint it via the exposed `hovered`/`selected`.
//
//   Ui.SelectableRow {
//       selected: active; onClicked: pick()
//       RowLayout { anchors.fill: parent; anchors.leftMargin: 10
//           Ui.Icon { color: (parent.parent.selected || parent.parent.hovered) ? primary : text }
//           Text { … }
//       }
//   }
Item {
    id: root

    property bool selected: false
    property bool interactive: true
    property int radius: 9
    property color restColor: "transparent"
    property color hoverColor: Theme.surfaceContainer
    property color selectedColor: Theme.surfaceContainer

    // For callers to tint their own inner content.
    readonly property bool hovered: mouse.containsMouse && interactive

    default property alias content: inner.data
    signal clicked()

    implicitHeight: 38
    implicitWidth: inner.implicitWidth

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.selected ? root.selectedColor
             : (root.hovered ? root.hoverColor : root.restColor)
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Item {
        id: inner
        anchors.fill: parent
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.interactive) root.clicked()
    }
}
