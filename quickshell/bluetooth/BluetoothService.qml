pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: svc

    property bool enabled: false
    property bool scanning: false
    property string lastError: ""
    property string pendingConfirmDevice: ""
    property string pendingConfirmCode: ""
    property var devices: []
    property bool _enriching: false

    // ── refresh: read controller power state + paired/known devices ──
    Process {
        id: showProc
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/Powered:\s*(yes|no)/);
                if (m) svc.enabled = (m[1] === "yes");
            }
        }
    }

    Process {
        id: devicesProc
        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.startsWith("Device "));
                const out = [];
                for (const line of lines) {
                    // "Device AA:BB:CC:DD:EE:FF Name with spaces"
                    const parts = line.substring("Device ".length).split(" ");
                    const mac = parts.shift();
                    const name = parts.join(" ") || mac;
                    out.push({ mac: mac, name: name, paired: true,
                               connected: false, rssi: 0, icon: "" });
                }
                // Replace; per-device connected/icon enrichment in next batch
                svc.devices = out;
                svc._enrichConnectedFlags();
            }
        }
    }

    Process {
        id: pairedConnectedProc
        // Note: no built-in "is connected" list, so query info per device.
        // For v1 we just call `bluetoothctl info <mac>` per device.
        property int cursor: 0
        property var working: []
        command: ["bluetoothctl", "info", "00:00:00:00:00:00"]   // placeholder; reset before run
        stdout: StdioCollector {
            onStreamFinished: {
                const mac = pairedConnectedProc.working[pairedConnectedProc.cursor]?.mac ?? "";
                const cm = text.match(/Connected:\s*(yes|no)/);
                const im = text.match(/Icon:\s*(\S+)/);
                if (mac) {
                    const arr = pairedConnectedProc.working;
                    const idx = arr.findIndex(d => d.mac === mac);
                    if (idx >= 0) {
                        arr[idx].connected = cm ? (cm[1] === "yes") : false;
                        arr[idx].icon = im ? im[1] : "";
                    }
                }
                pairedConnectedProc.cursor++;
                if (pairedConnectedProc.cursor < pairedConnectedProc.working.length) {
                    pairedConnectedProc.command = ["bluetoothctl", "info",
                        pairedConnectedProc.working[pairedConnectedProc.cursor].mac];
                    pairedConnectedProc.running = true;
                } else {
                    svc.devices = pairedConnectedProc.working.slice();
                    svc._enriching = false;
                }
            }
        }
    }

    function _enrichConnectedFlags() {
        if (devices.length === 0) return;
        if (_enriching) return;     // already running; skip — next refresh will re-trigger
        _enriching = true;
        pairedConnectedProc.working = devices.slice();
        pairedConnectedProc.cursor = 0;
        pairedConnectedProc.command = ["bluetoothctl", "info", devices[0].mac];
        pairedConnectedProc.running = true;
    }

    function refresh() {
        showProc.running = true;
        devicesProc.running = true;
    }

    // ── setEnabled ──────────────────────────────────────────────────
    Process {
        id: powerProc
        command: ["bluetoothctl", "power", "on"]
        onExited: (code) => {
            if (code !== 0) svc.lastError = "bluetoothctl power failed";
            svc.refresh();
        }
    }

    function setEnabled(on) {
        powerProc.command = ["bluetoothctl", "power", on ? "on" : "off"];
        powerProc.running = true;
    }

    // ── scan: long-lived bluetoothctl session ───────────────────────
    Process {
        id: scanProc
        command: ["bluetoothctl"]
        stdinEnabled: true
        // Refresh periodically while scanning so newly-discovered devices
        // surface in the panel.
        onRunningChanged: scanRefreshTimer.running = running
        // If bluetoothctl exits unexpectedly (crash, external kill, or after
        // we wrote "exit"), clear the scanning flag so the UI doesn't stay stuck.
        onExited: {
            if (svc.scanning) {
                svc.scanning = false;
                scanAutoStop.stop();
            }
        }
    }

    Timer {
        id: scanRefreshTimer
        interval: 2000
        repeat: true
        onTriggered: svc.refresh()
    }

    function startScan() {
        if (scanning) return;
        scanProc.running = true;
        scanProc.write("scan on\n");
        scanning = true;
        // Auto-stop after 10s to limit battery cost.
        scanAutoStop.restart();
    }

    function stopScan() {
        if (!scanning) return;
        if (scanProc.running) {
            scanProc.write("scan off\n");
            scanProc.write("exit\n");
        }
        scanning = false;
        scanAutoStop.stop();
        refresh();
    }

    Timer {
        id: scanAutoStop
        interval: 10000
        onTriggered: svc.stopScan()
    }

    // ── pairing: interactive bluetoothctl session per attempt ───────
    Process {
        id: pairProc
        command: ["bluetoothctl"]
        stdinEnabled: true
        property string targetMac: ""

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                // Confirm-passkey prompts look like:
                //   "[agent] Confirm passkey 123456 (yes/no):"
                let m = line.match(/Confirm passkey (\d+)/);
                if (m) {
                    svc.pendingConfirmDevice = pairProc.targetMac;
                    svc.pendingConfirmCode = m[1];
                    return;
                }
                if (/Pairing successful/.test(line)) {
                    svc.lastError = "";
                    pairProc.write("trust " + pairProc.targetMac + "\n");
                    pairProc.write("exit\n");
                    svc.refresh();
                }
                if (/Failed to pair/.test(line) || /AuthenticationFailed/.test(line)) {
                    svc.lastError = "Pairing failed for " + pairProc.targetMac;
                    pairProc.write("exit\n");
                }
            }
        }

        onExited: {
            // bluetoothctl ended (either by our own "exit\n" after success/failure,
            // or unexpectedly). Clear any pending-confirm state so the UI doesn't
            // strand a dialog over a dead session.
            if (svc.pendingConfirmDevice !== "") {
                if (svc.lastError === "") svc.lastError = "Pairing process exited";
                svc.pendingConfirmDevice = "";
                svc.pendingConfirmCode = "";
            }
        }
    }

    function pair(mac) {
        // Don't start a second pairing while one is in flight — the SplitParser
        // would see confirm-passkey lines for both and mix up the codes.
        if (pairProc.running) return;
        pairProc.targetMac = mac;
        svc.pendingConfirmDevice = "";
        svc.pendingConfirmCode = "";
        pairProc.running = true;
        pairProc.write("pair " + mac + "\n");
    }

    function confirmPair(yes) {
        if (!pairProc.running) return;
        pairProc.write((yes ? "yes" : "no") + "\n");
        if (!yes) {
            pairProc.write("exit\n");
            svc.lastError = "Pairing cancelled";
        }
        svc.pendingConfirmDevice = "";
        svc.pendingConfirmCode = "";
    }

    // ── unimplemented (filled in later tasks) ──
    function trust(mac)       {}
    function connect(mac)     {}
    function disconnect(mac)  {}
    function forget(mac)      {}
    function clearError()     { lastError = ""; }

    Component.onCompleted: refresh()

    Component.onDestruction: {
        // Don't leave bluetoothctl scanning after quickshell exits.
        if (scanning) stopScan();
        // Tear down any in-flight pairing so we don't orphan a bluetoothctl agent.
        if (pairProc.running) pairProc.running = false;
    }
}
