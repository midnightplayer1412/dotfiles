import QtQuick
import QtQuick.Controls
import "." as Ui
import ".."

// Themed dropdown — a drop-in replacement for QtQuick Controls ComboBox that
// matches the shell (Matugen colors, rounded, Nerd Font chevron, themed popup
// list) instead of the default system style. Standardized across the shell.
//
// API mirrors ComboBox enough for our uses:
//   model        array of strings OR objects
//   textRole     when set, display modelData[textRole]
//   currentIndex selected index (updated before activated fires)
//   currentText  read-only label of the current item
//   activated(i) emitted on user selection
Item {
    id: root

    property var model: []
    property string textRole: ""
    property int currentIndex: 0
    readonly property string currentText: root._label(root.currentIndex)
    signal activated(int index)

    implicitWidth: Math.max(120, label.implicitWidth + 46)
    implicitHeight: 30

    function _label(i) {
        if (!root.model || i < 0 || i >= root.model.length) return "";
        const item = root.model[i];
        if (root.textRole !== "" && item !== null && typeof item === "object")
            return item[root.textRole];
        return item;
    }

    // ── Closed control ────────────────────────────────────────────────
    Rectangle {
        id: field
        anchors.fill: parent
        radius: 8
        color: Theme.surfaceContainer
        border.width: 1
        border.color: (mouse.containsMouse || popup.visible) ? Theme.primary : Theme.outline
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Text {
            id: label
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: chevron.left
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: root.currentText
            color: Theme.surfaceText
            font.family: Theme.fontFamily
            font.pixelSize: 13
            elide: Text.ElideRight
        }

        Text {
            id: chevron
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: popup.visible ? "\u{F0143}" : "\u{F0140}"   // chevron-up / chevron-down
            font.family: "Monaspace Argon NF"
            font.pixelSize: 16
            color: (mouse.containsMouse || popup.visible) ? Theme.primary : Theme.outline
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.visible ? popup.close() : popup.open()
        }
    }

    // ── Open list (Popup escapes any surrounding Flickable clip) ───────
    Popup {
        id: popup
        y: field.height + 4
        x: 0
        width: field.width
        padding: 4
        // Themed container — overrides Controls' default system look.
        background: Rectangle {
            radius: 8
            color: Theme.surfaceContainer
            border.color: Theme.outline
            border.width: 1
        }

        contentItem: ListView {
            id: dropList
            implicitHeight: Math.min(contentHeight, 240)
            clip: true
            readonly property bool barVisible: contentHeight > height + 1
            ScrollBar.vertical: Ui.ScrollBar { visible: dropList.barVisible }
            model: root.model
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                width: (ListView.view ? ListView.view.width : 0) - (dropList.barVisible ? Theme.scrollGutter : 0)
                height: 30
                radius: 6
                readonly property bool isCurrent: index === root.currentIndex
                color: isCurrent ? Theme.primary
                     : rowMouse.containsMouse ? Theme.primaryContainer
                     : "transparent"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: (root.textRole !== "" && row.modelData !== null
                           && typeof row.modelData === "object")
                          ? row.modelData[root.textRole] : row.modelData
                    color: row.isCurrent ? Theme.primaryText : Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentIndex = row.index;
                        root.activated(row.index);
                        popup.close();
                    }
                }
            }
        }
    }
}
