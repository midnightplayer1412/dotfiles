import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."
import "../ui" as Ui

// Edge-docked synced-lyrics strip. Full width on the configured edge (top or
// bottom), dodges the bar via BarConfig.clearance, background follows the shared
// Solid/Glass surface tokens, and only the two corners facing into the screen
// are rounded. Floats over the desktop (ExclusionMode.Ignore) — it never shrinks
// the tiling workspace.
//
// shell.qml instantiates one per screen (Variants); each self-gates to the
// primary screen for v1, matching DesktopLayer/mascot.
PanelWindow {
    id: root

    // Which monitor to show on: the configured screen if it's connected, else the
    // primary. Gate by name (object identity on screens is unreliable), like Mascot.
    readonly property string targetName: {
        const want = LyricsConfig.screenName;
        if (want) for (const s of Quickshell.screens) if (s.name === want) return s.name;
        return Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "";
    }
    readonly property bool onTarget: root.screen && root.screen.name === targetName
    readonly property bool atTop: LyricsConfig.position === "top"

    // Transparent mode: no fill, no border, no blur — just the lyric text.
    readonly property bool transparentBg: LyricsConfig.background === "transparent"

    // Plain-only lyrics always render as the scroll view, regardless of mode.
    readonly property string effMode:
        !LyricsService.synced ? "scroll" : LyricsConfig.layoutMode

    // Show the empty-state label (a track is playing but has no lyrics) only when
    // the user opted in. Otherwise the strip just hides when nothing's found.
    readonly property bool showEmpty:
        LyricsConfig.showWhenEmpty && LyricsService.active && !LyricsService.available

    // Whether the strip wants to be on screen. Auto-hide-when-paused drops it
    // while playback is paused (but a track is still loaded).
    readonly property bool shouldShow:
        root.onTarget && LyricsConfig.enabled && !LyricsState.userHidden
        && (LyricsService.available || root.showEmpty)
        && (!LyricsConfig.hideWhenPaused || LyricsService.playing)

    // Off-screen offset for the slide animation (below a bottom strip / above a
    // top one).
    readonly property real hiddenY: root.atTop ? -root.implicitHeight : root.implicitHeight

    // Keep the surface mapped whenever a track is loaded (and through the slide-out
    // after it ends). Mapping a layer surface is async, so gating `visible` on the
    // shown-state would eat the slide's first frames; a stable surface lets the
    // content animation actually play. The content itself hides via slide+fade.
    visible: root.onTarget && LyricsConfig.enabled
        && (LyricsService.active || slideAnim.running)

    // Transparent mode opts out of the glass blur namespace entirely.
    WlrLayershell.namespace: root.transparentBg ? "quickshell" : Ui.Surfaces.blurNamespace
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    // Click-through: an empty input mask means no part of the strip grabs pointer
    // events — every click/scroll passes to the window behind it.
    mask: Region {}

    // Full-width strip on the docked edge.
    anchors { left: true; right: true; top: root.atTop; bottom: !root.atTop }

    // Flush to the docked edge (base 0), inset from the sides by sideGap; on any
    // edge the bar occupies, clearance widens the margin to clear it.
    margins {
        left:   BarConfig.clearance("left",  LyricsConfig.sideGap)
        right:  BarConfig.clearance("right", LyricsConfig.sideGap)
        top:    root.atTop  ? BarConfig.clearance("top",  0) : 0
        bottom: !root.atTop ? BarConfig.clearance("bottom", 0) : 0
    }

    readonly property int baseHeight: !LyricsService.available ? 72
                  : root.effMode === "scroll" ? 180
                  : root.effMode === "triple" ? 120 : 72
    implicitHeight: Math.round(baseHeight * LyricsConfig.heightScale)

    Rectangle {
        id: bg
        anchors.fill: parent
        color: root.transparentBg ? "transparent" : Ui.Surfaces.baseColor
        border.width: root.transparentBg ? 0 : Ui.Surfaces.borderWidth
        border.color: root.transparentBg ? "transparent" : Ui.Surfaces.borderColor

        // Slide in from / out to the docked edge, with a fade. Disabled → snaps.
        transform: Translate { y: bg.slideOff }
        property real slideOff: root.shouldShow ? 0 : root.hiddenY
        opacity: root.shouldShow ? 1 : 0
        Behavior on slideOff {
            enabled: LyricsConfig.animate
            NumberAnimation { id: slideAnim; duration: 300; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            enabled: LyricsConfig.animate
            NumberAnimation { duration: 220 }
        }

        // Round only the corners that face into the screen.
        readonly property int r: 18
        topLeftRadius:     root.atTop ? 0 : r
        topRightRadius:    root.atTop ? 0 : r
        bottomLeftRadius:  root.atTop ? r : 0
        bottomRightRadius: root.atTop ? r : 0

        Loader {
            anchors.fill: parent
            anchors.leftMargin: 28
            anchors.rightMargin: 28
            sourceComponent: !LyricsService.available ? cEmpty
                           : root.effMode === "scroll" ? cScroll
                           : root.effMode === "triple" ? cTriple : cSingle
        }
        Component { id: cSingle; LyricsSingleLine {} }
        Component { id: cTriple; LyricsTripleLine {} }
        Component { id: cScroll; LyricsScrollColumn {} }

        // Empty state — shown only when showWhenEmpty is on and a track has no
        // lyrics. Reads "Searching…" during the fetch, then "No lyrics found".
        Component {
            id: cEmpty
            Item {
                Row {
                    anchors.centerIn: parent
                    spacing: 10
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\u{F0387}"   // nf-md-music
                        font.family: Theme.glyphFont
                        font.pixelSize: 20
                        color: Theme.surfaceText
                        opacity: 0.5
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: LyricsService.loading ? "Searching lyrics…" : "No lyrics found"
                        color: Theme.surfaceText
                        opacity: 0.6
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(15 * LyricsConfig.fontScale)
                        style: root.transparentBg ? Text.Outline : Text.Normal
                        styleColor: Qt.rgba(0, 0, 0, 0.6)
                    }
                }
            }
        }

        // Unsynced hint — a small pill shown when lyrics exist but LRCLIB only had
        // a plain (untimed) version, so the strip falls back to the scroll view.
        // Makes clear the missing karaoke highlight is a data limit, not a bug.
        // Sits on the inner edge (opposite the docked edge) so it never hides
        // behind the screen bezel.
        Rectangle {
            id: unsyncedBadge
            visible: LyricsService.available && !LyricsService.synced
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.top: root.atTop ? undefined : parent.top
            anchors.bottom: root.atTop ? parent.bottom : undefined
            anchors.topMargin: 8
            anchors.bottomMargin: 8
            implicitWidth: badgeLabel.implicitWidth + 16
            implicitHeight: 20
            radius: 10
            color: root.transparentBg ? "transparent"
                 : Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.12)
            border.width: root.transparentBg ? 0 : 1
            border.color: root.transparentBg ? "transparent"
                        : Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.18)

            Text {
                id: badgeLabel
                anchors.centerIn: parent
                text: "unsynced"
                color: Theme.surfaceText
                opacity: 0.6
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 0.5
                style: root.transparentBg ? Text.Outline : Text.Normal
                styleColor: Qt.rgba(0, 0, 0, 0.6)
            }
        }
    }
}
