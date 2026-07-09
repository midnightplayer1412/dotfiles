import QtQuick
import QtQuick.Layouts
import ".."
import "../ui" as Ui

// Presentational only: renders time/date, declares relevance. Format is driven
// by per-widget settings (WidgetsConfig.setting("clock", …)); look is driven by
// the active widget style (Ui.WidgetStyle).
Item {
    id: w
    readonly property bool relevant: true

    readonly property bool fmt24: WidgetsConfig.setting("clock", "format24")
    readonly property bool showSeconds: WidgetsConfig.setting("clock", "showSeconds")
    readonly property bool showDate: WidgetsConfig.setting("clock", "showDate")
    readonly property string timeFmt:
        (fmt24 ? "hh:mm" : "h:mm") + (showSeconds ? ":ss" : "") + (fmt24 ? "" : " AP")

    readonly property string preset: Ui.WidgetStyle.preset
    readonly property int timeSize: preset === "dense" ? 30 : preset === "minimal" ? 34 : 40

    // Playful renders as an edge-to-edge gradient tile; WidgetFrame paints the
    // background (at frame scale) when a widget exposes these.
    readonly property bool bgGradient: preset === "playful"
    readonly property color bgA: Ui.WidgetStyle.gradA
    readonly property color bgB: Ui.WidgetStyle.gradB

    property var now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: w.now = new Date() }

    // Approximate week-of-year (dense preset only).
    function weekNo(d) {
        const start = new Date(d.getFullYear(), 0, 1);
        const days = Math.floor((d - start) / 86400000);
        return Math.ceil((days + start.getDay() + 1) / 7);
    }

    // ── Compact (non-dense): centered time over date ─────────────────
    Column {
        anchors.centerIn: parent
        visible: w.preset !== "dense"
        spacing: 2
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(w.now, w.timeFmt)
            color: w.preset === "playful" ? Theme.primaryText : Ui.WidgetStyle.titleColor
            font.family: Theme.fontFamily
            font.pixelSize: w.timeSize
            font.weight: Ui.WidgetStyle.titleWeight
            font.letterSpacing: w.preset === "minimal" ? 1 : -0.5
        }
        Text {
            visible: w.showDate
            anchors.horizontalCenter: parent.horizontalCenter
            text: w.preset === "minimal" ? Qt.formatDate(w.now, "dddd").toLowerCase()
                                         : Qt.formatDate(w.now, "ddd, d MMM")
            color: w.preset === "playful" ? Theme.primaryText : Theme.surfaceText
            opacity: w.preset === "playful" ? 0.8 : Ui.WidgetStyle.subOpacity
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: Ui.WidgetStyle.titleWeight === Font.Light ? Font.Light : Font.Normal
        }
    }

    // ── Dense: time (with seconds) left, date + week right ───────────
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        visible: w.preset === "dense"
        Text {
            text: Qt.formatTime(w.now, w.fmt24 ? "hh:mm" : "h:mm")
            color: Ui.WidgetStyle.titleColor
            font.family: Theme.fontFamily; font.pixelSize: w.timeSize; font.bold: true
        }
        Text {
            text: Qt.formatTime(w.now, "ss")
            color: Theme.surfaceText; opacity: Ui.WidgetStyle.subOpacity
            font.family: Theme.fontFamily; font.pixelSize: 14
            Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 4
        }
        Item { Layout.fillWidth: true }
        Text {
            horizontalAlignment: Text.AlignRight
            text: Qt.formatDate(w.now, "ddd d MMM") + "\nWeek " + w.weekNo(w.now)
            color: Theme.surfaceText; opacity: Ui.WidgetStyle.subOpacity
            font.family: Theme.fontFamily; font.pixelSize: 11
        }
    }
}
