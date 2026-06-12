import QtQuick
import ".."

// One key on the rendered keyboard. Drawn as a beveled keycap sitting in the
// board: a dark bezel with a lighter, gradient "keytop" inset slightly toward
// the top so the cap reads as 3D. Bound keys glow in the primary gradient;
// hovering lifts the cap and reports the key to the detail bar.
Rectangle {
    id: key

    required property string sym     // Hyprland keysym, matches keymap `key`
    required property string label   // display text on the cap
    property real flex: 1            // relative width unit
    property bool isMod: false       // modifier cap (SUPER/SHIFT/CTRL/ALT)

    readonly property var binds: isMod ? [] : KeymapData.bindsForKey(CheatsheetState.activeApp, sym)
    readonly property bool hot: isMod
        ? KeymapData.modActive(CheatsheetState.activeApp, sym)
        : binds.length > 0

    readonly property bool hovered: !isMod && hot && CheatsheetState.hoveredSym === sym

    // Keycap face colors
    readonly property color capTop: hot ? Theme.primary
        : (isMod ? Qt.lighter(Theme.surfaceContainer, 1.25) : Theme.surfaceContainer)
    readonly property color capBottom: hot ? Theme.secondary
        : (isMod ? Theme.surfaceContainer : Qt.darker(Theme.surfaceContainer, 1.45))

    height: 54
    radius: 9

    // Bezel / gap the cap sits in
    color: Qt.darker(Theme.surface, 1.7)
    border.width: 1
    border.color: hot ? Theme.primary : Qt.darker(Theme.outline, 1.4)

    // Hover lift + glow
    scale: hovered ? 1.07 : 1.0
    z: hovered ? 10 : 0
    Behavior on scale     { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    // Soft glow behind bound keys
    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: parent.radius + 2
        color: "transparent"
        border.width: key.hovered ? 3 : 2
        border.color: Theme.primary
        opacity: key.hot ? (key.hovered ? 0.55 : 0.30) : 0
        visible: key.hot
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    // The keytop — inset, with extra bottom bezel for a raised look
    Rectangle {
        id: cap
        anchors.fill: parent
        anchors.topMargin: 3
        anchors.leftMargin: 3
        anchors.rightMargin: 3
        anchors.bottomMargin: 6
        radius: 6
        gradient: Gradient {
            GradientStop { position: 0.0; color: key.capTop }
            GradientStop { position: 1.0; color: key.capBottom }
        }
        // Subtle top highlight line for the molded look
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 2 }
            height: 1
            radius: 1
            color: Qt.rgba(1, 1, 1, key.hot ? 0.30 : 0.06)
        }

        Text {
            anchors.centerIn: parent
            text: key.label
            elide: Text.ElideRight
            width: parent.width - 6
            horizontalAlignment: Text.AlignHCenter
            font.family: Theme.fontFamily
            font.pixelSize: key.label.length > 2 ? Theme.fontSizeSmall : Theme.fontSizeMedium
            font.bold: key.hot
            color: key.hot ? Theme.primaryText
                : (key.isMod ? Theme.surfaceText
                             : Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.45))
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: key.hot && !key.isMod
        enabled: key.hot && !key.isMod
        onEntered: {
            CheatsheetState.hoveredSym = key.sym;
            CheatsheetState.hoveredLabel = key.label;
        }
        onExited: {
            if (CheatsheetState.hoveredSym === key.sym) {
                CheatsheetState.hoveredSym = "";
                CheatsheetState.hoveredLabel = "";
            }
        }
    }
}
