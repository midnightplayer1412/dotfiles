import QtQuick
import QtQuick.Controls
import ".."

// Themed vertical scrollbar — slim, outline-tinted. Auto-hides: it's invisible
// at rest and fades in only while scrolling (active) or while the pointer is
// over the scrollbar strip (hovered). Shown only when content overflows.
//
//   ScrollBar.vertical: Ui.ScrollBar {}
//
ScrollBar {
    id: root
    policy: ScrollBar.AsNeeded
    width: 8

    readonly property bool revealed: root.active || root.hovered

    contentItem: Rectangle {
        implicitWidth: 6
        radius: 3
        color: Theme.outline
        opacity: root.revealed ? (root.pressed ? 0.9 : 0.55) : 0.0
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }
}
