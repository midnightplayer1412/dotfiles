import QtQuick
import ".."
import "../ui"

// Shared glyph icon-button. Two backgrounds:
//   bg: "filled" — round tile that fills on hover / when active (DND, month-nav)
//   bg: "bare"   — no tile; the glyph itself tints on hover (mute, dismiss, refresh)
//
//   Ui.IconButton { glyph: "\u{F0156}"; onClicked: dismiss() }              // bare
//   Ui.IconButton { bg: "filled"; active: dnd; glyph: dnd ? off : on; … }   // tile
Item {
    id: root

    property string glyph: ""            // Nerd Font glyph
    property string iconSource: ""       // svg icon (alternative to glyph)
    property string bg: "bare"           // filled | bare
    property int size: 28                // tile size (filled) / hit box (bare)
    property int glyphSize: 15
    property bool enabled: true
    property bool active: false          // filled: primary tile; bare: primary glyph

    signal clicked()

    readonly property bool interactive: enabled
    readonly property bool lit: mouse.containsMouse && interactive

    implicitWidth: size
    implicitHeight: size

    // Glyph color. Disabled → outline; active/lit → accent (or primaryText on a filled tile).
    readonly property color glyphColor: {
        if (!interactive) return Theme.outline;
        if (bg === "filled") return active ? Theme.primaryText : Theme.surfaceText;
        return (active || lit) ? Theme.primary : Theme.surfaceText;
    }

    // Filled tile background (bare draws nothing).
    Rectangle {
        anchors.fill: parent
        visible: root.bg === "filled"
        radius: height / 2
        color: root.active ? Theme.primary
             : (root.lit ? Theme.surfaceContainer : "transparent")
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Text {
        anchors.centerIn: parent
        visible: root.glyph.length > 0
        text: root.glyph
        color: root.glyphColor
        font.family: Theme.glyphFont
        font.pixelSize: root.glyphSize
        Behavior on color { ColorAnimation { duration: 100 } }
    }
    Icon {
        anchors.centerIn: parent
        visible: root.iconSource.length > 0
        source: root.iconSource
        color: root.glyphColor
        size: root.glyphSize
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        // Slight negative slop gives bare glyphs a comfortable hit target.
        anchors.margins: root.bg === "bare" ? -3 : 0
        hoverEnabled: true
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.interactive) root.clicked()
    }
}
