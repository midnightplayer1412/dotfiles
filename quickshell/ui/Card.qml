import QtQuick
import QtQuick.Layouts
import ".."
import "../ui"

// Shared titled card: a Ui.Surface with an optional header (leading icon/glyph,
// title, subtitle, trailing control) and a default body slot. Generalizes the
// per-file "card with header" composites.
//
//   Ui.Card { icon: cpuIcon; title: "System"; Text { text: uptime } }
//   Ui.Card {
//       glyph: "\u{F030C}"; title: "Keyboard lighting"; subtitle: "Match your theme."
//       trailing: Component { Ui.Toggle { checked: on; onToggled: … } }
//       // …body…
//   }
//
// Body children nest directly (default property). A non-colliding alias name is
// used because the base Surface already owns a `content` default alias.
Surface {
    id: root

    default property alias cardContent: bodyCol.data

    property string icon: ""             // svg icon source (leading)
    property string glyph: ""            // OR Nerd Font glyph (leading)
    property string title: ""
    property string subtitle: ""
    property Component trailing: null     // control shown at the header's right
    property int padding: 14

    level: 1
    radius: 12
    implicitHeight: col.implicitHeight + padding * 2

    readonly property bool hasHeader: title.length > 0 || icon.length > 0 || glyph.length > 0

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.padding
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            visible: root.hasHeader
            spacing: 10

            Icon {
                visible: root.icon.length > 0
                source: root.icon
                color: Theme.primary
                size: 22
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                visible: root.glyph.length > 0
                text: root.glyph
                color: Theme.primary
                font.family: Theme.glyphFont
                font.pixelSize: 20
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    visible: root.subtitle.length > 0
                    Layout.fillWidth: true
                    text: root.subtitle
                    color: Theme.outline
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
            }

            Loader {
                active: root.trailing !== null
                sourceComponent: root.trailing
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Body — consumer children land here.
        ColumnLayout {
            id: bodyCol
            Layout.fillWidth: true
            spacing: 10
        }
    }
}
