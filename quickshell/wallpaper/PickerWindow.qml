import QtQuick
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

    HyprlandFocusGrab {
        active: true
        windows: [win]
        onCleared: WallpaperService.pickerVisible = false
    }

    MouseArea {
        anchors.fill: parent
        onClicked: WallpaperService.pickerVisible = false
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: WallpaperService.pickerVisible = false
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

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.wallpaperPickerRowHeight
                spacing: 14

                Text {
                    text: "WALLPAPER"
                    color: Theme.surfaceText
                    font.family: Theme.wallpaperPickerFontFamily
                    font.pixelSize: Theme.wallpaperPickerTitleSize
                    font.weight: Font.DemiBold
                    font.letterSpacing: 2
                }
                Item { Layout.fillWidth: true }

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
                    Rectangle {
                        id: toggle
                        width: 38; height: 22; radius: 11
                        color: WallpaperService.cycleEnabled ? Theme.primary : Theme.outline
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Rectangle {
                            width: 18; height: 18; radius: 9
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                            x: WallpaperService.cycleEnabled ? parent.width - width - 2 : 2
                            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WallpaperService.setCycle(!WallpaperService.cycleEnabled)
                        }
                    }
                }
            }

            // Lazy-loaded grid — GridView only instantiates delegates that
            // are inside the viewport plus `cacheBuffer` worth of pixels
            // outside it. Scrolling reuses delegate instances, so memory
            // stays flat regardless of how many wallpapers exist.
            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                model: WallpaperService.wallpapers

                readonly property int cols: Theme.wallpaperThumbColumns
                readonly property int gap: Theme.wallpaperThumbGap

                // Cells are flush in GridView, so we put the gap *inside*
                // each cell via the delegate's rightMargin/bottomMargin.
                cellWidth: Math.floor(width / cols)
                cellHeight: Math.floor((cellWidth - gap) * 10 / 16) + gap

                // Pre-load one row above/below the viewport so scrolling is
                // smooth without holding everything in memory.
                cacheBuffer: cellHeight * 2

                boundsBehavior: Flickable.StopAtBounds

                delegate: WallpaperThumb {
                    required property var modelData
                    width: grid.cellWidth - grid.gap
                    height: grid.cellHeight - grid.gap
                    entry: modelData
                    selected: modelData.path === WallpaperService.currentPath
                    onClicked: {
                        console.log("PICKER: click pin", modelData.path);
                        WallpaperService.pinWallpaper(modelData.path);
                        WallpaperService.pickerVisible = false;
                    }
                }
            }
        }
    }
}
