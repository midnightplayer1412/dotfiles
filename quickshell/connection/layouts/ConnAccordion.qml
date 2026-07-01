import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../ui" as Ui
import "../.."
import "../../wifi" as Wifi
import "../../bluetooth" as Bt
import "../../vpn" as Vpn

// Accordion connection layout: three collapsible rows (Wi-Fi / Bluetooth / VPN)
// stacked in a ColumnLayout. Tapping a header expands/collapses that section's
// detail body; the on/off Toggle (wifi/bt) sits at the right and adjusts the
// service without toggling expansion. Independent expand state per row — Wi-Fi
// is open by default. The whole stack lives in a Flickable so tall expanded
// bodies can overflow the panel.
Item {
    id: root

    // Per-section expanded state — reassigned wholesale so bindings re-evaluate.
    property var expanded: ({ wifi: true, bluetooth: false, vpn: false })
    function toggleExpanded(key) {
        var next = Object.assign({}, expanded);
        next[key] = !next[key];
        expanded = next;
    }

    readonly property var rows: [
        { key: "wifi",      comp: wifiComp },
        { key: "bluetooth", comp: btComp },
        { key: "vpn",       comp: vpnComp }
    ]

    // Each section is created inside its own row (an Item can only have one
    // parent, so — unlike the shared instances in ConnTiles — they are loaded
    // per row via a Component + Loader).
    Component { id: wifiComp; Wifi.WifiSection {} }
    Component { id: btComp;   Bt.BtSection {} }
    Component { id: vpnComp;  Vpn.VpnSection {} }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: acc.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: Ui.ScrollBar {}

        ColumnLayout {
            id: acc
            width: parent.width
            spacing: 10

            Repeater {
                model: root.rows

                delegate: Item {
                    id: entry
                    required property var modelData
                    readonly property bool exp: root.expanded[modelData.key] === true

                    // Comfortable expanded height — capped so no row hogs the
                    // panel; the section's internal ListView scrolls within it.
                    readonly property int bodyH:
                        Math.min(Math.max(bodyLoader.item ? bodyLoader.item.implicitHeight : 0, 300), 360)

                    Layout.fillWidth: true
                    Layout.preferredHeight: entryCol.implicitHeight

                    Column {
                        id: entryCol
                        width: parent.width
                        spacing: 6

                        // ── Header (clickable to expand/collapse) ──
                        Ui.Surface {
                            id: header
                            level: 1
                            radius: 12
                            width: parent.width
                            height: 56

                            // Expansion tap — declared first so it sits below the
                            // Toggle; the Toggle consumes its own clicks, and the
                            // glyph/labels/chevron are transparent to the mouse.
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleExpanded(entry.modelData.key)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 12
                                spacing: 12

                                Text {
                                    text: bodyLoader.item ? bodyLoader.item.sectionGlyph : ""
                                    font.family: Theme.glyphFont
                                    font.pixelSize: 20
                                    color: entry.exp ? Theme.primary : Theme.surfaceText
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: bodyLoader.item ? bodyLoader.item.sectionTitle : ""
                                        color: Theme.surfaceText
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: bodyLoader.item ? bodyLoader.item.sectionSummary : ""
                                        color: Theme.outline
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }

                                Ui.Toggle {
                                    visible: bodyLoader.item ? bodyLoader.item.toggleAvailable : false
                                    Layout.preferredWidth: 44
                                    Layout.preferredHeight: 24
                                    checked: bodyLoader.item ? bodyLoader.item.sectionEnabled : false
                                    onToggled: (v) => { if (bodyLoader.item) bodyLoader.item.setSectionEnabled(v); }
                                }

                                // Chevron — rotates to point up when expanded.
                                Text {
                                    text: "\u{F0140}"  // nf-md-chevron-down
                                    font.family: Theme.glyphFont
                                    font.pixelSize: 20
                                    color: Theme.outline
                                    rotation: entry.exp ? 180 : 0
                                    Behavior on rotation {
                                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                    }
                                }
                            }
                        }

                        // ── Collapsible body (clips the section as it grows) ──
                        Item {
                            id: bodyClip
                            width: parent.width
                            clip: true
                            height: entry.exp ? entry.bodyH : 0
                            Behavior on height {
                                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                            }

                            Loader {
                                id: bodyLoader
                                width: parent.width
                                // Held at full expanded height regardless of the
                                // animating clip, so the section (and its ListView)
                                // never reflows mid-animation — it is simply revealed.
                                height: entry.bodyH
                                sourceComponent: entry.modelData.comp
                            }
                        }
                    }
                }
            }
        }
    }
}
