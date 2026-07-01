import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../ui" as Ui
import "../.."
import "../../wifi" as Wifi
import "../../bluetooth" as Bt
import "../../vpn" as Vpn

// Stacked connection layout: all three section panels shown at once, each with
// its own title header (the thin Wifi/Bluetooth/Vpn wrappers). Each panel wraps
// a fill-height ListView, so it gets a bounded preferred height and scrolls its
// own list; the outer Flickable scrolls between the three panels.
Item {
    id: root

    Ui.ScrollView {
        anchors.fill: parent
        spacing: 16

        Wifi.WifiPanel {
            Layout.fillWidth: true
            Layout.preferredHeight: 300
        }
        Bt.BluetoothPanel {
            Layout.fillWidth: true
            Layout.preferredHeight: 300
        }
        Vpn.VpnPanel {
            Layout.fillWidth: true
            Layout.preferredHeight: 300
        }
    }
}
