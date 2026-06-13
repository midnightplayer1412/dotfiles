import QtQuick
import Qt5Compat.GraphicalEffects

// SVG/theme icon rendered at an exact pixel size. Because the SVG is rasterised
// at `size` (sourceSize == size), apparent size is deterministic — icons never
// vary the way font glyphs do.
//
// When `color` is set (alpha > 0) the icon is recoloured to it via ColorOverlay.
// That's what lets the monochrome Papirus *symbolic* icons (which are authored
// as fill="currentColor" and would otherwise render black) be tinted to the
// Matugen accent, matching the rest of the shell. Leave `color` transparent to
// show the source artwork as-is (e.g. full-colour app icons).
//
// Note: Image.implicitWidth/Height are read-only, so the wrapper is an Item and
// the implicit size (used by layouts) comes from `size`.
Item {
    id: root
    property url source: ""
    property int size: 18
    property color color: "transparent"
    readonly property bool tinted: root.color.a > 0

    implicitWidth: size
    implicitHeight: size

    Image {
        id: img
        anchors.centerIn: parent
        width: root.size
        height: root.size
        source: root.source
        sourceSize.width: root.size
        sourceSize.height: root.size
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
        cache: true
        visible: !root.tinted   // hidden when tinted; ColorOverlay draws it
    }
    ColorOverlay {
        anchors.fill: img
        source: img
        color: root.color
        visible: root.tinted
    }
}
