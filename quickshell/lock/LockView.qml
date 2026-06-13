import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "."
import ".."

// The complete lockscreen visual. Rendered by the real lock surface
// (preview:false, context set) and by the settings preview (preview:true).
Item {
    id: view

    property bool preview: false
    property var context: null
    property bool showInput: true       // false on non-focused monitors

    // Resolve wallpaper: fixed file, or the live desktop wallpaper from state.
    FileView {
        id: wpState
        path: Quickshell.env("HOME") + "/.config/quickshell/wallpaper-state.json"
        watchChanges: true
        JsonAdapter { id: wp; property string currentPath: "" }
    }
    readonly property string wallpaper:
        LockConfig.wallpaperSource === "current-desktop" && wp.currentPath !== ""
            ? wp.currentPath
            : LockConfig.wallpaperPath

    // Shared clock tick.
    property date now: new Date()
    Timer {
        interval: 1000; running: true; repeat: true
        triggeredOnStart: true
        onTriggered: view.now = new Date()
    }

    // ── Background ────────────────────────────────────────────────
    Image {
        id: bg
        anchors.fill: parent
        source: view.wallpaper === "" ? "" : ("file://" + view.wallpaper.replace("file://", ""))
        fillMode: Image.PreserveAspectCrop
        cache: true
        asynchronous: true
        // Keep the GPU texture alive even when hidden, so MultiEffect can sample it.
        layer.enabled: LockConfig.blur > 0
        visible: LockConfig.blur <= 0
    }
    // Blur path (only when blur > 0) — MultiEffect (Qt6 built-in) over the image.
    MultiEffect {
        anchors.fill: parent
        source: bg
        blurEnabled: LockConfig.blur > 0
        blur: Math.min(1, LockConfig.blur / 12)
        blurMax: 64
        visible: LockConfig.blur > 0
    }
    // Dim overlay.
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: LockConfig.dim
    }

    // ── Clock (top-center area) ───────────────────────────────────
    Clock {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.verticalCenter
        anchors.bottomMargin: 40
        now: view.now
        clockFormat: LockConfig.clockFormat
        showSeconds: LockConfig.showSeconds
        dateFormat: LockConfig.dateFormat
        showDate: LockConfig.showDate
        textColor: "white"
    }

    // ── Center stack: media + input ───────────────────────────────
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.verticalCenter
        anchors.topMargin: 24
        spacing: 20

        MediaCard {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: LockConfig.showMedia
        }

        AuthField {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: view.showInput
            context: view.context
            hideInput: LockConfig.hideInput
        }
    }

    // ── Identity (bottom-left) ────────────────────────────────────
    Text {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 24
        visible: LockConfig.showIdentity
        text: Quickshell.env("USER") + "@" + Quickshell.env("HOSTNAME")
        color: "#ddffffff"
        font.family: Theme.fontFamily
        font.pixelSize: 14
    }

    // ── Battery (bottom-right) ────────────────────────────────────
    BatteryPill {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        visible: LockConfig.showBattery
    }
}
