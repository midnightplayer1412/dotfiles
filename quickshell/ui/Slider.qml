import QtQuick
import "../ui"
import ".."

// Dispatcher: renders whichever slider variant is selected in UiStyle.slider.
// Public API matches the variants (from/to/stepSize/value/fillColor/active +
// moved/released), so callers use Ui.Slider and follow the global setting.
Item {
    id: root

    property real from: 0
    property real to: 1
    property real stepSize: 0
    property real value: 0
    property color fillColor: Theme.primary
    property bool active: true
    signal moved(real v)
    signal released()

    implicitHeight: loader.item ? loader.item.implicitHeight : 18

    Loader {
        id: loader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: UiStyle.slider === "thick" ? cThick : cThin
    }

    Component {
        id: cThin
        SliderThin {
            from: root.from; to: root.to; stepSize: root.stepSize; value: root.value
            fillColor: root.fillColor; active: root.active
            onMoved: (v) => root.moved(v); onReleased: root.released()
        }
    }
    Component {
        id: cThick
        SliderThick {
            from: root.from; to: root.to; stepSize: root.stepSize; value: root.value
            fillColor: root.fillColor; active: root.active
            onMoved: (v) => root.moved(v); onReleased: root.released()
        }
    }
}
