import QtQuick
import QtQuick.Layouts
import ".."
import "../ui" as Ui

// Previous / current / next lines stacked and centered. Center line bright in the
// accent; neighbours dimmed. Synced lyrics only.
Item {
    id: v
    readonly property int idx: LyricsService.currentIndex

    // Transparent background: outline glyphs for legibility over any window.
    readonly property int txStyle: LyricsConfig.background === "transparent" ? Text.Outline : Text.Normal
    readonly property color txStyleColor: Qt.rgba(0, 0, 0, 0.6)

    function lineAt(k) {
        const s = LyricsService;
        const j = v.idx + k;
        return (j >= 0 && j < s.lines.length) ? s.lines[j].text : "";
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width
        spacing: 4

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: v.lineAt(-1)
            color: Theme.surfaceText
            opacity: Ui.WidgetStyle.subOpacity * 0.7
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(14 * LyricsConfig.fontScale)
            style: v.txStyle
            styleColor: v.txStyleColor
        }
        Text {
            visible: !LyricsService.instrumental
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: v.lineAt(0)
            color: Ui.WidgetStyle.accent
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(30 * LyricsConfig.fontScale)
            font.weight: Font.Bold
            style: v.txStyle
            styleColor: v.txStyleColor
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
        InstrumentalDots {
            visible: LyricsService.instrumental
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: Math.round(30 * LyricsConfig.fontScale)
            dotSize: Math.round(11 * LyricsConfig.fontScale)
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: v.lineAt(1)
            color: Theme.surfaceText
            opacity: Ui.WidgetStyle.subOpacity * 0.7
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(14 * LyricsConfig.fontScale)
            style: v.txStyle
            styleColor: v.txStyleColor
        }
    }
}
