import QtQuick
import QtQuick.Layouts
import "../../ui" as Ui
import "../.."

// Appearance: pick the active style variant for each shared UI component. The
// choice is global (UiStyle) — every Ui.Toggle / Ui.Slider across the shell
// re-skins live. Each card shows a real, live preview of its variant.
Item {
    id: pane

    // Validate + normalize a typed hex, then apply as the static seed color.
    function applyHex(s) {
        let h = (s || "").trim();
        if (h.length > 0 && h[0] !== "#") h = "#" + h;
        if (/^#[0-9a-fA-F]{6}$/.test(h)) ThemeConfig.setColor(h.toLowerCase());
    }

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

            // ── Theme color ───────────────────────────────────────────
            Text {
                text: "Theme color"
                color: Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                Layout.topMargin: 6
            }
            Text {
                text: "Colors normally come from your wallpaper. Turn on a static "
                    + "color to derive the whole palette from one accent instead — "
                    + "this also retints tmux, yazi, and hyprlock."
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 12
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Text {
                    Layout.fillWidth: true
                    text: "Use a static color"
                    color: Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
                Ui.Toggle {
                    checked: ThemeConfig.mode === "static"
                    onToggled: (v) => ThemeConfig.setMode(v ? "static" : "auto")
                }
            }

            // Swatches + hex, only while static.
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: false
                visible: ThemeConfig.mode === "static"
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Repeater {
                        model: ThemeConfig.presets
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool selected:
                                (ThemeConfig.color || "").toLowerCase() === modelData.toLowerCase()
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            radius: 17
                            color: modelData
                            border.width: selected ? 3 : 1
                            border.color: selected ? Theme.surfaceText : Theme.outline
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ThemeConfig.setColor(modelData)
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    // Current color preview
                    Rectangle {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        radius: 7
                        color: ThemeConfig.color
                        border.color: Theme.outline
                        border.width: 1
                    }
                    // Themed hex input (avoids the system-styled TextField)
                    Rectangle {
                        Layout.preferredWidth: 150
                        Layout.preferredHeight: 34
                        radius: 8
                        color: Theme.surfaceContainer
                        border.width: 1
                        border.color: hexInput.activeFocus ? Theme.primary : Theme.outline
                        TextInput {
                            id: hexInput
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.surfaceText
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            clip: true
                            selectByMouse: true
                            selectionColor: Theme.primary
                            text: ThemeConfig.color
                            inputMethodHints: Qt.ImhNoAutoUppercase
                            maximumLength: 7
                            onAccepted: pane.applyHex(text)
                        }
                    }
                    Text {
                        text: "Enter to apply"
                        color: Theme.outline
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                    Item { Layout.fillWidth: true }
                }
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
