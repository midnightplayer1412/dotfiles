import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."
import "../ui" as Ui

// CPU + RAM usage. CPU from /proc/stat deltas, RAM from /proc/meminfo, polled
// every 2s via a short-lived process (mirrors bar/Resources.qml). Which metrics
// show is per-widget-configurable (WidgetsConfig.setting("sysmonitor", …)); the
// active widget style picks bars vs rings, and the Data-dense preset adds a CPU
// sparkline.
Item {
    id: w
    readonly property bool relevant: true

    readonly property bool showCpu: WidgetsConfig.setting("sysmonitor", "showCpu")
    readonly property bool showRam: WidgetsConfig.setting("sysmonitor", "showRam")

    readonly property string gauge: Ui.WidgetStyle.gauge   // "bar" | "ring"
    readonly property bool dense: Ui.WidgetStyle.dense

    property real cpu: 0      // 0..1
    property real mem: 0      // 0..1
    property var _prev: null
    property var hist: []     // recent cpu samples for the sparkline
    readonly property int histMax: 40

    // Structure only — NO live value embedded, so this array's identity is stable
    // across polls (it changes only when the CPU/RAM settings toggle). Delegates
    // read the live value by key; if the value were in here, every poll would
    // rebuild the array, recreate the bar delegates, and animate them from 0.
    readonly property var rows: {
        const r = [];
        if (showCpu) r.push({ label: "CPU", key: "cpu" });
        if (showRam) r.push({ label: "RAM", key: "ram" });
        return r;
    }
    function valueOf(key) { return key === "cpu" ? w.cpu : w.mem; }

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
                    w.hist = w.hist.concat([w.cpu]).slice(-w.histMax);
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

    Text {
        anchors.centerIn: parent
        visible: w.rows.length === 0
        text: "No metrics enabled"
        color: Theme.surfaceText; opacity: 0.6
        font.family: Theme.fontFamily; font.pixelSize: 12
    }

    // ── Bar layout (Refined / Minimal) ───────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        visible: w.gauge === "bar" && w.rows.length > 0

        Repeater {
            model: w.rows
            delegate: RowLayout {
                required property var modelData
                readonly property real v: w.valueOf(modelData.key)
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: modelData.label; color: Theme.surfaceText
                    Layout.preferredWidth: 36; font.family: Theme.fontFamily; font.pixelSize: 13
                    opacity: Ui.WidgetStyle.preset === "minimal" ? Ui.WidgetStyle.subOpacity : 1
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: Ui.WidgetStyle.barThickness
                    radius: height / 2
                    color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.15)
                    Rectangle {
                        width: parent.width * v; height: parent.height; radius: parent.radius
                        color: Ui.WidgetStyle.useGradient ? "transparent" : Ui.WidgetStyle.accent
                        gradient: Ui.WidgetStyle.useGradient ? barGrad : null
                        Behavior on width { NumberAnimation { duration: 300 } }
                    }
                }
                Text {
                    text: Math.round(v * 100) + "%"; color: Theme.surfaceText
                    Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight
                    font.family: Theme.fontFamily; font.pixelSize: 12
                    opacity: Ui.WidgetStyle.preset === "minimal" ? Ui.WidgetStyle.subOpacity : 1
                }
            }
        }
    }

    Gradient {
        id: barGrad
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: Ui.WidgetStyle.gradA }
        GradientStop { position: 1; color: Ui.WidgetStyle.gradB }
    }

    // ── Ring layout (Playful / Data-dense) ───────────────────────────
    RowLayout {
        anchors.fill: parent
        spacing: 8
        visible: w.gauge === "ring" && w.rows.length > 0

        Loader {
            active: w.showCpu
            visible: active
            sourceComponent: ringComp
            onLoaded: { item.value = Qt.binding(() => w.cpu); item.label = "CPU"; item.ringColor = Qt.binding(() => Ui.WidgetStyle.gradA); }
        }

        // Dense: CPU sparkline fills the gap between the two rings.
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: w.dense && w.showCpu
            Text {
                id: sparkLbl
                anchors.top: parent.top; anchors.left: parent.left
                text: "last " + (w.histMax * 2) + "s"
                color: Theme.surfaceText; opacity: Ui.WidgetStyle.subOpacity
                font.family: Theme.fontFamily; font.pixelSize: 10
            }
            Canvas {
                id: spark
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: sparkLbl.bottom; anchors.bottom: parent.bottom
                anchors.topMargin: 2
                onPaint: {
                    const ctx = getContext("2d"); ctx.reset();
                    const h = w.hist, n = h.length;
                    if (n < 2) return;
                    const stepX = width / (n - 1);
                    const y = v => height - v * height;
                    ctx.beginPath();
                    ctx.moveTo(0, y(h[0]));
                    for (let i = 1; i < n; i++) ctx.lineTo(i * stepX, y(h[i]));
                    ctx.lineWidth = 2; ctx.lineJoin = "round";
                    ctx.strokeStyle = Ui.WidgetStyle.accent;
                    ctx.stroke();
                    ctx.lineTo(width, height); ctx.lineTo(0, height); ctx.closePath();
                    ctx.fillStyle = Qt.rgba(Ui.WidgetStyle.accent.r, Ui.WidgetStyle.accent.g, Ui.WidgetStyle.accent.b, 0.12);
                    ctx.fill();
                }
                Connections { target: w; function onHistChanged() { spark.requestPaint(); } }
            }
        }

        Loader {
            active: w.showRam
            visible: active
            sourceComponent: ringComp
            onLoaded: { item.value = Qt.binding(() => w.mem); item.label = "RAM"; item.ringColor = Qt.binding(() => Ui.WidgetStyle.gradB); }
        }
    }

    // Reusable radial gauge: track ring + value arc + centered percent + label.
    Component {
        id: ringComp
        Item {
            id: ring
            property real value: 0
            property string label: ""
            property color ringColor: Ui.WidgetStyle.accent
            readonly property int diam: w.dense ? 46 : 58
            implicitWidth: diam
            implicitHeight: diam + 16
            Layout.alignment: Qt.AlignVCenter

            Canvas {
                id: arc
                width: ring.diam; height: ring.diam
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                onPaint: {
                    const ctx = getContext("2d"); ctx.reset();
                    const cx = width / 2, cy = height / 2, r = width / 2 - 4;
                    ctx.lineWidth = w.dense ? 4 : 5; ctx.lineCap = "round";
                    ctx.strokeStyle = Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.15);
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, 2 * Math.PI); ctx.stroke();
                    ctx.strokeStyle = ring.ringColor;
                    ctx.beginPath(); ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + ring.value * 2 * Math.PI); ctx.stroke();
                }
                Component.onCompleted: requestPaint()
            }
            Text {
                anchors.horizontalCenter: arc.horizontalCenter
                anchors.verticalCenter: arc.verticalCenter
                text: Math.round(ring.value * 100)
                color: Theme.surfaceText; font.family: Theme.fontFamily
                font.pixelSize: w.dense ? 12 : 15; font.bold: true
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                text: ring.label; color: Theme.surfaceText; opacity: Ui.WidgetStyle.subOpacity
                font.family: Theme.fontFamily; font.pixelSize: 11
            }
            // Repaint the arc when the bound value/color updates.
            onValueChanged: arc.requestPaint()
            onRingColorChanged: arc.requestPaint()
        }
    }
}
