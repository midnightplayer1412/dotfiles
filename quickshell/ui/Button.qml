import QtQuick
import QtQuick.Layouts
import ".."
import "../ui"

// Shared pill button. Semantic `kind` picks the palette; the call site chooses
// by meaning, not by aesthetics. Colors track Theme (so matugen + Glass/Solid
// re-skin it for free). Content is a glyph and/or an svg icon and/or a label.
//
//   Ui.Button { kind: "danger"; text: "Forget"; onClicked: … }
//   Ui.Button { kind: "primary"; text: "Connect"; busy: connecting }
//   Ui.Button { kind: "chip"; text: action.text; onClicked: … }
//
// kinds:
//   filled  — surfaceContainer → primary on hover (default action pill)
//   primary — primaryContainer → primary on hover, bold (emphasis)
//   ghost   — transparent, outline border, fills on hover (Cancel)
//   danger  — errorContainer → error on hover, bold (destructive)
//   chip    — primary-bordered, fills primary on hover (tag action)
Item {
    id: root

    property string kind: "filled"       // filled | primary | ghost | danger | chip
    property string text: ""
    property string glyph: ""            // Nerd Font glyph (optional)
    property string iconSource: ""       // svg icon path/url (optional)
    property int fontSize: 11
    property bool enabled: true
    property bool active: false          // toggle-like emphasis (renders as hovered)
    property bool busy: false            // in-flight; blocks clicks, dims
    property int hPadding: kind === "primary" ? 22 : kind === "ghost" ? 18 : 20

    signal clicked()

    readonly property bool interactive: enabled && !busy
    readonly property bool lit: (mouse.containsMouse && interactive) || active

    implicitHeight: 28
    implicitWidth: Math.max(row.implicitWidth + hPadding, height)

    // Per-kind palette. `text`/`textHover` are the label colors at rest/lit.
    readonly property var pal: {
        switch (kind) {
        case "primary": return { rest: Theme.primaryContainer, hover: Theme.primary,
                                 text: Theme.surfaceText, textHover: Theme.primaryText,
                                 border: "transparent", bold: true };
        case "ghost":   return { rest: "transparent", hover: Theme.surface,
                                 text: Theme.surfaceText, textHover: Theme.surfaceText,
                                 border: Theme.outline, bold: false };
        case "danger":  return { rest: Theme.errorContainer, hover: Theme.error,
                                 text: Theme.errorText, textHover: Theme.errorText,
                                 border: "transparent", bold: true };
        case "chip":    return { rest: Theme.surfaceContainer, hover: Theme.primary,
                                 text: Theme.primary, textHover: Theme.primaryText,
                                 border: Theme.primary, bold: false };
        default:        return { rest: Theme.surfaceContainer, hover: Theme.primary,
                                 text: Theme.surfaceText, textHover: Theme.primaryText,
                                 border: "transparent", bold: false };
        }
    }
    readonly property color contentColor: lit ? pal.textHover : pal.text

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: height / 2
        color: root.lit ? root.pal.hover : root.pal.rest
        border.width: (root.kind === "ghost" || root.kind === "chip") ? 1 : 0
        border.color: root.pal.border
        opacity: root.interactive ? 1.0 : 0.55
        scale: (mouse.pressed && root.interactive) ? 0.96 : 1.0
        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on scale { NumberAnimation { duration: 80 } }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: root.glyph.length > 0
            text: root.glyph
            color: root.contentColor
            font.family: Theme.glyphFont
            font.pixelSize: root.fontSize + 3
        }
        Icon {
            visible: root.iconSource.length > 0
            source: root.iconSource
            color: root.contentColor
            size: root.fontSize + 3
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            visible: root.text.length > 0
            text: root.text
            color: root.contentColor
            font.family: Theme.fontFamily
            font.pixelSize: root.fontSize
            font.bold: root.pal.bold
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.interactive) root.clicked()
    }
}
