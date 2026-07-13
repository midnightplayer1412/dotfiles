import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../launcher" as Launcher
import "../../ui" as Ui
import "../.."

// Launcher settings. Top: pick the overall layout (compact bar / spotlight / sidebar /
// app grid) from mockup cards. Below: controls specific to the chosen layout, then the
// shared controls (recents, max recents, web engine). All choices persist to
// LauncherConfig and apply to the launcher live.
Item {
    id: pane

    readonly property string layout: Launcher.LauncherConfig.layout

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
                text: "Choose the launcher's layout, then tune it."
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            // ── Layout ────────────────────────────────────────────────
            Text {
                text: "Layout"
                color: Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                Layout.topMargin: 6
            }
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 12
                columnSpacing: 12
                Repeater {
                    model: [
                        { key: "bar",       label: "Compact bar" },
                        { key: "spotlight", label: "Spotlight" },
                        { key: "sidebar",   label: "Edge sidebar" },
                        { key: "grid",      label: "App grid" }
                    ]
                    delegate: Rectangle {
                        id: layCard
                        required property var modelData
                        readonly property bool selected: pane.layout === modelData.key
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
                                sourceComponent: layCard.modelData.key === "bar" ? mockLayBar
                                               : layCard.modelData.key === "spotlight" ? mockLaySpotlight
                                               : layCard.modelData.key === "sidebar" ? mockLaySidebar
                                               : mockLayGrid
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: layCard.modelData.label
                                color: layCard.selected ? Theme.primary : Theme.surfaceText
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Launcher.LauncherConfig.layout = layCard.modelData.key;
                                Launcher.LauncherConfig.save();
                            }
                        }
                    }
                }
            }

            // ── Bar: position ─────────────────────────────────────────
            SegChoice {
                visible: pane.layout === "bar"
                title: "Position"
                current: Launcher.LauncherConfig.position
                options: [ { key: "bottom", label: "Bottom" }, { key: "center", label: "Center" } ]
                onPicked: (k) => { Launcher.LauncherConfig.position = k; Launcher.LauncherConfig.save(); }
            }

            // ── Spotlight: size ───────────────────────────────────────
            SegChoice {
                visible: pane.layout === "spotlight"
                title: "Size"
                current: Launcher.LauncherConfig.spotlightSize
                options: [ { key: "small", label: "Small" }, { key: "medium", label: "Medium" }, { key: "large", label: "Large" } ]
                onPicked: (k) => { Launcher.LauncherConfig.spotlightSize = k; Launcher.LauncherConfig.save(); }
            }

            // ── Sidebar: edge + width ─────────────────────────────────
            SegChoice {
                visible: pane.layout === "sidebar"
                title: "Edge"
                current: Launcher.LauncherConfig.sidebarEdge
                options: [ { key: "left", label: "Left" }, { key: "right", label: "Right" } ]
                onPicked: (k) => { Launcher.LauncherConfig.sidebarEdge = k; Launcher.LauncherConfig.save(); }
            }
            SegChoice {
                visible: pane.layout === "sidebar"
                title: "Width"
                current: Launcher.LauncherConfig.sidebarWidth
                options: [ { key: "narrow", label: "Narrow" }, { key: "medium", label: "Medium" }, { key: "wide", label: "Wide" } ]
                onPicked: (k) => { Launcher.LauncherConfig.sidebarWidth = k; Launcher.LauncherConfig.save(); }
            }

            // ── Grid: columns + icon size + labels ────────────────────
            SegChoice {
                visible: pane.layout === "grid"
                title: "Columns"
                current: Launcher.LauncherConfig.gridColumns
                options: [ { key: 5, label: "5" }, { key: 6, label: "6" }, { key: 7, label: "7" }, { key: 8, label: "8" } ]
                onPicked: (k) => { Launcher.LauncherConfig.gridColumns = k; Launcher.LauncherConfig.save(); }
            }
            SegChoice {
                visible: pane.layout === "grid"
                title: "Icon size"
                current: Launcher.LauncherConfig.gridIconSize
                options: [ { key: "small", label: "Small" }, { key: "medium", label: "Medium" }, { key: "large", label: "Large" } ]
                onPicked: (k) => { Launcher.LauncherConfig.gridIconSize = k; Launcher.LauncherConfig.save(); }
            }
            SegChoice {
                visible: pane.layout === "grid"
                title: "Labels"
                current: Launcher.LauncherConfig.gridLabels ? "on" : "off"
                options: [ { key: "on", label: "Show" }, { key: "off", label: "Hide" } ]
                onPicked: (k) => { Launcher.LauncherConfig.gridLabels = (k === "on"); Launcher.LauncherConfig.save(); }
            }

            // ── Recent apps layout (list layouts only) ────────────────
            Text {
                visible: pane.layout !== "grid"
                text: "Recent apps layout"
                color: Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                Layout.topMargin: 10
            }
            RowLayout {
                visible: pane.layout !== "grid"
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
                text: pane.layout === "grid"
                      ? "Used for search ranking (grid shows all apps on open)."
                      : "How many recent apps appear when the search box is empty."
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

    // ── Reusable segmented choice: a labelled row of equal-width pills ──
    component SegChoice: RowLayout {
        id: seg
        property string title
        property var options            // [{ key, label }]
        property var current            // matches option.key (string or int)
        signal picked(var key)

        Layout.fillWidth: true
        spacing: 10

        Text {
            text: seg.title
            color: Theme.surfaceText
            font.family: Theme.fontFamily
            font.pixelSize: 13
            Layout.preferredWidth: 78
        }
        Repeater {
            model: seg.options
            delegate: Rectangle {
                id: pill
                required property var modelData
                readonly property bool sel: seg.current === modelData.key
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 8
                color: sel ? Theme.primaryContainer : Theme.surfaceContainer
                border.width: sel ? 2 : 1
                border.color: sel ? Theme.primary : Theme.outline

                Text {
                    anchors.centerIn: parent
                    text: pill.modelData.label
                    color: pill.sel ? Theme.primary : Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: pill.sel
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: seg.picked(pill.modelData.key)
                }
            }
        }
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
    component MockScreen: Rectangle {
        radius: 6
        color: Theme.surface
        border.color: Theme.outline
        border.width: 1
    }

    // Layout mockups: a screen frame with the launcher shape in place.
    Component {
        id: mockLayBar
        MockScreen {
            Rectangle {
                width: parent.width * 0.5; height: parent.height * 0.32; radius: 3; color: Theme.primary
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom; anchors.bottomMargin: 6
            }
        }
    }
    Component {
        id: mockLaySpotlight
        MockScreen {
            Rectangle {
                width: parent.width * 0.55; height: parent.height * 0.42; radius: 3; color: Theme.primary
                anchors.centerIn: parent
            }
        }
    }
    Component {
        id: mockLaySidebar
        MockScreen {
            Rectangle {
                width: parent.width * 0.26; height: parent.height * 0.82; radius: 3; color: Theme.primary
                anchors.left: parent.left; anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
    Component {
        id: mockLayGrid
        MockScreen {
            Grid {
                anchors.centerIn: parent
                columns: 4; rowSpacing: 5; columnSpacing: 5
                Repeater {
                    model: 12
                    delegate: Rectangle { width: 9; height: 9; radius: 2; color: Theme.primary }
                }
            }
        }
    }

    // Recents-layout mockups.
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
