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
    // Set by the alt-tab cycle in OverviewWidget — the current keyboard target.
    property bool highlighted: false
    readonly property bool dragging: dragArea.drag.active

    // Optional macOS-style drag proxy. 0 = disabled (drags at full size, drop
    // hotspot = center — used by Grid/Exposé/Side). >0 = while dragging, shrink
    // around the GRAB POINT so the long edge ≈ this many px, and use the grab
    // point as the drop hotspot — so the drop lands under the cursor regardless
    // of window size (used by Mission Control, where windows can be huge).
    property real dragProxyLongEdge: 0
    // Where inside the tile the drag began (item coords); the shrink origin and
    // drop hotspot when dragProxyLongEdge > 0. Defaults to center.
    property real grabX: width / 2
    property real grabY: height / 2
    readonly property real proxyScale: (dragProxyLongEdge > 0 && width > 0 && height > 0)
        ? Math.min(1, dragProxyLongEdge / Math.max(width, height)) : 1

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
    border.width: highlighted ? 3 : active ? 2 : 1
    border.color: highlighted || active ? Theme.primary : Theme.outline
    clip: true

    opacity: dragging ? 0.9 : 1.0
    // Lift the highlighted tile above its neighbours so its border/scale isn't
    // clipped by sibling tiles; dragging still wins.
    z: dragging ? 1000 : highlighted ? 500 : 0
    scale: highlighted ? 1.04 : 1.0

    Behavior on color        { ColorAnimation  { duration: 100 } }
    Behavior on border.color { ColorAnimation  { duration: 120 } }
    Behavior on scale        { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

    // Drag-proxy shrink, around the grab point (composes with the highlight
    // `scale` above). Identity (1.0) unless a proxy-enabled tile is dragging.
    transform: Scale {
        origin.x: root.grabX
        origin.y: root.grabY
        xScale: (root.dragProxyLongEdge > 0 && root.dragging) ? root.proxyScale : 1
        yScale: (root.dragProxyLongEdge > 0 && root.dragging) ? root.proxyScale : 1
        Behavior on xScale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
        Behavior on yScale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
    }

    Drag.active: dragArea.drag.active
    // With the proxy on, the drop point is the grab point (kept under the cursor
    // since drag.target moves the tile by the cursor delta, and the shrink origin
    // is the same point) — so the drop lands where you point. Else: center.
    Drag.hotSpot.x: dragProxyLongEdge > 0 ? grabX : width / 2
    Drag.hotSpot.y: dragProxyLongEdge > 0 ? grabY : height / 2
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

        // Record where inside the tile the drag started, for the drag-proxy
        // shrink origin + drop hotspot (see dragProxyLongEdge).
        onPressed: (mouse) => { root.grabX = mouse.x; root.grabY = mouse.y }

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
