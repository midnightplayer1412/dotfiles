import QtQuick
import ".."

// Big time + date, formatted per LockConfig. Driven by an external `now`
// property so a single shared timer (in LockView) ticks all instances.
Column {
    id: clock

    property date now: new Date()
    property string clockFormat: "24h"   // "24h" | "12h"
    property bool showSeconds: false
    property string dateFormat: "dddd, MMMM d"
    property bool showDate: true
    property color textColor: "white"

    spacing: 2

    function _fmtTime(d) {
        let h = d.getHours();
        const m = d.getMinutes();
        const s = d.getSeconds();
        let suffix = "";
        if (clockFormat === "12h") {
            suffix = h < 12 ? " AM" : " PM";
            h = h % 12; if (h === 0) h = 12;
        }
        const pad = (n) => (n < 10 ? "0" + n : "" + n);
        const hh = clockFormat === "12h" ? ("" + h) : pad(h);
        let out = hh + ":" + pad(m);
        if (showSeconds) out += ":" + pad(s);
        return out + suffix;
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        // Reference showSeconds/clockFormat explicitly so toggling them re-renders
        // immediately — they're read inside _fmtTime(), which QML wouldn't otherwise
        // track as binding dependencies (only the per-second `now` tick would).
        text: { clock.showSeconds; clock.clockFormat; return clock._fmtTime(clock.now); }
        color: clock.textColor
        font.family: Theme.fontFamily
        font.pixelSize: 92
        font.bold: true
        style: Text.Raised
        styleColor: "#80000000"
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: clock.showDate
        text: Qt.formatDate(clock.now, clock.dateFormat)
        color: clock.textColor
        font.family: Theme.fontFamily
        font.pixelSize: 20
        font.bold: true
        style: Text.Raised
        styleColor: "#80000000"
    }
}
