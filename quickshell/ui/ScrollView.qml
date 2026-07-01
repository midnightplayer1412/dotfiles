import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../ui" as Ui

// Scrollable vertical column with a themed scrollbar that RESERVES a right gutter
// when the content overflows — so content is never covered by the bar. Drop-in
// replacement for the "Flickable + ColumnLayout + Ui.ScrollBar" pattern:
//
//   Ui.ScrollView {
//       spacing: 14
//       Text { … }
//       RowLayout { … }
//       …
//   }
//
// Children become items of the inner ColumnLayout (use Layout.* on them as
// usual). The column narrows by `gutter` only while the scrollbar is showing.
Flickable {
    id: root

    property int spacing: 12
    property int gutter: Theme.scrollGutter
    default property alias content: col.data

    readonly property bool overflowing: contentHeight > height + 1

    contentWidth: width
    contentHeight: col.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    ScrollBar.vertical: Ui.ScrollBar { visible: root.overflowing }

    ColumnLayout {
        id: col
        width: root.width - (root.overflowing ? root.gutter : 0)
        spacing: root.spacing
    }
}
