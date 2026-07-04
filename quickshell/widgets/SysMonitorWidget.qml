import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

// CPU + RAM usage. CPU from /proc/stat deltas, RAM from /proc/meminfo, polled
// every 2s via a short-lived process (mirrors bar/Resources.qml). Which metrics
// show is per-widget-configurable (WidgetsConfig.setting("sysmonitor", …)).
Item {
    id: w
    readonly property bool relevant: true

    readonly property bool showCpu: WidgetsConfig.setting("sysmonitor", "showCpu")
    readonly property bool showRam: WidgetsConfig.setting("sysmonitor", "showRam")

    property real cpu: 0      // 0..1
    property real mem: 0      // 0..1
    property var _prev: null

    readonly property var rows: {
        const r = [];
        if (showCpu) r.push({ label: "CPU", v: w.cpu });
        if (showRam) r.push({ label: "RAM", v: w.mem });
        return r;
    }

    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: statProc.running = true
    }

    Process {
        id: statProc
        command: ["sh", "-c", "cat /proc/stat | grep '^cpu '; cat /proc/meminfo | grep -E 'MemTotal|MemAvailable'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const cpuParts = lines[0].trim().split(/\s+/).slice(1).map(Number);
                const idle = cpuParts[3] + (cpuParts[4] || 0);
                const total = cpuParts.reduce((a, b) => a + b, 0);
                if (w._prev) {
                    const dt = total - w._prev.total, di = idle - w._prev.idle;
                    w.cpu = dt > 0 ? Math.max(0, Math.min(1, 1 - di / dt)) : 0;
                }
                w._prev = { total: total, idle: idle };
                let memTotal = 0, memAvail = 0;
                for (const l of lines) {
                    if (l.indexOf("MemTotal") === 0) memTotal = Number(l.replace(/\D+/g, ""));
                    else if (l.indexOf("MemAvailable") === 0) memAvail = Number(l.replace(/\D+/g, ""));
                }
                if (memTotal > 0) w.mem = Math.max(0, Math.min(1, 1 - memAvail / memTotal));
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            visible: w.rows.length === 0
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: "No metrics enabled"
            color: Theme.surfaceText; opacity: 0.6
            font.family: Theme.fontFamily; font.pixelSize: 12
        }

        Repeater {
            model: w.rows
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: modelData.label; color: Theme.surfaceText
                    Layout.preferredWidth: 36; font.family: Theme.fontFamily; font.pixelSize: 13
                }
                Rectangle {
                    Layout.fillWidth: true; height: 8; radius: 4
                    color: Qt.darker(Theme.surface, 1.3)
                    Rectangle {
                        width: parent.width * modelData.v; height: parent.height; radius: 4
                        color: Theme.primary
                        Behavior on width { NumberAnimation { duration: 300 } }
                    }
                }
                Text {
                    text: Math.round(modelData.v * 100) + "%"; color: Theme.surfaceText
                    Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight
                    font.family: Theme.fontFamily; font.pixelSize: 12
                }
            }
        }
    }
}
