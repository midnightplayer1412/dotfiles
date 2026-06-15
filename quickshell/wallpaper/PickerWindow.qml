import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../ui" as Ui
import ".."

PanelWindow {
    id: win
    required property var screen

    anchors { left: true; right: true; top: true; bottom: true }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    color: "transparent"

    // Symbolic (monochrome) Papirus icons, tinted by Ui.Icon to match the shell.
    readonly property string symActions: "/usr/share/icons/Papirus/16x16/symbolic/actions"

    // Wallpapers filtered by the search box (case-insensitive substring on
    // basename). Empty query → the full list.
    readonly property var filtered: {
        const q = search.text.trim().toLowerCase();
        const all = WallpaperService.wallpapers;
        if (!q) return all;
        return all.filter(w => w.basename.toLowerCase().indexOf(q) !== -1);
    }

    // Pin the currently key-focused thumbnail and close.
    function pinCurrent() {
        const idx = grid.currentIndex;
        if (idx >= 0 && idx < win.filtered.length) {
            WallpaperService.pinWallpaper(win.filtered[idx].path);
            WallpaperService.pickerVisible = false;
        }
    }

    HyprlandFocusGrab {
        active: true
        windows: [win]
        onCleared: WallpaperService.pickerVisible = false
    }

    MouseArea {
        anchors.fill: parent
        onClicked: WallpaperService.pickerVisible = false
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Theme.wallpaperPickerWidth
        height: Theme.wallpaperPickerHeight
        color: Theme.surface
        radius: Theme.wallpaperPickerRadius
        border.color: Theme.outline
        border.width: 1

        // Swallow clicks inside the panel (so they don't close it)
        MouseArea {
            anchors.fill: parent
            // Do nothing on click; the propagation chain stops here.
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.wallpaperPickerPadding
            spacing: 12

            // ── Header ──────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.wallpaperPickerRowHeight
                spacing: 12

                Text {
                    text: "WALLPAPER"
                    color: Theme.surfaceText
                    font.family: Theme.wallpaperPickerFontFamily
                    font.pixelSize: Theme.wallpaperPickerTitleSize
                    font.weight: Font.DemiBold
                    font.letterSpacing: 2
                }

                // Search field — grows to fill the gap between title and controls.
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.wallpaperPickerRowHeight
                    Layout.maximumWidth: 360
                    radius: 8
                    color: Theme.surfaceContainer
                    border.width: 1
                    border.color: search.activeFocus ? Theme.primary : Theme.outline
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 9
                        anchors.rightMargin: 6
                        spacing: 6

                        Ui.Icon {
                            source: "file://" + win.symActions + "/edit-find-symbolic.svg"
                            color: Theme.outline
                            size: 14
                        }

                        TextInput {
                            id: search
                            Layout.fillWidth: true
                            clip: true
                            color: Theme.surfaceText
                            font.family: Theme.wallpaperPickerFontFamily
                            font.pixelSize: Theme.wallpaperPickerBodySize
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            selectionColor: Theme.primary
                            focus: true

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                visible: search.text.length === 0
                                text: "Search…"
                                color: Theme.outline
                                font: search.font
                            }

                            // Reset key-focus to the top whenever the result set changes.
                            onTextChanged: grid.currentIndex = win.filtered.length > 0 ? 0 : -1

                            Keys.onDownPressed: {
                                grid.forceActiveFocus();
                                if (grid.currentIndex < 0 && win.filtered.length > 0)
                                    grid.currentIndex = 0;
                            }
                            Keys.onReturnPressed: win.pinCurrent()
                            Keys.onEnterPressed: win.pinCurrent()
                            Keys.onEscapePressed: {
                                if (search.text.length > 0) search.text = "";
                                else WallpaperService.pickerVisible = false;
                            }
                        }

                        // Clear button (only when there is a query)
                        Ui.Icon {
                            source: "file://" + win.symActions + "/edit-clear-symbolic.svg"
                            color: clearMouse.containsMouse ? Theme.surfaceText : Theme.outline
                            size: 14
                            visible: search.text.length > 0
                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { search.text = ""; search.forceActiveFocus(); }
                            }
                        }
                    }
                }

                // Shuffle-now button
                Rectangle {
                    Layout.preferredWidth: Theme.wallpaperPickerRowHeight
                    Layout.preferredHeight: Theme.wallpaperPickerRowHeight
                    radius: 8
                    color: shuffleMouse.containsMouse ? Theme.primaryContainer : Theme.surfaceContainer
                    border.width: 1
                    border.color: shuffleMouse.containsMouse ? Theme.primary : Theme.outline
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Ui.Icon {
                        anchors.centerIn: parent
                        source: "file://" + win.symActions + "/ymuse-random-symbolic.svg"
                        color: Theme.surfaceText
                        size: 16
                    }
                    MouseArea {
                        id: shuffleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WallpaperService.shuffleNow()
                    }
                }

                // Cycle order — random vs. sequential (persisted preference).
                Ui.Dropdown {
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: Theme.wallpaperPickerRowHeight
                    textRole: "label"
                    model: [
                        { label: "Random",     v: "random" },
                        { label: "Sequential", v: "sequential" }
                    ]
                    currentIndex: WallpaperService.cycleOrder === "sequential" ? 1 : 0
                    onActivated: (i) => WallpaperService.setCycleOrder(model[i].v)
                }

                Ui.Dropdown {
                    Layout.preferredWidth: 110
                    Layout.preferredHeight: Theme.wallpaperPickerRowHeight
                    textRole: "label"
                    model: [
                        { label: "1 min",  s: 60 },
                        { label: "5 min",  s: 300 },
                        { label: "15 min", s: 900 },
                        { label: "30 min", s: 1800 },
                        { label: "1 hour", s: 3600 }
                    ]
                    currentIndex: {
                        const s = WallpaperService.intervalSeconds;
                        for (let i = 0; i < model.length; i++) if (model[i].s === s) return i;
                        return 1;
                    }
                    onActivated: (i) => WallpaperService.setInterval(model[i].s)
                }

                RowLayout {
                    spacing: 8
                    Text {
                        text: "Cycle"
                        color: Theme.surfaceText
                        font.family: Theme.wallpaperPickerFontFamily
                        font.pixelSize: Theme.wallpaperPickerBodySize
                    }
                    Ui.Toggle {
                        checked: WallpaperService.cycleEnabled
                        onToggled: (v) => WallpaperService.setCycle(v)
                    }
                }
            }

            // ── Grid ────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Lazy-loaded: GridView only instantiates delegates inside the
                // viewport plus `cacheBuffer`. Scrolling reuses instances, so
                // memory stays flat regardless of how many wallpapers exist.
                GridView {
                    id: grid
                    anchors.fill: parent
                    clip: true
                    focus: false

                    model: win.filtered

                    readonly property int cols: Theme.wallpaperThumbColumns
                    readonly property int gap: Theme.wallpaperThumbGap

                    // Cells are flush in GridView, so we put the gap *inside*
                    // each cell via the delegate's right/bottom margin.
                    cellWidth: Math.floor(width / cols)
                    cellHeight: Math.floor((cellWidth - gap) * 10 / 16) + gap

                    cacheBuffer: cellHeight * 2
                    boundsBehavior: Flickable.StopAtBounds
                    highlightFollowsCurrentItem: true
                    keyNavigationEnabled: true

                    ScrollBar.vertical: Ui.ScrollBar { visible: grid.contentHeight > grid.height + 1 }

                    Keys.onReturnPressed: win.pinCurrent()
                    Keys.onEnterPressed: win.pinCurrent()
                    Keys.onEscapePressed: WallpaperService.pickerVisible = false

                    delegate: WallpaperThumb {
                        required property var modelData
                        required property int index
                        width: grid.cellWidth - grid.gap
                        height: grid.cellHeight - grid.gap
                        entry: modelData
                        selected: modelData.path === WallpaperService.currentPath
                        keyFocused: grid.activeFocus && index === grid.currentIndex
                        thumbRev: WallpaperService.thumbRev
                        onClicked: {
                            WallpaperService.pinWallpaper(modelData.path);
                            WallpaperService.pickerVisible = false;
                        }
                    }
                }   // GridView

                // Empty state — no wallpapers at all, or none match the search.
                Text {
                    anchors.centerIn: parent
                    visible: win.filtered.length === 0
                    text: WallpaperService.wallpapers.length === 0
                          ? "No wallpapers found in " + WallpaperService.wallpaperDir
                          : "No wallpapers match “" + search.text + "”"
                    color: Theme.outline
                    font.family: Theme.wallpaperPickerFontFamily
                    font.pixelSize: Theme.wallpaperPickerBodySize
                }
            }
        }
    }

    // On open: center the grid on the currently-applied wallpaper and seed
    // key-navigation there, so it's visible immediately even far down the list.
    Component.onCompleted: {
        const idx = win.filtered.findIndex(w => w.path === WallpaperService.currentPath);
        if (idx >= 0) {
            grid.currentIndex = idx;
            Qt.callLater(() => grid.positionViewAtIndex(idx, GridView.Center));
        }
    }
}
