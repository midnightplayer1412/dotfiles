import QtQuick
import ".."

// Thick slider: a tall rounded pill bar (HUD-like) with an inset fill and a
// grab knob. Same API as SliderThin (from/to/stepSize/value/moved) so the two
// are drop-in interchangeable.
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

    implicitHeight: 22
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
        anchors.fill: parent
        radius: height / 2
        color: Theme.surfaceContainer

        Rectangle {
            id: fill
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            // Keep the fill at least round-cap wide so it reads cleanly near 0.
            width: Math.max(sl._frac > 0 ? parent.height : 0, parent.width * sl._frac)
            radius: parent.radius
            color: sl.active ? sl.fillColor : Theme.outline
        }

        Rectangle {
            id: knob
            width: parent.height - 8
            height: parent.height - 8
            radius: width / 2
            color: Theme.surface
            anchors.verticalCenter: parent.verticalCenter
            // Ride fully INSIDE the bar at the fill's leading edge (a ticker
            // within the bar), rather than straddling the fill tip. Always shown.
            x: Math.max(4, Math.min(track.width - width - 4, fill.width - width - 4))
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
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
        x: Math.max(0, Math.min(sl.width - width, knob.x + knob.width / 2 - width / 2))
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
