import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."

Rectangle {
    id: root

    // HyprlandToplevel: { address, workspace, monitor, wayland, lastIpcObject, ... }
    required property var toplevel

    // Home geometry in parent (cell) coords, computed by OverviewWidget from
    // window.at/size and monitor dimensions. Drag breaks the x/y bindings; we
    // restore them on release so the tile snaps back to its proportional slot.
    required property real tileX
    required property real tileY
    required property real tileW
    required property real tileH

    // Item whose bounds constrain the drag (the OverviewWidget root).
    property Item constrainTo: null

    property bool hovered: false
    readonly property bool dragging: dragArea.drag.active

    signal clicked()

    readonly property string appClass: toplevel?.lastIpcObject?.class ?? ""
    readonly property string title:    toplevel?.lastIpcObject?.title ?? ""
    readonly property bool   active:   toplevel?.activated ?? false
    readonly property string address:  toplevel?.address ?? ""

    x: tileX
    y: tileY
    width:  tileW
    height: tileH

    radius: 4
    color: dragging ? Theme.primaryContainer
         : hovered  ? Theme.surfaceContainer
         :             Qt.darker(Theme.surface, 1.1)
    border.width: active ? 2 : 1
    border.color: active ? Theme.primary : Theme.outline
    clip: true

    opacity: dragging ? 0.9 : 1.0
    z: dragging ? 1000 : 0

    Behavior on color       { ColorAnimation { duration: 100 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    Drag.active: dragArea.drag.active
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2
    Drag.keys: ["overview-window"]
    Drag.source: root

    // Live screencopy preview — captures only while the overview is open and
    // the feature is enabled. Visibility is gated on hasContent so the tile's
    // background + icon/label remain visible if the capture fails (common on
    // NVIDIA proprietary, where wlr-screencopy DMA-BUF can be flaky).
    ScreencopyView {
        id: preview
        anchors.fill: parent
        anchors.margins: 1
        captureSource: Theme.overviewLivePreviews
                    && OverviewState.visible
                    && root.toplevel?.wayland
            ? root.toplevel.wayland : null
        live: OverviewState.visible
        visible: hasContent
    }

    // Adaptive icon + title overlay: full pill for sizable tiles, just a
    // floating icon for tiny ones.
    readonly property bool _showLabel: width >= 80 && height >= 32

    Rectangle {
        id: labelPill
        visible: root._showLabel
        anchors {
            left: parent.left; right: parent.right; bottom: parent.bottom
            margins: 2
        }
        height: 20
        radius: 4
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.78)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 4

            Image {
                source: root.appClass !== ""
                    ? Quickshell.iconPath(root.appClass.toLowerCase(), 16) : ""
                sourceSize.width: 14
                sourceSize.height: 14
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
            }

            Text {
                text: root.title !== "" ? root.title : root.appClass
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.bold: root.active
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    // Fallback icon for tiles too small for the label pill.
    Image {
        visible: !root._showLabel && root.appClass !== ""
        source: root.appClass !== ""
            ? Quickshell.iconPath(root.appClass.toLowerCase(), 16) : ""
        anchors.centerIn: parent
        sourceSize.width: 16
        sourceSize.height: 16
        width: Math.min(16, parent.width - 4)
        height: Math.min(16, parent.height - 4)
        asynchronous: true
        fillMode: Image.PreserveAspectFit
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: true

        drag.target: root
        drag.threshold: 5

        onEntered: root.hovered = true
        onExited:  root.hovered = false

        // Clamp the tile to the widget bounds on every drag move.
        onPositionChanged: {
            if (!drag.active || !root.constrainTo || !root.parent) return;
            const tl = root.constrainTo.mapToItem(root.parent, 0, 0);
            const br = root.constrainTo.mapToItem(root.parent,
                root.constrainTo.width, root.constrainTo.height);
            const maxX = br.x - root.width;
            const maxY = br.y - root.height;
            if (root.x < tl.x)  root.x = tl.x;
            else if (root.x > maxX) root.x = maxX;
            if (root.y < tl.y)  root.y = tl.y;
            else if (root.y > maxY) root.y = maxY;
        }

        onReleased: {
            root.Drag.drop();
            // Drag broke the x/y bindings; re-establish them so the tile
            // snaps back to its computed home (or to its new cell once the
            // model updates after a successful drop).
            root.x = Qt.binding(() => root.tileX);
            root.y = Qt.binding(() => root.tileY);
        }

        onClicked: root.clicked()
    }
}
