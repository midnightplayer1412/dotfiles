pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: svc

    // Sink entries: { name, description, kind, portLabel }
    //   kind: "bluetooth" | "hdmi" | "analog" | "other"
    //   portLabel: "Speakers" | "Headphones" | "" (only meaningful for analog)
    property var sinks: []
    property string defaultSink: ""
    property string lastError: ""

    Process {
        id: defaultProc
        command: ["pactl", "get-default-sink"]
        stdout: StdioCollector {
            onStreamFinished: svc.defaultSink = text.trim()
        }
    }

    Process {
        id: sinksProc
        command: ["pactl", "list", "sinks"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                const lines = text.split("\n");
                let cur = null;
                for (const line of lines) {
                    if (/^Sink #\d+/.test(line)) {
                        if (cur && cur.name) out.push(svc._finalizeSink(cur));
                        cur = { name: "", description: "", port: "" };
                        continue;
                    }
                    if (!cur) continue;
                    let m;
                    if ((m = line.match(/^\s*Name:\s*(\S+)/))) cur.name = m[1];
                    else if ((m = line.match(/^\s*Description:\s*(.+)/))) cur.description = m[1].trim();
                    else if ((m = line.match(/^\s*Active Port:\s*(\S+)/))) cur.port = m[1];
                }
                if (cur && cur.name) out.push(svc._finalizeSink(cur));
                svc.sinks = out;
            }
        }
    }

    function _finalizeSink(s) {
        let kind = "analog";
        if (s.name.startsWith("bluez_")) kind = "bluetooth";
        else if (s.name.indexOf("hdmi") >= 0 || s.port.indexOf("hdmi") >= 0) kind = "hdmi";
        else if (s.name.indexOf("alsa_") < 0) kind = "other";
        let portLabel = "";
        if (kind === "analog") {
            if (s.port.indexOf("headphones") >= 0) portLabel = "Headphones";
            else if (s.port.indexOf("speaker") >= 0) portLabel = "Speakers";
        }
        return { name: s.name, description: s.description || s.name, kind: kind, portLabel: portLabel };
    }

    Process {
        id: setDefaultProc
        onExited: (code) => {
            if (code !== 0) svc.lastError = "Failed to switch audio output";
            svc.refresh();
        }
    }

    function refresh() {
        defaultProc.running = true;
        sinksProc.running = true;
    }

    function setDefault(sinkName) {
        // sink names from pactl use [a-zA-Z0-9._-]; reject anything else
        // before passing to a shell-invoked pipeline.
        if (!/^[a-zA-Z0-9._-]+$/.test(sinkName)) {
            lastError = "Invalid sink name";
            return;
        }
        if (setDefaultProc.running) return;
        setDefaultProc.command = ["sh", "-c",
            "pactl set-default-sink \"$1\" && " +
            "pactl list short sink-inputs | awk '{print $1}' | " +
            "xargs -r -I@ pactl move-sink-input @ \"$1\"",
            "_", sinkName];
        setDefaultProc.running = true;
    }

    function clearError() { lastError = ""; }

    Component.onCompleted: refresh()
}
