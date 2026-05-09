pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // ---------- public state ----------
    property bool enabled: false
    property bool connected: false
    property string activeSsid: ""
    property int activeSignal: 0          // 0..100
    property string activeConnectionName: ""  // for `nmcli connection down`
    property string lastError: ""
    property bool connecting: false
    property bool scanning: false
    property string pendingSsid: ""
    property string pendingPasswordSsid: ""
    property var savedSsids: ({})  // map ssid -> connection name
    property var networks: []      // array of { ssid, signal, security, bssid, active, saved }

    // ---------- internal ----------
    function _setError(msg) {
        if (msg && msg.length) {
            console.warn("WifiService:", msg);
            lastError = msg;
        }
    }

    function clearError() { lastError = ""; }

    function setEnabled(on) {
        radioSet.command = ["nmcli", "radio", "wifi", on ? "on" : "off"];
        radioSet.running = true;
    }

    function connect(ssid) {
        if (!ssid) return;
        if (root.connecting) return;  // ignore clicks while a connect is in flight
        const entry = root._findNetwork(ssid);
        const isSecured = entry && entry.security && entry.security.length > 0;
        const isSaved = root.savedSsids[ssid] !== undefined;

        if (isSecured && !isSaved) {
            // Defer to password prompt UI (Task 9)
            root.pendingPasswordSsid = ssid;
            return;
        }

        root.pendingSsid = ssid;
        root.connecting = true;
        connectProc.command = ["nmcli", "device", "wifi", "connect", ssid];
        connectProc.running = true;
    }

    function disconnect() {
        if (!root.activeConnectionName) return;
        disconnectProc.command = ["nmcli", "connection", "down", root.activeConnectionName];
        disconnectProc.running = true;
    }

    function connectWithPassword(ssid, password) {
        if (!ssid) return;
        if (root.connecting) return;  // ignore double-submit (e.g. Enter pressed twice)
        root.pendingSsid = ssid;
        root.connecting = true;
        pwConnectProc.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password];
        pwConnectProc.running = true;
    }

    function cancelPasswordPrompt() {
        root.pendingPasswordSsid = "";
        root.clearError();
    }

    function forget(ssid) {
        const connName = root.savedSsids[ssid];
        if (!connName) return;
        forgetProc.command = ["nmcli", "connection", "delete", connName];
        forgetProc.running = true;
    }

    function _findNetwork(ssid) {
        for (const e of root.networks) {
            if (e.ssid === ssid) return e;
        }
        return null;
    }

    // ---------- public methods ----------
    function refreshActive() {
        radioCheck.running = true;
        activeQuery.running = true;
    }

    function refresh() {
        refreshActive();
        savedQuery.running = true;
        scanQuery.running = true;
    }

    // ---------- nmcli: radio status ----------
    Process {
        id: radioCheck
        command: ["nmcli", "-t", "radio", "wifi"]
        stdout: StdioCollector { id: radioOut }
        onExited: (code) => {
            if (code !== 0) { root._setError("nmcli radio failed"); return; }
            root.enabled = (radioOut.text.trim() === "enabled");
        }
    }

    Process {
        id: radioSet
        stderr: StdioCollector { id: radioSetErr }
        onExited: (code) => {
            if (code !== 0) root._setError("radio toggle failed: " + radioSetErr.text.trim());
            root.refreshActive();
        }
    }

    // ---------- nmcli: active connection ----------
    Process {
        id: activeQuery
        // -t terse, -e escape, ACTIVE,SSID,SIGNAL,BSSID — only IN-USE network has ACTIVE=yes
        command: ["nmcli", "-t", "-e", "yes", "-f", "ACTIVE,SSID,SIGNAL,BSSID", "device", "wifi"]
        stdout: StdioCollector { id: activeOut }
        stderr: StdioCollector { id: activeErr }
        onExited: (code) => {
            if (code !== 0) {
                root._setError("nmcli wifi list failed: " + activeErr.text.trim());
                root.connected = false;
                root.activeSsid = "";
                root.activeSignal = 0;
                return;
            }
            const lines = activeOut.text.split("\n").filter(l => l.length > 0);
            for (const line of lines) {
                const parts = root._splitTerse(line);
                if (parts[0] === "yes") {
                    root.connected = true;
                    root.activeSsid = parts[1];
                    root.activeSignal = parseInt(parts[2]) || 0;
                    activeNameQuery.running = true;
                    return;
                }
            }
            root.connected = false;
            root.activeSsid = "";
            root.activeSignal = 0;
            root.activeConnectionName = "";
        }
    }

    // Active connection NAME (may differ from SSID for saved profiles)
    Process {
        id: activeNameQuery
        command: ["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]
        stdout: StdioCollector { id: activeNameOut }
        onExited: (code) => {
            if (code !== 0) return;
            // Race guard: a later activeQuery may have flipped connected→false
            // while we were in flight; don't write a stale name in that case.
            if (!root.connected) return;
            const lines = activeNameOut.text.split("\n").filter(l => l.length > 0);
            for (const line of lines) {
                const parts = root._splitTerse(line);
                if (parts[1] === "802-11-wireless" || parts[1] === "wifi") {
                    root.activeConnectionName = parts[0];
                    return;
                }
            }
        }
    }

    // Maps SSID → saved connection NAME. Assumes nmcli's default profile
    // naming (NAME == SSID). If the user renamed a profile via
    // `nmcli connection modify <conn> connection.id <new>`, that profile
    // appears as unsaved and forget() can't target it. A correct fix would
    // be N+1 queries: `nmcli -t -g 802-11-wireless.ssid connection show <name>`
    // per wifi profile, since 802-11-wireless.ssid isn't valid in the multi-
    // profile listing.
    Process {
        id: savedQuery
        command: ["nmcli", "-t", "-e", "yes", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector { id: savedOut }
        onExited: (code) => {
            if (code !== 0) return;
            const map = {};
            const lines = savedOut.text.split("\n").filter(l => l.length > 0);
            for (const line of lines) {
                const parts = root._splitTerse(line);
                if (parts[1] === "802-11-wireless" || parts[1] === "wifi") {
                    map[parts[0]] = parts[0];
                }
            }
            root.savedSsids = map;
        }
    }

    Process {
        id: scanQuery
        command: ["nmcli", "-t", "-e", "yes", "-f", "IN-USE,SSID,SIGNAL,SECURITY,BSSID", "device", "wifi", "list"]
        stdout: StdioCollector { id: scanOut }
        stderr: StdioCollector { id: scanErr }
        onStarted: root.scanning = true
        onExited: (code) => {
            root.scanning = false;
            if (code !== 0) {
                root._setError("scan failed: " + scanErr.text.trim());
                return;
            }
            const lines = scanOut.text.split("\n").filter(l => l.length > 0);
            const bySsid = {};
            for (const line of lines) {
                const p = root._splitTerse(line);
                const ssid = p[1];
                if (!ssid) continue;
                const signal = parseInt(p[2]) || 0;
                const entry = {
                    ssid: ssid,
                    signal: signal,
                    security: p[3] || "",
                    bssid: p[4] || "",
                    active: p[0] === "*",
                    saved: !!root.savedSsids[ssid],
                };
                if (!bySsid[ssid] || bySsid[ssid].signal < signal) bySsid[ssid] = entry;
            }
            const arr = Object.values(bySsid).sort((a, b) => b.signal - a.signal);
            root.networks = arr;
        }
    }

    Process {
        id: connectProc
        stderr: StdioCollector { id: connectErr }
        onExited: (code) => {
            root.connecting = false;
            if (code !== 0) {
                root._setError("connect failed: " + connectErr.text.trim());
            }
            root.pendingSsid = "";
            root.refresh();
        }
    }

    Process {
        id: disconnectProc
        stderr: StdioCollector { id: disconnectErr }
        onExited: (code) => {
            if (code !== 0) root._setError("disconnect failed: " + disconnectErr.text.trim());
            root.refresh();
        }
    }

    Process {
        id: forgetProc
        stderr: StdioCollector { id: forgetErr }
        onExited: (code) => {
            if (code !== 0) root._setError("forget failed: " + forgetErr.text.trim());
            root.refresh();
        }
    }

    Process {
        id: pwConnectProc
        stderr: StdioCollector { id: pwConnectErr }
        onExited: (code) => {
            root.connecting = false;
            root.pendingSsid = "";
            if (code !== 0) {
                root._setError(pwConnectErr.text.trim() || "wrong password");
                // Keep the prompt open so the user can retry
            } else {
                root.pendingPasswordSsid = "";
            }
            root.refresh();
        }
    }

    // ---------- terse output parser ----------
    // nmcli -t -e yes escapes ":" as "\:" and "\" as "\\"
    function _splitTerse(line) {
        const out = [];
        let cur = "";
        let i = 0;
        while (i < line.length) {
            const c = line[i];
            if (c === "\\" && i + 1 < line.length) {
                cur += line[i + 1];
                i += 2;
            } else if (c === ":") {
                out.push(cur);
                cur = "";
                i++;
            } else {
                cur += c;
                i++;
            }
        }
        out.push(cur);
        return out;
    }

    // ---------- background poll ----------
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshActive()
    }
}
