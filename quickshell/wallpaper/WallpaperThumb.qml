import QtQuick
import ".."

Item {
    id: cell
    required property var entry          // { path, basename, isGif, thumb }
    required property bool selected
    property bool hovered: false
    property bool keyFocused: false      // keyboard-navigation focus
    readonly property bool active: cell.hovered || cell.keyFocused

    // Bumped by WallpaperService when thumbnail generation finishes; resets the
    // fallback so a cell that showed the original (thumb not ready yet) retries.
    property int thumbRev: 0
    property bool _thumbFailed: false
    onThumbRevChanged: cell._thumbFailed = false

    signal clicked()

    // Lift slightly on hover/focus so the target reads as interactive.
    // transformOrigin is Center, so the thumb grows in place.
    scale: cell.active ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    z: cell.active ? 10 : 0   // grow above neighbours, not under them

    // Placeholder background — visible while the image is still loading or
    // failed. Subtly distinct from panel surface so empty cells read as
    // "loading" rather than missing.
    Rectangle {
        anchors.fill: parent
        radius: Theme.wallpaperThumbRadius
        color: Theme.surfaceContainer
        z: 0
    }

    // Load the small cached thumbnail (see gen-wallpaper-thumbs.sh), falling
    // back to the original only while the thumb doesn't exist yet. Thumbnails
    // are tiny JPGs, so even after the pixmap cache evicts them, re-decoding on
    // scroll-back is near-instant instead of re-reading the multi-MB original
    // (some GIFs are >300 MB). The thumb is already a static first frame; the
    // GIF badge marks animated files, which still animate on the desktop.
    Image {
        anchors.fill: parent
        source: (!cell._thumbFailed && cell.entry.thumb)
                ? "file://" + cell.entry.thumb
                : "file://" + cell.entry.path
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        sourceSize.width: 400
        sourceSize.height: 400
        z: 1
        // Thumb not generated yet → fall back to the original so the cell
        // still shows an image; thumbRev later flips _thumbFailed back.
        onStatusChanged: {
            if (status === Image.Error && !cell._thumbFailed && cell.entry.thumb)
                cell._thumbFailed = true;
        }
        // Fade in once Ready. With lazy GridView, only cells in or near the
        // viewport actually load, so we fade each in as it arrives.
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    // Selection ring (drawn above the image, below the GIF badge).
    // Selected → accent ring; hovered (but not selected) → soft white ring
    // that reads against any image.
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: cell.selected ? Theme.primary
                     : cell.active ? Qt.rgba(1, 1, 1, 0.7)
                     : "transparent"
        border.width: Theme.wallpaperThumbBorder
        radius: Theme.wallpaperThumbRadius
        z: 2
        Behavior on border.color { ColorAnimation { duration: 120 } }
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
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: cell.hovered = true
        onExited: cell.hovered = false
        onClicked: cell.clicked()
    }
}
