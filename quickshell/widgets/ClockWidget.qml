import QtQuick
import ".."

// Presentational only: renders time/date, declares relevance. Format is driven
// by per-widget settings (WidgetsConfig.setting("clock", …)).
Item {
    id: w
    readonly property bool relevant: true

    readonly property bool fmt24: WidgetsConfig.setting("clock", "format24")
    readonly property bool showSeconds: WidgetsConfig.setting("clock", "showSeconds")
    readonly property bool showDate: WidgetsConfig.setting("clock", "showDate")
    readonly property string timeFmt:
        (fmt24 ? "hh:mm" : "h:mm") + (showSeconds ? ":ss" : "") + (fmt24 ? "" : " AP")

    property var now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: w.now = new Date() }

    Column {
        anchors.centerIn: parent
        spacing: 2
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(w.now, w.timeFmt)
            color: Theme.primary; font.family: Theme.fontFamily
            font.pixelSize: 38; font.bold: true
        }
        Text {
            visible: w.showDate
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(w.now, "ddd, d MMM")
            color: Theme.surfaceText; opacity: 0.8
            font.family: Theme.fontFamily; font.pixelSize: 14
        }
    }
}
