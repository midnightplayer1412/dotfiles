import QtQuick
import QtQuick.Layouts
import "../../ui" as Ui
import "../.."

// Window Switcher settings: pick which layout the SUPER+TAB overview renders.
// Each card shows a small static wireframe of the layout; clicking it writes
// OverviewConfig.layout, and the overview re-renders live via its dispatcher.
Item {
    id: pane

    readonly property var cards: [
        { key: "grid",   label: "Grid" },
        { key: "dock",   label: "Dock" },
        { key: "expose", label: "Exposé" },
        { key: "side",   label: "Side panel" },
        { key: "mission", label: "Mission Control" }
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Layout"; color: Theme.primary; Layout.fillWidth: true
                font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true
            }
            Ui.Button {
                kind: "ghost"
                text: "Reset to default"
                fontSize: 12
                onClicked: OverviewConfig.resetDefaults()
            }
        }
        Text {
            Layout.fillWidth: true
            text: "Choose how the SUPER+TAB window overview is arranged. Changes apply immediately."
            color: Theme.surfaceText; opacity: 0.7; wrapMode: Text.WordWrap
            font.family: Theme.fontFamily; font.pixelSize: 12
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            columns: 2
            rowSpacing: 12
            columnSpacing: 12

            Repeater {
                model: pane.cards
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    readonly property string key: modelData.key
                    readonly property bool selected: OverviewConfig.layout === key

                    Layout.fillWidth: true
                    Layout.preferredHeight: 168
                    radius: 12
                    color: hover.hovered ? Theme.surfaceContainer : Qt.darker(Theme.surface, 1.1)
                    border.width: selected ? 2 : 1
                    border.color: selected ? Theme.primary : Theme.outline

                    Behavior on border.color { ColorAnimation { duration: 120 } }
                    Behavior on color        { ColorAnimation { duration: 100 } }

                    HoverHandler { id: hover }
                    TapHandler { onTapped: OverviewConfig.setLayout(card.key) }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        // Wireframe sketch.
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 92
                            radius: 8
                            color: "#15151f"
                            clip: true

                            Loader {
                                anchors.fill: parent
                                sourceComponent: {
                                    switch (card.key) {
                                    case "dock":    return dockSketch;
                                    case "expose":  return exposeSketch;
                                    case "side":    return sideSketch;
                                    case "mission": return missionSketch;
                                    default:        return gridSketch;
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: card.modelData.label
                                color: card.selected ? Theme.primary : Theme.surfaceText
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                                Layout.fillWidth: true
                            }
                            // Selected check.
                            Text {
                                visible: card.selected
                                text: "\u{F012C}"   // nf-md-check
                                font.family: Theme.glyphFont
                                font.pixelSize: 15
                                color: Theme.primary
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: OverviewConfig.descriptions[card.key] ?? ""
                            color: Theme.surfaceText; opacity: 0.7; wrapMode: Text.WordWrap
                            font.family: Theme.fontFamily; font.pixelSize: 11
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

    // ── Wireframe sketch components (accent = active/selected element) ──
    component Cell: Rectangle {
        color: "#242433"; border.width: 1; border.color: "#4a4a63"; radius: 3
    }
    component ActiveCell: Rectangle {
        color: "#242433"; border.width: 1; border.color: Theme.primary; radius: 3
    }
    component Tile: Rectangle {
        color: "#33415588"; border.width: 1; border.color: "#5a7a9a"; radius: 2
    }

    Component {
        id: gridSketch
        Item {
            ActiveCell { x: parent.width*0.30; y: parent.height*0.22; width: parent.width*0.16; height: parent.height*0.28
                Tile { anchors.centerIn: parent; width: parent.width*0.6; height: parent.height*0.5 } }
            Cell { x: parent.width*0.48; y: parent.height*0.22; width: parent.width*0.16; height: parent.height*0.28
                Tile { anchors.centerIn: parent; width: parent.width*0.55; height: parent.height*0.45 } }
            Cell { x: parent.width*0.30; y: parent.height*0.54; width: parent.width*0.16; height: parent.height*0.28 }
            Cell { x: parent.width*0.48; y: parent.height*0.54; width: parent.width*0.16; height: parent.height*0.28
                Tile { anchors.centerIn: parent; width: parent.width*0.6; height: parent.height*0.55 } }
        }
    }
    Component {
        id: dockSketch
        Item {
            ActiveCell { x: parent.width*0.24; y: parent.height*0.5; width: parent.width*0.16; height: parent.height*0.34
                Tile { anchors.fill: parent; anchors.margins: 3 } }
            Cell { x: parent.width*0.06; y: parent.height*0.54; width: parent.width*0.16; height: parent.height*0.30
                Tile { anchors.fill: parent; anchors.margins: 3 } }
            Cell { x: parent.width*0.42; y: parent.height*0.54; width: parent.width*0.16; height: parent.height*0.30
                Tile { anchors.fill: parent; anchors.margins: 3 } }
            Cell { x: parent.width*0.60; y: parent.height*0.54; width: parent.width*0.16; height: parent.height*0.30
                Tile { anchors.fill: parent; anchors.margins: 3 } }
            Cell { x: parent.width*0.78; y: parent.height*0.54; width: parent.width*0.15; height: parent.height*0.30
                Tile { anchors.fill: parent; anchors.margins: 3 } }
        }
    }
    Component {
        id: exposeSketch
        Item {
            Tile { x: parent.width*0.08; y: parent.height*0.14; width: parent.width*0.24; height: parent.height*0.32 }
            Tile { x: parent.width*0.38; y: parent.height*0.12; width: parent.width*0.26; height: parent.height*0.36 }
            Tile { x: parent.width*0.70; y: parent.height*0.16; width: parent.width*0.22; height: parent.height*0.28 }
            Rectangle { x: parent.width*0.12; y: parent.height*0.56; width: parent.width*0.26; height: parent.height*0.30
                color: "#33415588"; radius: 2; border.width: 1; border.color: Theme.primary }
            Tile { x: parent.width*0.44; y: parent.height*0.56; width: parent.width*0.20; height: parent.height*0.28 }
            Tile { x: parent.width*0.70; y: parent.height*0.54; width: parent.width*0.22; height: parent.height*0.32 }
        }
    }
    Component {
        id: missionSketch
        Item {
            // Top Spaces strip.
            Rectangle { x: 0; y: 0; width: parent.width; height: parent.height*0.34
                color: "#1b1b28"; border.width: 1; border.color: "#3a3a4d" }
            Cell { x: parent.width*0.18; y: parent.height*0.07; width: parent.width*0.18; height: parent.height*0.20
                Tile { anchors.centerIn: parent; width: parent.width*0.55; height: parent.height*0.5 } }
            ActiveCell { x: parent.width*0.41; y: parent.height*0.07; width: parent.width*0.18; height: parent.height*0.20
                Tile { anchors.centerIn: parent; width: parent.width*0.6; height: parent.height*0.5 } }
            Cell { x: parent.width*0.64; y: parent.height*0.07; width: parent.width*0.18; height: parent.height*0.20 }
            // Center: active space's windows spread out.
            Tile { x: parent.width*0.14; y: parent.height*0.48; width: parent.width*0.24; height: parent.height*0.34 }
            Rectangle { x: parent.width*0.42; y: parent.height*0.44; width: parent.width*0.26; height: parent.height*0.42
                color: "#33415588"; radius: 2; border.width: 1; border.color: Theme.primary }
            Tile { x: parent.width*0.72; y: parent.height*0.50; width: parent.width*0.18; height: parent.height*0.30 }
        }
    }
    Component {
        id: sideSketch
        Item {
            // Panel docked right (matches bar-left default).
            Rectangle { x: parent.width*0.62; y: 0; width: parent.width*0.38; height: parent.height
                color: "#1b1b28"; border.width: 1; border.color: "#3a3a4d" }
            ActiveCell { x: parent.width*0.66; y: parent.height*0.08; width: parent.width*0.30; height: parent.height*0.22
                Tile { anchors.centerIn: parent; width: parent.width*0.6; height: parent.height*0.5 } }
            Cell { x: parent.width*0.66; y: parent.height*0.35; width: parent.width*0.30; height: parent.height*0.22
                Tile { anchors.centerIn: parent; width: parent.width*0.5; height: parent.height*0.45 } }
            Cell { x: parent.width*0.66; y: parent.height*0.62; width: parent.width*0.30; height: parent.height*0.22 }
        }
    }
}
