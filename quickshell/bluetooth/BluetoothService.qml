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
                }
            }
        }
    }

    function _enrichConnectedFlags() {
        if (devices.length === 0) return;
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

    // ── unimplemented (filled in later tasks) ──
    function startScan()      {}
    function stopScan()       {}
    function pair(mac)        {}
    function confirmPair(yes) {}
    function trust(mac)       {}
    function connect(mac)     {}
    function disconnect(mac)  {}
    function forget(mac)      {}
    function clearError()     { lastError = ""; }

    Component.onCompleted: refresh()
}
