import QtQuick
import "../ui"

// Dispatcher: renders whichever toggle variant is selected in UiStyle.toggle.
// Public API matches the variants (checked + toggled), so callers use Ui.Toggle
// and automatically follow the global Appearance setting.
Item {
    id: root

    property bool checked: false
    signal toggled(bool value)

    implicitWidth: loader.item ? loader.item.implicitWidth : 44
    implicitHeight: loader.item ? loader.item.implicitHeight : 24

    Loader {
        id: loader
        anchors.centerIn: parent
        sourceComponent: UiStyle.toggle === "square" ? cSquare
                       : UiStyle.toggle === "notch" ? cNotch
                       : cCapsule
    }

    Component { id: cCapsule; ToggleCapsule { checked: root.checked; onToggled: (v) => root.toggled(v) } }
    Component { id: cSquare;  ToggleSquare  { checked: root.checked; onToggled: (v) => root.toggled(v) } }
    Component { id: cNotch;   ToggleNotch   { checked: root.checked; onToggled: (v) => root.toggled(v) } }
}
