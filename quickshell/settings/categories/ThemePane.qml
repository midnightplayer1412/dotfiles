import QtQuick
import QtQuick.Layouts
import "../../ui" as Ui
import "../.."

// Appearance: pick the active style variant for each shared UI component. The
// choice is global (UiStyle) — every Ui.Toggle / Ui.Slider across the shell
// re-skins live. Each card shows a real, live preview of its variant.
Item {
    id: pane

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 14

            Text {
                text: "Appearance"
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.bold: true
            }
            Text {
                text: "Pick a style for each component — changes apply across the whole shell."
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 12
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            // ── Toggle ────────────────────────────────────────────────
            Text {
                text: "Toggle"
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
                        { key: "capsule", label: "Capsule" },
                        { key: "square",  label: "Square" },
                        { key: "notch",   label: "Notch" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool selected: Ui.UiStyle.toggle === modelData.key
                        Layout.fillWidth: true
                        Layout.preferredHeight: 78
                        radius: 10
                        color: Theme.surfaceContainer
                        border.width: selected ? 2 : 1
                        border.color: selected ? Theme.primary : Theme.outline

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 10
                            Loader {
                                Layout.alignment: Qt.AlignHCenter
                                sourceComponent: modelData.key === "square" ? pvSquare
                                               : modelData.key === "notch" ? pvNotch
                                               : pvCapsule
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.label
                                color: parent.parent.selected ? Theme.primary : Theme.surfaceText
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                            }
                        }
                        // Top-level click area (covers the preview's own MouseArea)
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { Ui.UiStyle.toggle = modelData.key; Ui.UiStyle.save(); }
                        }
                    }
                }
            }

            // ── Slider ────────────────────────────────────────────────
            Text {
                text: "Slider"
                color: Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                Layout.topMargin: 10
            }
            Repeater {
                model: [
                    { key: "thin",  label: "Thin" },
                    { key: "thick", label: "Thick" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool selected: Ui.UiStyle.slider === modelData.key
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: 10
                    color: Theme.surfaceContainer
                    border.width: selected ? 2 : 1
                    border.color: selected ? Theme.primary : Theme.outline

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 14
                        Text {
                            text: modelData.label
                            color: parent.parent.selected ? Theme.primary : Theme.surfaceText
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 48
                        }
                        Loader {
                            Layout.fillWidth: true
                            sourceComponent: modelData.key === "thick" ? pvThick : pvThin
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { Ui.UiStyle.slider = modelData.key; Ui.UiStyle.save(); }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    // ── Live preview components (shown in the cards, on-state / mid value) ──
    Component { id: pvCapsule; Ui.ToggleCapsule { checked: true } }
    Component { id: pvSquare;  Ui.ToggleSquare  { checked: true } }
    Component { id: pvNotch;   Ui.ToggleNotch   { checked: true } }
    Component { id: pvThin;    Ui.SliderThin  { value: 0.6 } }
    Component { id: pvThick;   Ui.SliderThick { value: 0.6 } }
}
