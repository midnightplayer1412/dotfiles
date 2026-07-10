import QtQuick
import ".."
import "../ui" as Ui

// Scrolling column of all lines. For synced lyrics the active line is
// highlighted and the view auto-scrolls to keep it centered; for plain-only
// lyrics it's a plain scrollable block (no highlight, user flicks). Uses a
// Repeater rather than a ListView per the singleton-var-model gotcha.
Item {
    id: v

    readonly property bool synced: LyricsService.synced
    readonly property int active: LyricsService.currentIndex
    readonly property var rows: synced
        ? LyricsService.lines.map(l => l.text)
        : (LyricsService.plainText ? LyricsService.plainText.split("\n") : [])

    onActiveChanged: if (v.synced && v.active >= 0) v.scrollTo(v.active)

    function scrollTo(i) {
        const it = rep.itemAt(i);
        if (!it) return;
        const target = it.y + it.height / 2 - flick.height / 2;
        const maxY = Math.max(0, col.height - flick.height);
        scrollAnim.to = Math.max(0, Math.min(target, maxY));
        scrollAnim.restart();
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        contentWidth: width
        contentHeight: col.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !v.synced   // synced auto-scrolls; plain is user-driven

        Column {
            id: col
            width: flick.width
            spacing: 6

            Repeater {
                id: rep
                model: v.rows
                delegate: Text {
                    required property int index
                    required property var modelData
                    readonly property bool current: v.synced && index === v.active
                    width: col.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: modelData
                    color: current ? Ui.WidgetStyle.accent : Theme.surfaceText
                    opacity: current ? 1.0 : (v.synced ? Ui.WidgetStyle.subOpacity * 0.8 : 0.9)
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round((current ? 24 : 15) * LyricsConfig.fontScale)
                    font.weight: current ? Font.Bold : Font.Normal
                    style: LyricsConfig.background === "transparent" ? Text.Outline : Text.Normal
                    styleColor: Qt.rgba(0, 0, 0, 0.6)
                    Behavior on color   { ColorAnimation  { duration: 150 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }

        NumberAnimation {
            id: scrollAnim
            target: flick
            property: "contentY"
            duration: 300
            easing.type: Easing.InOutQuad
        }
    }
}
