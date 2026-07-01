import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../launcher" as Launcher
import "../../ui" as Ui
import "../.."

// Launcher settings. Currently: pick how the empty-query "Recent" apps render —
// vertical list rows or a horizontal chip strip. Two selectable cards with small
// static mockups, mirroring the Appearance tab's card pattern. The choice
// persists to LauncherConfig and applies to the launcher live.
Item {
    id: pane

    Ui.ScrollView {
        anchors.fill: parent
        spacing: 14

            Text {
                text: "Launcher"
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.bold: true
            }
            Text {
                Layout.fillWidth: true
                text: "Choose how recent apps appear when the search box is empty."
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            // ── Position ──────────────────────────────────────────────
            Text {
                text: "Position"
                color: Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                Layout.topMargin: 6
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Repeater {
                    model: [
                        { key: "bottom", label: "Bottom" },
                        { key: "center", label: "Center" }
                    ]
                    delegate: Rectangle {
                        id: posCard
                        required property var modelData
                        readonly property bool selected: Launcher.LauncherConfig.position === modelData.key
                        Layout.fillWidth: true
                        Layout.preferredHeight: 130
                        radius: 10
                        color: Theme.surfaceContainer
                        border.width: selected ? 2 : 1
                        border.color: selected ? Theme.primary : Theme.outline

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8
                            Loader {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                sourceComponent: posCard.modelData.key === "center" ? mockPosCenter : mockPosBottom
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: posCard.modelData.label
                                color: posCard.selected ? Theme.primary : Theme.surfaceText
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Launcher.LauncherConfig.position = posCard.modelData.key;
                                Launcher.LauncherConfig.save();
                            }
                        }
                    }
                }
            }

            // ── Recent apps layout ────────────────────────────────────
            Text {
                text: "Recent apps layout"
                color: Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                Layout.topMargin: 10
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Repeater {
                    model: [
                        { key: "rows",  label: "List rows" },
                        { key: "chips", label: "Chip strip" }
                    ]
                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        readonly property bool selected: Launcher.LauncherConfig.recentsLayout === modelData.key
                        Layout.fillWidth: true
                        Layout.preferredHeight: 160
                        radius: 10
                        color: Theme.surfaceContainer
                        border.width: selected ? 2 : 1
                        border.color: selected ? Theme.primary : Theme.outline

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Loader {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                sourceComponent: card.modelData.key === "chips" ? mockChips : mockRows
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: card.modelData.label
                                color: card.selected ? Theme.primary : Theme.surfaceText
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Launcher.LauncherConfig.recentsLayout = card.modelData.key;
                                Launcher.LauncherConfig.save();
                            }
                        }
                    }
                }
            }

            // ── Recent apps count ─────────────────────────────────────
            Text {
                text: "Recent apps shown"
                color: Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                Layout.topMargin: 10
            }
            Text {
                Layout.fillWidth: true
                text: "How many recent apps appear when the search box is empty."
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Text {
                    text: "Max items"
                    color: Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    Layout.preferredWidth: 70
                }
                Ui.Slider {
                    Layout.fillWidth: true
                    from: 1; to: 10; stepSize: 1
                    value: Launcher.LauncherConfig.maxRecents
                    onMoved: (v) => Launcher.LauncherConfig.maxRecents = v
                    onReleased: Launcher.LauncherConfig.save()
                }
                Text {
                    text: Launcher.LauncherConfig.maxRecents
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 20
                }
            }

            // ── Web search engine ─────────────────────────────────────
            Text {
                text: "Web search engine"
                color: Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                Layout.topMargin: 10
            }
            Text {
                Layout.fillWidth: true
                text: "Used when a search matches no app (the “Search the web” result)."
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Text {
                    text: "Engine"
                    color: Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    Layout.fillWidth: true
                }
                Ui.Dropdown {
                    Layout.preferredWidth: 180
                    textRole: "label"
                    model: Launcher.LauncherConfig.engines
                    currentIndex: {
                        const k = Launcher.LauncherConfig.searchEngine;
                        const es = Launcher.LauncherConfig.engines;
                        for (let i = 0; i < es.length; i++) if (es[i].key === k) return i;
                        return 0;
                    }
                    onActivated: (i) => {
                        Launcher.LauncherConfig.searchEngine = Launcher.LauncherConfig.engines[i].key;
                        Launcher.LauncherConfig.save();
                    }
                }
            }

            Item { Layout.fillHeight: true }
    }

    // ── Static layout mockups shown inside the cards ──────────────────
    component MockLabel: Rectangle {
        Layout.preferredHeight: 6
        radius: 3
        color: Theme.outline
        opacity: 0.6
    }
    component MockRow: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 14
        radius: 4
        color: Theme.surface
    }

    // Position mockups: a screen frame with the launcher box placed bottom/center.
    component MockScreen: Rectangle {
        radius: 6
        color: Theme.surface
        border.color: Theme.outline
        border.width: 1
    }

    Component {
        id: mockPosBottom
        MockScreen {
            Rectangle {
                width: parent.width * 0.6; height: 12; radius: 3; color: Theme.primary
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
            }
        }
    }
    Component {
        id: mockPosCenter
        MockScreen {
            Rectangle {
                width: parent.width * 0.6; height: 12; radius: 3; color: Theme.primary
                anchors.centerIn: parent
            }
        }
    }

    Component {
        id: mockRows
        ColumnLayout {
            spacing: 4
            MockLabel { Layout.preferredWidth: 40 }
            MockRow {
                Rectangle { width: 8; height: 8; radius: 4; color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 4 }
            }
            MockRow {
                Rectangle { width: 8; height: 8; radius: 4; color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 4 }
            }
            MockLabel { Layout.preferredWidth: 28; Layout.topMargin: 2 }
            MockRow {}
            MockRow {}
        }
    }

    Component {
        id: mockChips
        ColumnLayout {
            spacing: 6
            MockLabel { Layout.preferredWidth: 40 }
            RowLayout {
                spacing: 6
                Repeater {
                    model: 4
                    delegate: Rectangle {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        radius: 6
                        color: Theme.surface
                        Rectangle { width: 12; height: 12; radius: 6; color: Theme.primary; anchors.centerIn: parent }
                    }
                }
                Item { Layout.fillWidth: true }
            }
            MockLabel { Layout.preferredWidth: 28; Layout.topMargin: 2 }
            MockRow {}
            MockRow {}
        }
    }
}
