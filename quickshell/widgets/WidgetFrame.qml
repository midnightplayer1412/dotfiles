import QtQuick
import ".."
import "../ui" as Ui

// Chrome wrapper shared by both hosts. Sizes itself from the widget's registry
// descriptor times `scaleFactor`, draws the shared Surface background (crisp at
// the scaled size), and scales the CONTENT so text/graphics grow with the box.
// Re-exposes the widget's `relevant` so hosts can gate visibility/layout.
Item {
    id: frame
    property string widgetId: ""
    property Component content: null
    property bool enabled: true
    property real scaleFactor: 1

    property alias item: loader.item
    readonly property bool relevant: (loader.item && loader.item.relevant !== undefined) ? loader.item.relevant : true

    readonly property var _d: WidgetRegistry.descriptors[widgetId] || ({ w: 200, h: 120 })
    implicitWidth: _d.w * scaleFactor
    implicitHeight: _d.h * scaleFactor
    width: implicitWidth
    height: implicitHeight
    visible: enabled && relevant

    // Background fills the scaled box and is drawn at full resolution (crisp).
    Ui.Surface {
        anchors.fill: parent
        level: 1
        radius: 16
    }

    // Content laid out at natural (descriptor) size, then scaled to fill — so the
    // clock digits, calendar grid, etc. grow proportionally rather than getting
    // extra padding.
    Item {
        id: contentBox
        width: frame._d.w
        height: frame._d.h
        transformOrigin: Item.TopLeft
        scale: frame.scaleFactor
        Loader {
            id: loader
            anchors.fill: parent
            anchors.margins: 10
            sourceComponent: frame.content
        }
    }
}
