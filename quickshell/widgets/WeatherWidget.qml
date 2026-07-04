import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

// Current weather from open-meteo (no API key). Coordinates come from
// WidgetsConfig.weatherLat/Lon (set in Settings). Refetches every 15 min.
Item {
    id: w
    readonly property bool relevant: true
    readonly property bool located: WidgetsConfig.weatherLat !== 0 || WidgetsConfig.weatherLon !== 0

    property real temp: 0
    property int code: -1
    property bool ok: false

    function refetch() {
        if (!located) return;
        wxProc.command = ["sh", "-c",
            "curl -s 'https://api.open-meteo.com/v1/forecast?latitude=" + WidgetsConfig.weatherLat +
            "&longitude=" + WidgetsConfig.weatherLon + "&current=temperature_2m,weather_code'"];
        wxProc.running = true;
    }

    Component.onCompleted: refetch()
    onLocatedChanged: refetch()
    Timer { interval: 900000; running: true; repeat: true; onTriggered: w.refetch() }

    Process {
        id: wxProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    w.temp = j.current.temperature_2m;
                    w.code = j.current.weather_code;
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

    ColumnLayout {
        anchors.fill: parent
        spacing: 4
        visible: w.located && w.ok
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
            Text { text: w.glyphFor(w.code); font.family: Theme.glyphFont; font.pixelSize: 40; color: Theme.primary }
            Text {
                text: Math.round(w.temp) + "°"
                color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: 34; font.bold: true
            }
        }
        Text {
            Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
            text: WidgetsConfig.weatherLabel || "Weather"
            color: Theme.surfaceText; opacity: 0.7; font.family: Theme.fontFamily; font.pixelSize: 12
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
