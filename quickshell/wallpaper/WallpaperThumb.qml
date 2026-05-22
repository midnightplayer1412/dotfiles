import QtQuick
import ".."

Item {
    id: cell
    required property var entry          // { path, basename, isGif }
    required property bool selected

    signal clicked()

    // Placeholder background — visible while the image is still loading or
    // failed. Subtly distinct from panel surface so empty cells read as
    // "loading" rather than missing.
    Rectangle {
        anchors.fill: parent
        radius: Theme.wallpaperThumbRadius
        color: Theme.surfaceContainer
        z: 0
    }

    // Single static Image for both regular files and GIFs. QImage decodes
    // the first frame of an animated GIF and stops, which is what we want
    // for a thumbnail — animating large GIFs (some are >300MB here) in
    // every cell would saturate the main thread and starve click events.
    // The GIF badge below identifies which thumbs are animated; the
    // actual wallpaper still animates on the desktop via awww.
    Image {
        anchors.fill: parent
        source: "file://" + cell.entry.path
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        sourceSize.width: 320
        sourceSize.height: 200
        z: 1
        // Fade in once Ready (or Error). With lazy GridView, only cells in
        // or near the viewport actually load, so we just fade each one in
        // as it arrives instead of gating on the whole grid.
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    // Selection ring (drawn above the image, below the GIF badge)
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: cell.selected ? Theme.primary : "transparent"
        border.width: Theme.wallpaperThumbBorder
        radius: Theme.wallpaperThumbRadius
        z: 2
    }

    // GIF badge
    Rectangle {
        visible: cell.entry.isGif
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 3
        color: "#b0000000"
        radius: 3
        z: 3
        width: gifLabel.implicitWidth + 6
        height: gifLabel.implicitHeight + 2
        Text {
            id: gifLabel
            text: "GIF"
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: 9
            font.bold: true
        }
    }

    layer.enabled: true
    layer.smooth: true

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: cell.clicked()
    }
}
