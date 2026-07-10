import QtQuick
import ".."
import "../ui" as Ui

// Single active line, large and centered, with a soft opacity pulse on change.
// Only used for synced lyrics (plain-only routes to the scroll view).
Item {
    id: v
    readonly property string line: {
        const s = LyricsService;
        const i = s.currentIndex;
        return (i >= 0 && i < s.lines.length) ? s.lines[i].text : "";
    }

    // Transparent background: outline the glyphs so lyrics stay readable over
    // any window behind the strip. No-op on the solid/glass surface.
    readonly property int txStyle: LyricsConfig.background === "transparent" ? Text.Outline : Text.Normal
    readonly property color txStyleColor: Qt.rgba(0, 0, 0, 0.6)

    onLineChanged: pulse.restart()

    Text {
        id: label
        visible: !LyricsService.instrumental
        anchors.centerIn: parent
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: v.line
        color: Theme.surfaceText
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(30 * LyricsConfig.fontScale)
        font.weight: Font.Bold
        style: v.txStyle
        styleColor: v.txStyleColor
    }

    InstrumentalDots {
        anchors.centerIn: parent
        visible: LyricsService.instrumental
        dotSize: Math.round(11 * LyricsConfig.fontScale)
    }

    SequentialAnimation {
        id: pulse
        NumberAnimation { target: label; property: "opacity"; to: 0.15; duration: 110 }
        NumberAnimation { target: label; property: "opacity"; to: 1.0;  duration: 200 }
    }
}
