import QtQuick
import QtQuick.Layouts
import ".."

// The cheatsheet card: header + (left tabs | keyboard) + bottom detail bar.
Rectangle {
    id: widget

    readonly property int pad: 28
    readonly property int gap: 22

    // Size to content — the layout reports its intrinsic size from its children.
    implicitWidth:  content.implicitWidth + pad * 2
    implicitHeight: content.implicitHeight + pad * 2

    radius: 20
    color: Theme.surface
    border.width: 1
    border.color: Theme.outline

    // Absorb clicks so they don't reach the window's close-catcher.
    MouseArea { anchors.fill: parent; onClicked: {} }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: widget.pad
        spacing: widget.gap

        // Header
        RowLayout {
            id: header
            Layout.fillWidth: true
            Text {
                text: "Keybindings"
                font.family: Theme.fontFamily
                font.pixelSize: 26
                font.bold: true
                color: Theme.surfaceText
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "SUPER + /  ·  Esc to close"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.outline
            }
        }

        // Tabs | Keyboard
        RowLayout {
            Layout.fillWidth: true
            spacing: widget.gap

            AppTabs {
                id: tabs
                Layout.alignment: Qt.AlignTop
            }

            Keyboard {
                id: keyboard
                Layout.alignment: Qt.AlignTop
            }
        }

        // Detail bar
        DetailBar {
            id: detail
            Layout.fillWidth: true
        }
    }
}
