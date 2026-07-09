import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."
import "../ui" as Ui

// Current weather from open-meteo (no API key). Location + units come from the
// widget's own settings (WidgetsConfig.setting("weather", …)). Refetches on any
// of those changing, and every 15 min. Look follows the active widget style;
// the Data-dense preset also surfaces hi/lo, humidity and wind.
Item {
    id: w
    readonly property bool relevant: true

    readonly property real lat: WidgetsConfig.setting("weather", "lat")
    readonly property real lon: WidgetsConfig.setting("weather", "lon")
    readonly property string units: WidgetsConfig.setting("weather", "units")
    readonly property string label: WidgetsConfig.setting("weather", "label")
    readonly property bool located: lat !== 0 || lon !== 0

    readonly property string preset: Ui.WidgetStyle.preset
    readonly property bool dense: Ui.WidgetStyle.dense

    property real temp: 0
    property int code: -1
    property bool ok: false
    property real hi: 0
    property real lo: 0
    property int humidity: 0
    property real wind: 0

    readonly property string unitSuffix: units === "f" ? "°F" : "°C"

    function refetch() {
        if (!located) return;
        wxProc.command = ["sh", "-c",
            "curl -s 'https://api.open-meteo.com/v1/forecast?latitude=" + lat +
            "&longitude=" + lon +
            "&current=temperature_2m,weather_code,relative_humidity_2m,wind_speed_10m" +
            "&daily=temperature_2m_max,temperature_2m_min&timezone=auto" +
            (units === "f" ? "&temperature_unit=fahrenheit" : "") + "'"];
        wxProc.running = true;
    }

    Component.onCompleted: refetch()
    onLatChanged: refetch()
    onLonChanged: refetch()
    onUnitsChanged: refetch()
    Timer { interval: 900000; running: true; repeat: true; onTriggered: w.refetch() }

    Process {
        id: wxProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    w.temp = j.current.temperature_2m;
                    w.code = j.current.weather_code;
                    w.humidity = j.current.relative_humidity_2m;
                    w.wind = j.current.wind_speed_10m;
                    w.hi = j.daily.temperature_2m_max[0];
                    w.lo = j.daily.temperature_2m_min[0];
                    w.ok = true;
                } catch (e) { w.ok = false; }
            }
        }
    }

    // Minimal WMO code -> nf-md glyph.
    function glyphFor(c) {
        if (c === 0) return "\u{F0599}";                    // sunny
        if (c <= 3) return "\u{F0595}";                     // partly cloudy
        if (c <= 48) return "\u{F0591}";                    // fog/cloud
        if (c <= 67) return "\u{F0597}";                    // rain
        if (c <= 77) return "\u{F0598}";                    // snow
        return "\u{F0596}";                                 // pour/storm
    }

    // ── Compact (non-dense): centered glyph + temp, label under ──────
    ColumnLayout {
        anchors.fill: parent
        spacing: 4
        visible: w.located && w.ok && !w.dense
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
            Text {
                text: w.glyphFor(w.code)
                font.family: Theme.glyphFont
                font.pixelSize: w.preset === "playful" ? 48 : 40
                color: w.preset === "minimal" ? Theme.surfaceText : Theme.primary
                opacity: w.preset === "minimal" ? 0.8 : 1
            }
            Text {
                text: Math.round(w.temp) + w.unitSuffix
                color: w.preset === "minimal" ? Theme.surfaceText : Ui.WidgetStyle.accent
                font.family: Theme.fontFamily
                font.pixelSize: 30
                font.weight: Ui.WidgetStyle.titleWeight
            }
        }
        Text {
            Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
            text: w.label || "Weather"
            color: Theme.surfaceText; opacity: Ui.WidgetStyle.subOpacity
            font.family: Theme.fontFamily; font.pixelSize: 12
        }
    }

    // ── Dense: glyph + temp + hi/lo, then humidity / wind line ───────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 2
        spacing: 8
        visible: w.located && w.ok && w.dense
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text { text: w.glyphFor(w.code); font.family: Theme.glyphFont; font.pixelSize: 30; color: Theme.primary }
            Text {
                text: Math.round(w.temp) + w.unitSuffix
                color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: 26; font.bold: true
            }
            Text {
                text: "↑" + Math.round(w.hi) + "°  ↓" + Math.round(w.lo) + "°"
                color: Theme.surfaceText; opacity: Ui.WidgetStyle.subOpacity
                font.family: Theme.fontFamily; font.pixelSize: 13
                Layout.alignment: Qt.AlignVCenter
            }
        }
        Text {
            Layout.fillWidth: true
            text: (w.label ? w.label + "  ·  " : "") + "\u{F058E} " + w.humidity + "%   \u{F059D} " + Math.round(w.wind) + " km/h"
            color: Theme.surfaceText; opacity: Ui.WidgetStyle.subOpacity
            font.family: Theme.fontFamily; font.pixelSize: 12
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !w.located
        width: parent.width - 20; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
        text: "Set your location in\nSettings → Widgets"
        color: Theme.surfaceText; opacity: 0.6; font.family: Theme.fontFamily; font.pixelSize: 12
    }
}
