import QtQuick
import ".."

// Fixed bar at the bottom of the overlay. Lists the binding(s) for the key
// currently hovered on the keyboard, or a hint when nothing is hovered. Wraps
// to multiple lines so keys with several bindings (e.g. nvim leader keys) all
// show. A bind may carry an explicit `combo` string (e.g. "Space f f" or
// "C-a |") which overrides the auto-built "mods + key" text.
Rectangle {
    id: bar

    readonly property var binds:
        CheatsheetState.hoveredSym
            ? KeymapData.bindsForKey(CheatsheetState.activeApp, CheatsheetState.hoveredSym)
            : []

    function comboText(b) {
        if (b.combo && b.combo.length) return b.combo;
        const mods = (b.mods || []);
        const prefix = mods.length ? mods.join(" + ") + " + " : "";
        return prefix + CheatsheetState.hoveredLabel;
    }

    height: 96
    radius: 12
    color: Qt.darker(Theme.surface, 1.25)
    border.width: 1
    border.color: Theme.primary

    // Hint when nothing is hovered
    Text {
        visible: bar.binds.length === 0
        anchors.centerIn: parent
        text: "Hover any highlighted key to see what it does"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.outline
    }

    // One chip + description per binding on the hovered key, wrapping as needed
    Flow {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12
        visible: bar.binds.length > 0

        Repeater {
            model: bar.binds

            Row {
                required property var modelData
                spacing: 8
                height: 30

                Rectangle {
                    radius: 7
                    color: Theme.primary
                    height: 28
                    width: comboLabel.implicitWidth + 22
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        id: comboLabel
                        anchors.centerIn: parent
                        text: bar.comboText(modelData)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                        color: Theme.primaryText
                    }
                }

                Text {
                    text: modelData.desc
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                }
            }
        }
    }
}
