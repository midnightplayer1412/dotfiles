pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: svc

    property bool enabled: false
    property bool scanning: false
    property string lastError: ""
    property string pendingConfirmDevice: ""    // "" when no pairing confirmation pending
    property string pendingConfirmCode: ""
    // Each entry: { mac: string, name: string, paired: bool, connected: bool, rssi: int, icon: string }
    property var devices: []

    function setEnabled(on)      {}
    function refresh()           {}
    function startScan()         {}
    function stopScan()          {}
    function pair(mac)           {}
    function confirmPair(yes)    {}
    function trust(mac)          {}
    function connect(mac)        {}
    function disconnect(mac)     {}
    function forget(mac)         {}
    function clearError()        { lastError = ""; }
}
