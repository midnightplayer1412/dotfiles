import QtQuick
import QtQuick.Controls
import ".."

// Themed vertical scrollbar — slim, outline-tinted, brighter while dragged, and
// shown only when the content overflows. Matches the rest of the shell instead
// of the default Controls look. Assign to a Flickable's attached property:
//
//   ScrollBar.vertical: Ui.ScrollBar {}
//
ScrollBar {
    id: root
    policy: ScrollBar.AsNeeded
    width: 8

    contentItem: Rectangle {
        implicitWidth: 6
        radius: 3
        color: Theme.outline
        opacity: root.pressed ? 0.9 : 0.5
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }
}
