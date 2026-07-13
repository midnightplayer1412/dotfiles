import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import ".."
import "../ui" as Ui

// Full-screen "app grid" results view — macOS Launchpad style. Apps fill a fixed
// rows×columns page; overflow spills onto further pages you swipe/scroll/arrow between,
// with page dots below. Built over the launcher's flat result array (filteredModel's
// values). The launcher swaps back to the row list for command/shell/calc/web queries.
Item {
    id: grid

    // Tuning, driven by LauncherConfig via Launcher.qml.
    required property int columns
    property int rows: 5
    property int iconSize: Theme.launcherGridIconMedium
    property bool showLabels: true
    property var entries: []            // flat array of result rows (filteredModel.values)

    // Selection index into `entries`; drives keyboard nav + which tile highlights.
    property int currentIndex: 0

    // Emitted on click / Enter with the model index to launch.
    signal launch(int index)

    readonly property int pageSize: Math.max(1, columns * rows)
    readonly property int pageCount: Math.max(1, Math.ceil(entries.length / pageSize))

    readonly property real cellWidth: columns > 0 ? swipe.width / columns : swipe.width
    // Per-cell height = icon (+ label) plus generous vertical padding so tiles aren't
    // cramped; content centers in the cell, so the extra height reads as top/bottom
    // breathing room. Capped so `rows` always fit the page.
    readonly property real cellHeight: {
        const ideal = iconSize + (showLabels ? 68 : 44);
        const avail = rows > 0 ? swipe.height / rows : ideal;
        return Math.min(ideal, avail);
    }

    // New query / result set → back to the first tile on the first page.
    onEntriesChanged: {
        if (currentIndex >= entries.length || currentIndex < 0) currentIndex = 0;
        swipe.currentIndex = 0;
    }

    // 2-D keyboard move over the flat index space (dy in rows, dx in columns). Moving
    // past a page edge naturally lands on the next/prev page and follows the swipe.
    function move(dy, dx) {
        if (!entries.length) return;
        let i = currentIndex + dx + dy * columns;
        if (i < 0) i = 0;
        if (i >= entries.length) i = entries.length - 1;
        currentIndex = i;
        swipe.currentIndex = Math.floor(currentIndex / pageSize);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        SwipeView {
            id: swipe
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            currentIndex: 0

            // User-driven swipe/scroll/dot to a new page: move the selection onto it.
            onCurrentIndexChanged: {
                if (Math.floor(grid.currentIndex / grid.pageSize) !== currentIndex)
                    grid.currentIndex = currentIndex * grid.pageSize;
            }

            Repeater {
                model: grid.pageCount
                delegate: Item {
                    id: page
                    required property int index
                    readonly property int base: index * grid.pageSize

                    Grid {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        columns: grid.columns
                        rowSpacing: 16
                        columnSpacing: 8

                        Repeater {
                            model: {
                                const start = page.base;
                                const end = Math.min(start + grid.pageSize, grid.entries.length);
                                const out = [];
                                for (let k = start; k < end; k++) out.push({ entry: grid.entries[k], gi: k });
                                return out;
                            }
                            delegate: Item {
                                id: tile
                                required property var modelData
                                readonly property bool sel: modelData.gi === grid.currentIndex
                                width: grid.cellWidth
                                height: grid.cellHeight

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width - 8
                                    height: parent.height - 6
                                    radius: 14
                                    color: Theme.primaryContainer
                                    opacity: tile.sel ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 100 } }
                                }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    width: grid.cellWidth - 8
                                    spacing: 4

                                    Image {
                                        Layout.alignment: Qt.AlignHCenter
                                        property string iconName: tile.modelData.entry.icon ?? ""
                                        source: iconName.startsWith("/") ? iconName : Quickshell.iconPath(iconName, grid.iconSize)
                                        sourceSize.width: grid.iconSize
                                        sourceSize.height: grid.iconSize
                                        Layout.preferredWidth: grid.iconSize
                                        Layout.preferredHeight: grid.iconSize
                                        asynchronous: true
                                    }
                                    Text {
                                        visible: grid.showLabels
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.maximumWidth: grid.cellWidth - 12
                                        text: tile.modelData.entry.name ?? ""
                                        color: Theme.surfaceText
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: grid.currentIndex = tile.modelData.gi
                                    onClicked: grid.launch(tile.modelData.gi)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Page dots — click to jump, plus a live indicator of the current page.
        PageIndicator {
            id: pageInd
            Layout.alignment: Qt.AlignHCenter
            visible: grid.pageCount > 1
            count: grid.pageCount
            currentIndex: swipe.currentIndex
            interactive: false
            spacing: 8

            delegate: Rectangle {
                required property int index
                implicitWidth: 8
                implicitHeight: 8
                radius: 4
                color: index === pageInd.currentIndex ? Theme.primary : Theme.outline
                opacity: index === pageInd.currentIndex ? 1 : 0.4
                Behavior on opacity { NumberAnimation { duration: 120 } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: swipe.currentIndex = index
                }
            }
        }
    }

    // Mouse wheel / trackpad flips pages (there is no vertical scroll in this layout).
    WheelHandler {
        acceptedModifiers: Qt.NoModifier
        onWheel: (ev) => {
            const dir = (ev.angleDelta.y < 0 || ev.angleDelta.x < 0) ? 1 : -1;
            swipe.currentIndex = Math.max(0, Math.min(grid.pageCount - 1, swipe.currentIndex + dir));
        }
    }
}
