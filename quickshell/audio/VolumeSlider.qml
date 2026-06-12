import QtQuick
import ".."

// Reusable horizontal volume slider. Controlled: `value` is set by the owner
// (bound to a node's volume); dragging emits `moved(v)` for the owner to apply.
Item {
    id: sl

    property real value: 0            // 0..1
    property color fillColor: Theme.primary
    property bool active: true        // dimmed when muted
    signal moved(real v)

    implicitHeight: 18
    height: implicitHeight

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
            width: parent.width * Math.max(0, Math.min(1, sl.value))
            radius: 3
            color: sl.active ? sl.fillColor : Theme.outline
        }

        // Knob — appears on hover/drag
        Rectangle {
            width: 14
            height: 14
            radius: 7
            color: sl.active ? sl.fillColor : Theme.outline
            border.color: Theme.surface
            border.width: 2
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(track.width - width, fill.width - width / 2))
            visible: dragArea.containsMouse || dragArea.pressed
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        anchors.topMargin: -6
        anchors.bottomMargin: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function apply(mx) {
            sl.moved(Math.max(0, Math.min(1, mx / width)));
        }
        onPressed: (m) => apply(m.x)
        onPositionChanged: (m) => { if (pressed) apply(m.x); }
    }
}
