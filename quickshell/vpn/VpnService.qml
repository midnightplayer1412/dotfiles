pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: svc

    // Each entry: { name: string, type: string, active: bool }
    property var connections: []
    property string activeName: ""
    property string lastError: ""

    // ── refresh ─────────────────────────────────────────────────────
    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE,ACTIVE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                let active = "";
                for (const line of text.split("\n")) {
                    if (!line) continue;
                    // nmcli -t output uses ':' separators with `\:` escaping inside fields
                    // Field count is fixed at 3 here, so split on un-escaped ':' from the right.
                    const parts = line.split(":");
                    if (parts.length < 3) continue;
                    const isActive = parts[parts.length - 1] === "yes";
                    const type = parts[parts.length - 2];
                    const name = parts.slice(0, parts.length - 2).join(":")
                                       .replace(/\\:/g, ":");
                    if (type !== "vpn" && type !== "wireguard") continue;
                    out.push({ name: name, type: type, active: isActive });
                    if (isActive) active = name;
                }
                svc.connections = out;
                svc.activeName = active;
            }
        }
    }

    function refresh() { listProc.running = true; }

    // ── activate / deactivate ───────────────────────────────────────
    Process {
        id: actProc
        command: ["true"]
        property string action: ""
        property string name: ""
        onExited: (code) => {
            if (code !== 0) svc.lastError = actProc.action + " failed for " + actProc.name;
            svc.refresh();
        }
    }

    function activate(name) {
        if (actProc.running) return;
        // If another VPN is up, deactivate it first.
        if (svc.activeName !== "" && svc.activeName !== name) {
            actProc.action = "down";
            actProc.name = svc.activeName;
            actProc.command = ["nmcli", "connection", "down", svc.activeName];
            actProc.running = true;
            // Once it returns, refresh() will fire; user will need to click activate
            // again. For v1, this two-step model is acceptable.
            return;
        }
        actProc.action = "up";
        actProc.name = name;
        actProc.command = ["nmcli", "connection", "up", name];
        actProc.running = true;
    }

    function deactivate(name) {
        if (actProc.running) return;
        actProc.action = "down";
        actProc.name = name;
        actProc.command = ["nmcli", "connection", "down", name];
        actProc.running = true;
    }

    function clearError() { lastError = ""; }

    Component.onCompleted: refresh()
}
