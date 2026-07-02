import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."
import "../ui" as Ui

// Dock layout: a horizontal strip of window cards near the bottom edge, in
// most-recently-used order (OverviewState.cycleOrder). Like a macOS/GNOME app
// switcher. Reuses OverviewState for MRU order, keyboard selection, focus, and
// geometric HJKL nav (h/l walk the row); cards are laid out by a Flow/Row rather
// than absolutely, so they use a self-contained delegate instead of the
// absolutely-positioned OverviewWindow tile.
Item {
    id: dock

    readonly property var windows: OverviewState.cycleOrder
    readonly property int cardW: 220
    readonly property int cardH: 140
    readonly property int gap:   12
    readonly property int pad:   12

    Ui.Surface {
        id: strip
        level: 0
        radius: 20

        readonly property int contentW: dock.windows.length > 0
            ? dock.windows.length * dock.cardW + (dock.windows.length - 1) * dock.gap
            : dock.cardW
        // Never wider than the screen (minus a margin); the Flickable scrolls the rest.
        width:  Math.min(contentW + dock.pad * 2, dock.width - 60)
        height: dock.cardH + dock.pad * 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 44

        // Slide-up + fade entry.
        opacity: 0
        transform: Translate { id: slide; y: 24 }
        Component.onCompleted: entryAnim.start()
        ParallelAnimation {
            id: entryAnim
            NumberAnimation { target: strip; property: "opacity"; from: 0;  to: 1; duration: 180; easing.type: Easing.OutCubic }
            NumberAnimation { target: slide; property: "y";       from: 24; to: 0; duration: 180; easing.type: Easing.OutCubic }
        }

        // Swallow clicks on the dock background so they don't close the overview.
        MouseArea { anchors.fill: parent; onClicked: {} }

        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: dock.pad
            contentWidth: row.width
            contentHeight: height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.HorizontalFlick

            Row {
                id: row
                height: parent.height
                spacing: dock.gap

                Repeater {
                    model: dock.windows

                    // ── Window card ──
                    Rectangle {
                        id: card
                        required property var modelData

                        readonly property var toplevel: modelData
                        readonly property string appClass: toplevel?.lastIpcObject?.class ?? ""
                        readonly property string title:    toplevel?.lastIpcObject?.title ?? ""
                        readonly property string address:  toplevel?.address ?? ""
                        readonly property bool   active:    toplevel?.activated ?? false
                        readonly property bool highlighted: OverviewState.armed
                            ? OverviewState.highlightedWindow === modelData
                            : OverviewState.keyboardSelectedWindow === modelData

                        width:  dock.cardW
                        height: dock.cardH
                        radius: 10
                        color: highlighted ? Theme.primaryContainer
                             : hover.hovered ? Theme.surfaceContainer
                             :                 Qt.darker(Theme.surface, 1.1)
                        border.width: highlighted ? 3 : active ? 2 : 1
                        border.color: highlighted || active ? Theme.primary : Theme.outline
                        clip: true
                        scale: highlighted ? 1.03 : 1.0

                        Behavior on color        { ColorAnimation  { duration: 100 } }
                        Behavior on border.color { ColorAnimation  { duration: 120 } }
                        Behavior on scale        { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

                        // Report center for geometric HJKL nav, in dock-root coords.
                        function reportGeometry() {
                            if (!OverviewState.visible || !card.address) return;
                            const c = card.mapToItem(dock, card.width / 2, card.height / 2);
                            OverviewState.registerTile(card.address, c.x, c.y);
                        }
                        Component.onCompleted: Qt.callLater(reportGeometry)
                        onXChanged: reportGeometry()

                        ScreencopyView {
                            id: preview
                            anchors.fill: parent
                            anchors.margins: 1
                            captureSource: Theme.overviewLivePreviews
                                        && OverviewState.visible
                                        && card.toplevel?.wayland
                                ? card.toplevel.wayland : null
                            live: OverviewState.visible
                            visible: hasContent
                        }

                        // Icon + title pill.
                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 3 }
                            height: 22
                            radius: 6
                            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.82)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                spacing: 6
                                Image {
                                    source: card.appClass !== ""
                                        ? Quickshell.iconPath(card.appClass.toLowerCase(), 16) : ""
                                    sourceSize.width: 16; sourceSize.height: 16
                                    Layout.preferredWidth: 16; Layout.preferredHeight: 16
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectFit
                                    visible: status === Image.Ready
                                }
                                Text {
                                    text: card.title !== "" ? card.title : card.appClass
                                    color: Theme.surfaceText
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.bold: card.active
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        HoverHandler { id: hover }
                        TapHandler {
                            onTapped: {
                                if (card.address) OverviewState.focusWindow(card.address);
                                OverviewState.close();
                            }
                        }
                    }
                }
            }
        }
    }

    // Empty-state hint when there are no windows.
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 44 + dock.cardH / 2
        visible: dock.windows.length === 0
        text: "No open windows"
        color: Theme.surfaceText
        opacity: 0.6
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeMedium
    }
}
