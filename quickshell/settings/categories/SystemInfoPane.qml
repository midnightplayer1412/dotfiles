import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../../ui" as Ui
import "../.."

// "About" tab: a read-only snapshot of system / hardware facts. Gathered once via
// a single shell pass (the mascot's Process + StdioCollector pattern) whenever the
// pane becomes visible, so values like uptime stay fresh each time the panel opens.
Item {
    id: pane

    property var info: ({})   // key → value map (os, kernel, host, wm, cpu, cores, memkb, uptime, disk)
    property var gpus: []     // one entry per GPU
    property bool loaded: false

    readonly property string sym: "/usr/share/icons/Papirus/16x16/symbolic"

    // Gather everything in one bash pass; emit tab-separated key/value lines.
    readonly property string gatherScript: `
printf 'os\\t%s\\n' "$(. /etc/os-release; echo "$PRETTY_NAME")"
printf 'kernel\\t%s\\n' "$(uname -r)"
printf 'host\\t%s\\n' "$(uname -n)"
printf 'wm\\t%s\\n' "$(hyprctl version 2>/dev/null | head -1 | grep -oE 'Hyprland [0-9.]+')"
printf 'cpu\\t%s\\n' "$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ *//')"
printf 'cores\\t%s\\n' "$(nproc)"
lspci 2>/dev/null | grep -Ei 'vga|3d|display' | sed -E 's/^[0-9a-f:.]+ [^:]+: //; s/ \\(rev [0-9a-f]+\\)$//' | while IFS= read -r g; do printf 'gpu\\t%s\\n' "$g"; done
printf 'memkb\\t%s\\n' "$(grep -m1 MemTotal /proc/meminfo | awk '{print $2}')"
printf 'uptime\\t%s\\n' "$(cut -d' ' -f1 /proc/uptime | cut -d. -f1)"
df -h --output=used,size,pcent / 2>/dev/null | tail -1 | awk '{printf "disk\\t%s / %s (%s)\\n", $1, $2, $3}'
`

    function fmtUptime(s) {
        const t = parseInt(s) || 0;
        const d = Math.floor(t / 86400);
        const h = Math.floor((t % 86400) / 3600);
        const m = Math.floor((t % 3600) / 60);
        const out = [];
        if (d) out.push(d + "d");
        if (h) out.push(h + "h");
        out.push(m + "m");
        return out.join(" ");
    }
    function fmtMem(kb) {
        const v = parseInt(kb) || 0;
        return v > 0 ? (v / 1048576).toFixed(1) + " GiB" : "—";
    }
    function gpuText() {
        return pane.gpus.length > 0 ? pane.gpus.join("\n") : "—";
    }
    function cpuText() {
        if (!pane.info.cpu)
            return "—";
        return pane.info.cpu + (pane.info.cores ? "  (" + pane.info.cores + " threads)" : "");
    }

    onVisibleChanged: if (visible) gather.running = true
    Component.onCompleted: gather.running = true

    Process {
        id: gather
        command: ["bash", "-c", pane.gatherScript]
        stdout: StdioCollector { id: collected }
        onExited: (code) => {
            const map = {};
            const g = [];
            const lines = collected.text.split("\n");
            for (let n = 0; n < lines.length; n++) {
                const line = lines[n];
                if (!line)
                    continue;
                const i = line.indexOf("\t");
                if (i < 0)
                    continue;
                const k = line.slice(0, i);
                const v = line.slice(i + 1);
                if (k === "gpu")
                    g.push(v);
                else
                    map[k] = v;
            }
            pane.info = map;
            pane.gpus = g;
            pane.loaded = true;
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight
        clip: true
        ScrollBar.vertical: Ui.ScrollBar { visible: flick.contentHeight > flick.height + 1 }
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 16

            // ── Header: machine identity ──
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 2
                spacing: 14
                Ui.Icon {
                    source: pane.sym + "/devices/computer-symbolic.svg"
                    color: Theme.primary
                    size: 38
                    Layout.alignment: Qt.AlignVCenter
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: pane.info.host || "System"
                        color: Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: 20
                        font.bold: true
                    }
                    Text {
                        text: pane.info.os || (pane.loaded ? "Unknown" : "Reading…")
                        color: Theme.outline
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                    }
                }
            }

            // ── Software ──
            Card {
                title: "Software"
                icon: pane.sym + "/categories/applications-system-symbolic.svg"
                InfoRow { label: "OS";         value: pane.info.os || "—" }
                InfoRow { label: "Kernel";     value: pane.info.kernel || "—" }
                InfoRow { label: "Hostname";   value: pane.info.host || "—" }
                InfoRow { label: "Compositor"; value: pane.info.wm || "—" }
                InfoRow { label: "Uptime";     value: pane.fmtUptime(pane.info.uptime) }
            }

            // ── Hardware ──
            Card {
                title: "Hardware"
                icon: pane.sym + "/devices/cpu-symbolic.svg"
                InfoRow { label: "Processor"; value: pane.cpuText() }
                InfoRow { label: "Graphics";  value: pane.gpuText() }
                InfoRow { label: "Memory";    value: pane.fmtMem(pane.info.memkb) }
                InfoRow { label: "Disk (/)";  value: pane.info.disk || "—" }
            }

            Item { Layout.fillHeight: true }
        }
    }

    // ── Reusable pieces ──
    component InfoRow: RowLayout {
        property string label: ""
        property string value: ""
        Layout.fillWidth: true
        spacing: 12
        Text {
            text: label
            color: Theme.outline
            font.family: Theme.fontFamily
            font.pixelSize: 13
            Layout.preferredWidth: 110
            Layout.alignment: Qt.AlignTop
        }
        Text {
            text: value
            color: Theme.surfaceText
            font.family: Theme.fontFamily
            font.pixelSize: 13
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
    }

    // Thin wrapper over Ui.Card: title/icon props and the body slot are inherited;
    // the two Card{} usages pass title/icon + InfoRow body children unchanged.
    component Card: Ui.Card {
        Layout.fillWidth: true
    }
}
