import QtQuick
import ".."
import "../ui" as Ui

// Chrome wrapper shared by both hosts. Sizes itself from the widget's registry
// descriptor, draws the shared Surface background, hosts the widget content, and
// re-exposes the widget's `relevant` so hosts can gate visibility/layout.
Item {
    id: frame
    property string widgetId: ""
    property Component content: null
    property bool enabled: true

    property alias item: loader.item
    readonly property bool relevant: (loader.item && loader.item.relevant !== undefined) ? loader.item.relevant : true

    readonly property var _d: WidgetRegistry.descriptors[widgetId] || ({ w: 200, h: 120 })
    implicitWidth: _d.w
    implicitHeight: _d.h
    width: implicitWidth
    height: implicitHeight
    visible: enabled && relevant

    Ui.Surface {
        anchors.fill: parent
        level: 1
        radius: 16
        Loader {
            id: loader
            anchors.fill: parent
            anchors.margins: 10
            sourceComponent: frame.content
        }
    }
}
