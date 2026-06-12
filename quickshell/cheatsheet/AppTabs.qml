import QtQuick
import ".."

// Vertical tab strip — one entry per loaded app. Active tab uses the primary
// cyan→green gradient (matching the bound-key highlight).
Column {
    id: tabs
    spacing: 8

    Repeater {
        model: KeymapData.apps

        Rectangle {
            id: tab
            required property var modelData
            readonly property bool active: CheatsheetState.activeApp === modelData.id

            width: 156
            height: 46
            radius: 10
            color: active ? "transparent" : Theme.surfaceContainer
            border.width: 1
            border.color: active ? Theme.primary : Theme.outline

            gradient: active ? activeGradient : null
            Gradient {
                id: activeGradient
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.primary }
                GradientStop { position: 1.0; color: Theme.secondary }
            }

            Behavior on border.color { ColorAnimation { duration: 120 } }

            Text {
                anchors.fill: parent
                anchors.leftMargin: 14
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                text: tab.modelData.app
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: 15
                font.bold: tab.active
                color: tab.active ? Theme.primaryText : Theme.surfaceText
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: CheatsheetState.selectApp(tab.modelData.id)
            }
        }
    }
}
