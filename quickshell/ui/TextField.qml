import QtQuick
import QtQuick.Layouts
import ".."
import "../ui"

// Shared text input: a themed container + TextInput, with placeholder, focus
// border, optional left icon and clear button. Two variants differ only in the
// default surface tint:
//   variant: "field"  — Theme.surface        (dialogs, hex inputs)
//   variant: "search" — Theme.surfaceContainer (search bars)
//
//   Ui.TextField { placeholder: "Password"; echoMode: TextInput.Password; onAccepted: … }
//   Ui.TextField { variant: "search"; leftIconSource: findIcon; clearable: true
//                  onEdited: (t) => filter(t) }
//
// Attach key handling / focus via the exposed `input`:
//   Ui.TextField { id: sf; Keys.forwardTo: [] ... }  → use sf.input for Keys, sf.input.forceActiveFocus()
Item {
    id: root

    property string variant: "field"     // field | search
    property alias text: input.text
    property alias input: input          // the inner TextInput (for Keys, focus, selection)
    property string placeholder: ""
    property int echoMode: TextInput.Normal
    property string leftIconSource: ""   // svg icon on the left
    property string leftGlyph: ""        // OR a Nerd Font glyph on the left
    property bool clearable: false
    property int maxLength: 32767
    property bool selectByMouse: true
    property int fontSize: 13
    property string fontFamily: Theme.fontFamily
    property color accentColor: Theme.primary

    signal accepted()
    signal edited(string text)

    readonly property bool hasLeft: leftIconSource.length > 0 || leftGlyph.length > 0

    implicitHeight: 32
    implicitWidth: 160

    Rectangle {
        id: box
        anchors.fill: parent
        radius: 8
        color: root.variant === "search" ? Theme.surfaceContainer : Theme.surface
        border.width: 1
        border.color: input.activeFocus ? root.accentColor : Theme.outline
        Behavior on border.color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: root.clearable ? 4 : 10
            spacing: 6

            Icon {
                visible: root.leftIconSource.length > 0
                source: root.leftIconSource
                color: Theme.outline
                size: root.fontSize + 1
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                visible: root.leftGlyph.length > 0
                text: root.leftGlyph
                color: Theme.outline
                font.family: Theme.glyphFont
                font.pixelSize: root.fontSize + 1
                Layout.alignment: Qt.AlignVCenter
            }

            TextInput {
                id: input
                Layout.fillWidth: true
                clip: true
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.surfaceText
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                echoMode: root.echoMode
                maximumLength: root.maxLength
                selectByMouse: root.selectByMouse
                selectionColor: root.accentColor
                onAccepted: root.accepted()
                onTextChanged: root.edited(text)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text.length === 0 && root.placeholder.length > 0
                    text: root.placeholder
                    color: Theme.outline
                    font: input.font
                }
            }

            IconButton {
                visible: root.clearable && input.text.length > 0
                glyph: "\u{F0156}"          // nf-md-close
                glyphSize: root.fontSize
                size: 22
                Layout.alignment: Qt.AlignVCenter
                onClicked: { input.clear(); input.forceActiveFocus(); }
            }
        }
    }
}
