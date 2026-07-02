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

    // Scrollable — five layout cards plus the Grid options overflow the fixed
    // panel height, so the content must scroll rather than spill out of bounds.
    Ui.ScrollView {
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

        // ── Grid options (only relevant to the Grid layout) ──
        // Grouped in a card; Size is a slider row, Position is a framed 3×3
        // preset picker aligned to the right so the row reads cleanly.
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 8
            visible: OverviewConfig.resolvedLayout === "grid"
            radius: 12
            color: Qt.darker(Theme.surface, 1.06)
            border.width: 1
            border.color: Theme.outline
            implicitHeight: gridOpts.implicitHeight + 28

            ColumnLayout {
                id: gridOpts
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                spacing: 14

                Text {
                    text: "Grid options"; color: Theme.primary
                    font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true
                }

                // Size
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Text {
                        text: "Size"; color: Theme.surfaceText; Layout.preferredWidth: 64
                        font.family: Theme.fontFamily; font.pixelSize: 13
                    }
                    Ui.Slider {
                        Layout.fillWidth: true
                        from: OverviewConfig.gridScaleMin
                        to: OverviewConfig.gridScaleMax
                        stepSize: 0.05
                        value: OverviewConfig.gridScale
                        onMoved: (v) => OverviewConfig.gridScale = v
                        onReleased: OverviewConfig.save()
                    }
                    Text {
                        text: Math.round(OverviewConfig.gridScale * 100) + "%"
                        color: Theme.surfaceText; Layout.preferredWidth: 42
                        horizontalAlignment: Text.AlignRight
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                }

                // Position — label left, framed 3×3 picker right; the dot in each
                // cell shows where the grid will sit.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Text {
                        text: "Position"; color: Theme.surfaceText
                        Layout.preferredWidth: 64
                        Layout.alignment: Qt.AlignVCenter
                        font.family: Theme.fontFamily; font.pixelSize: 13
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        radius: 8
                        color: Qt.darker(Theme.surface, 1.2)
                        border.width: 1
                        border.color: Theme.outline
                        implicitWidth:  posGrid.implicitWidth + 12
                        implicitHeight: posGrid.implicitHeight + 12

                        Grid {
                            id: posGrid
                            anchors.centerIn: parent
                            columns: 3
                            rowSpacing: 4
                            columnSpacing: 4
                            Repeater {
                                model: OverviewConfig.gridPositions
                                delegate: Rectangle {
                                    required property string modelData
                                    readonly property bool sel: OverviewConfig.resolvedGridPosition === modelData
                                    width: 42; height: 28; radius: 5
                                    color: sel ? Theme.primaryContainer
                                         : phover.hovered ? Theme.surfaceContainer
                                         :                  Qt.darker(Theme.surface, 1.12)
                                    border.width: sel ? 2 : 1
                                    border.color: sel ? Theme.primary : Theme.outline

                                    Rectangle {
                                        width: 11; height: 8; radius: 2
                                        color: sel ? Theme.primary : Theme.outline
                                        x: modelData.indexOf("left")  >= 0 ? 4
                                         : modelData.indexOf("right") >= 0 ? parent.width - width - 4
                                         :                                   (parent.width - width) / 2
                                        y: modelData.indexOf("top")    >= 0 ? 4
                                         : modelData.indexOf("bottom") >= 0 ? parent.height - height - 4
                                         :                                    (parent.height - height) / 2
                                    }

                                    HoverHandler { id: phover }
                                    TapHandler { onTapped: OverviewConfig.setGridPosition(modelData) }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Side panel options (only relevant to the Side layout) ──
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 8
            visible: OverviewConfig.resolvedLayout === "side"
            radius: 12
            color: Qt.darker(Theme.surface, 1.06)
            border.width: 1
            border.color: Theme.outline
            implicitHeight: sideOpts.implicitHeight + 28

            ColumnLayout {
                id: sideOpts
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                spacing: 12

                Text {
                    text: "Side panel options"; color: Theme.primary
                    font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Text {
                        text: "Position"; color: Theme.surfaceText
                        Layout.preferredWidth: 64; Layout.alignment: Qt.AlignVCenter
                        font.family: Theme.fontFamily; font.pixelSize: 13
                    }
                    Item { Layout.fillWidth: true }
                    Row {
                        spacing: 6
                        Repeater {
                            model: [
                                { key: "auto",  label: "Auto" },
                                { key: "left",  label: "Left" },
                                { key: "right", label: "Right" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool sel: OverviewConfig.resolvedSidePosition === modelData.key
                                width: 62; height: 30; radius: 6
                                color: sel ? Theme.primaryContainer
                                     : shover.hovered ? Theme.surfaceContainer
                                     :                   Qt.darker(Theme.surface, 1.12)
                                border.width: sel ? 2 : 1
                                border.color: sel ? Theme.primary : Theme.outline
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: sel ? Theme.primary : Theme.surfaceText
                                    font.family: Theme.fontFamily; font.pixelSize: 12
                                    font.bold: sel
                                }
                                HoverHandler { id: shover }
                                TapHandler { onTapped: OverviewConfig.setSidePosition(modelData.key) }
                            }
                        }
                    }
                }

                // Auto-scroll speed (drag a window near a panel edge to scroll).
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Text {
                        text: "Speed"; color: Theme.surfaceText; Layout.preferredWidth: 64
                        Layout.alignment: Qt.AlignVCenter
                        font.family: Theme.fontFamily; font.pixelSize: 13
                    }
                    Ui.Slider {
                        Layout.fillWidth: true
                        from: OverviewConfig.sideScrollMin
                        to: OverviewConfig.sideScrollMax
                        stepSize: 1
                        value: OverviewConfig.sideScrollSpeed
                        onMoved: (v) => OverviewConfig.sideScrollSpeed = v
                        onReleased: OverviewConfig.save()
                    }
                    Text {
                        text: OverviewConfig.sideScrollSpeed
                        color: Theme.surfaceText; Layout.preferredWidth: 28
                        horizontalAlignment: Text.AlignRight
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Auto docks the panel to the edge opposite your bar; drag a window near the top/bottom edge to scroll."
                    color: Theme.surfaceText; opacity: 0.7; wrapMode: Text.WordWrap
                    font.family: Theme.fontFamily; font.pixelSize: 11
                }
            }
        }
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
