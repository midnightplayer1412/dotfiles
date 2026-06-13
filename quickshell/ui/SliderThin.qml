import QtQuick
import ".."

// Thin slider: 6px rounded track, primary fill, knob on hover/drag.
// Generalises audio/VolumeSlider with from/to/stepSize so it covers ranged use
// (e.g. blur 0..10) as well as normalised 0..1. Controlled: owner sets `value`,
// dragging emits moved(newValue).
Item {
    id: sl

    property real from: 0
    property real to: 1
    property real stepSize: 0
    property real value: 0
    property color fillColor: Theme.primary
    property bool active: true
    signal moved(real v)
    signal released()        // drag finished — owner can persist here

    implicitHeight: 18
    height: implicitHeight

    readonly property real _frac:
        (to > from) ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0

    function _applyFrac(f) {
        f = Math.max(0, Math.min(1, f));
        let v = from + f * (to - from);
        if (stepSize > 0) v = Math.round(v / stepSize) * stepSize;
        sl.moved(Math.max(from, Math.min(to, v)));
    }

    // Bubble label: a normalised slider (range ≤ 1, e.g. volume/opacity/dim)
    // reads as a percentage; wider ranges (thickness, radius, …) read as integers.
    function _fmt(v) {
        return (to - from) <= 1 ? Math.round(v * 100) + "%" : Math.round(v).toString();
    }

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        radius: 3
        color: Theme.surfaceContainer

        Rectangle {
            id: fill
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * sl._frac
            radius: 3
            color: sl.active ? sl.fillColor : Theme.outline
        }

        Rectangle {
            width: 14
            height: 14
            radius: 7
            color: sl.active ? sl.fillColor : Theme.outline
            border.color: Theme.surface
            border.width: 2
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(track.width - width, fill.width - width / 2))
            visible: drag.containsMouse || drag.pressed
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        anchors.topMargin: -6
        anchors.bottomMargin: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: (m) => sl._applyFrac(m.x / width)
        onPositionChanged: (m) => { if (pressed) sl._applyFrac(m.x / width); }
        onReleased: sl.released()
    }

    // Value bubble — follows the knob, shown on hover or drag.
    Rectangle {
        id: bubble
        visible: drag.containsMouse || drag.pressed
        z: 100
        radius: 5
        color: Theme.surfaceContainer
        border.color: Theme.outline
        border.width: 1
        width: bubbleText.implicitWidth + 12
        height: bubbleText.implicitHeight + 6
        x: Math.max(0, Math.min(sl.width - width, fill.width - width / 2))
        y: -height - 4
        Text {
            id: bubbleText
            anchors.centerIn: parent
            text: sl._fmt(sl.value)
            color: Theme.surfaceText
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true
        }
    }
}
