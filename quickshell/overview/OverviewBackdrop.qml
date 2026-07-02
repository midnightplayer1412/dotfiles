import QtQuick
import "../wallpaper" as Wallpaper

// Full-screen wallpaper backdrop for overview layouts. Paints the current
// wallpaper (covering the real desktop windows, so they aren't shown twice —
// once for real behind the transparent overlay and once as a live tile) plus a
// scrim for tile contrast, like macOS Mission Control's dedicated view.
//
// Drop it in as the FIRST child of a full-screen layout so it sits behind the
// content. It has no MouseArea, so clicks on it fall through to Overview's outer
// close-catcher.
Item {
    id: root
    anchors.fill: parent

    // Darkening over the wallpaper (0 = wallpaper as-is, 1 = black).
    property real scrim: 0.35

    // Gentle fade-in to match the layouts' entry animations.
    opacity: 0
    Component.onCompleted: fade.start()
    NumberAnimation { id: fade; target: root; property: "opacity"; from: 0; to: 1; duration: 170; easing.type: Easing.OutCubic }

    Image {
        anchors.fill: parent
        source: Wallpaper.WallpaperService.currentPath !== ""
            ? "file://" + Wallpaper.WallpaperService.currentPath : ""
        fillMode: Image.PreserveAspectCrop
        cache: true
        asynchronous: true
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, root.scrim)
    }
}
