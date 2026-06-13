import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../ui" as Ui
import ".."

// Compact CPU + RAM usage. Polls /proc every 2s; CPU% is computed from the
// jiffies delta between samples (so the first sample just primes the baseline).
Item {
    id: res
    property bool horizontal: false

    readonly property string sym: "/usr/share/icons/Papirus/16x16/symbolic/devices"

    property int cpu: 0          // 0..100
    property int mem: 0          // 0..100
    property real _prevIdle: -1
    property real _prevTotal: -1

    implicitWidth: lay.implicitWidth
    implicitHeight: lay.implicitHeight

    function _parse(text) {
        const lines = text.split("\n");
        let memTotal = 0, memAvail = 0;
        for (const line of lines) {
            if (line.startsWith("cpu ") || line.startsWith("cpu\t")) {
                const f = line.trim().split(/\s+/).slice(1).map(Number);
                const idle = (f[3] || 0) + (f[4] || 0);          // idle + iowait
                let total = 0; for (const v of f) total += v;
                if (res._prevTotal >= 0 && total > res._prevTotal) {
                    const dTotal = total - res._prevTotal;
                    const dIdle = idle - res._prevIdle;
                    res.cpu = Math.max(0, Math.min(100, Math.round((1 - dIdle / dTotal) * 100)));
                }
                res._prevIdle = idle;
                res._prevTotal = total;
            } else if (line.startsWith("MemTotal:")) {
                memTotal = Number(line.replace(/[^0-9]/g, ""));
            } else if (line.startsWith("MemAvailable:")) {
                memAvail = Number(line.replace(/[^0-9]/g, ""));
            }
        }
        if (memTotal > 0) res.mem = Math.round((1 - memAvail / memTotal) * 100);
    }

    Process {
        id: proc
        command: ["sh", "-c", "head -1 /proc/stat; grep -E '^MemTotal:|^MemAvailable:' /proc/meminfo"]
        stdout: StdioCollector { id: out }
        onExited: res._parse(out.text)
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    GridLayout {
        id: lay
        anchors.centerIn: parent
        rows: res.horizontal ? 1 : -1
        columns: res.horizontal ? -1 : 1
        rowSpacing: 4
        columnSpacing: 10

        // CPU
        RowLayout {
            Layout.alignment: Qt.AlignCenter
            spacing: 3
            Ui.Icon { source: res.sym + "/cpu-symbolic.svg"; color: Theme.surfaceText; size: 13 }
            Text {
                text: res.cpu + "%"
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
        }
        // RAM
        RowLayout {
            Layout.alignment: Qt.AlignCenter
            spacing: 3
            Ui.Icon { source: res.sym + "/ram-symbolic.svg"; color: Theme.surfaceText; size: 13 }
            Text {
                text: res.mem + "%"
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }
}
