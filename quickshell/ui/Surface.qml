import QtQuick
import ".."
import "../ui"

// Shared surface primitive: a themable panel/card background that follows the
// active surface preset (Solid | Glass) chosen in Settings → Appearance.
//
// Drop-in for `Rectangle { color: Theme.surface; ...children... }`:
//   Ui.Surface { level: 0; radius: 16; ...children... }
//
//   level 0 = panel / window base surface (was Theme.surface)
//   level 1 = inner card                  (was Theme.surfaceContainer)
//
// Children are placed inside the surface (default content), so existing layouts
// that anchored to the old Rectangle keep working — `parent` inside the content
// resolves to a full-bleed Item over the background.
//
// Set `preset` to force a specific look regardless of the global choice — used
// by the Settings preview cards to show Solid and Glass side by side.
Item {
    id: root

    property int  level: 0
    property real radius: 12                 // callers pass their own (barRadius, launcherRadius, …)
    property bool showBorder: true           // rare surfaces (e.g. thin bar) may opt out
    property bool showHighlight: true
    property string preset: ""               // "" = follow global UiStyle.surface

    readonly property var tokens: preset === "" ? null : Surfaces.tokensFor(preset)
    readonly property bool isGlass: tokens ? tokens.isGlass : Surfaces.isGlass
    readonly property color surfaceColor: {
        const t = tokens;
        if (t) return level >= 1 ? t.card : t.base;
        return level >= 1 ? Surfaces.cardColor : Surfaces.baseColor;
    }
    readonly property int   _borderWidth: tokens ? tokens.borderWidth : Surfaces.borderWidth
    readonly property color _borderColor: tokens ? tokens.borderColor : Surfaces.borderColor
    readonly property color _highlightColor: tokens ? tokens.highlight : Surfaces.highlightColor

    default property alias content: contentItem.data

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: root.radius
        color: root.surfaceColor
        border.width: (root.showBorder && root._borderWidth > 0) ? root._borderWidth : 0
        border.color: root._borderColor

        // Subtle top-edge highlight — glass only. Sits just inside the border.
        Rectangle {
            visible: root.showHighlight && root.isGlass
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: root.radius / 2
            anchors.rightMargin: root.radius / 2
            anchors.topMargin: 1
            height: 1
            color: root._highlightColor
        }

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // Content lives above the background, full-bleed.
    Item {
        id: contentItem
        anchors.fill: parent
    }
}
