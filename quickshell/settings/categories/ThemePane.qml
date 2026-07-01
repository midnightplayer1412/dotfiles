import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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

    // Same, for the keyboard's custom-color input.
    function applyKbHex(s) {
        let h = (s || "").trim();
        if (h.length > 0 && h[0] !== "#") h = "#" + h;
        if (/^#[0-9a-fA-F]{6}$/.test(h)) KeyboardConfig.setColor(h.toLowerCase());
    }

    // Dropdown models for the Keyboard lighting card (key → display label).
    readonly property var kbColorModes: [
        { key: "theme",  label: "Follow theme" },
        { key: "custom", label: "Custom" }
    ]
    readonly property var kbEffects: [
        { key: "static",  label: "Static" },
        { key: "breathe", label: "Breathe" },
        { key: "pulse",   label: "Pulse" }
    ]
    readonly property var kbBrightnessLevels: [
        { key: "off",  label: "Off" },
        { key: "low",  label: "Low" },
        { key: "med",  label: "Medium" },
        { key: "high", label: "High" }
    ]
    readonly property var kbSpeedLevels: [
        { key: "low",  label: "Low" },
        { key: "med",  label: "Medium" },
        { key: "high", label: "High" }
    ]
    function kbIndexOf(arr, key) { return Math.max(0, arr.findIndex(e => e.key === key)); }

    // The color the keyboard will actually show, and a dim factor for the
    // preview bar so it hints at the chosen brightness.
    readonly property color kbColor: KeyboardConfig.colorMode === "custom"
        ? KeyboardConfig.color : Theme.primary
    readonly property real kbDim: ({ "off": 0.1, "low": 0.4, "med": 0.7, "high": 1.0 }[KeyboardConfig.brightness]) || 1.0

    Ui.ScrollView {
        anchors.fill: parent
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
                    // Themed hex input
                    Ui.TextField {
                        id: hexInput
                        variant: "field"
                        maxLength: 7
                        fontSize: 13
                        Layout.preferredWidth: 150
                        text: ThemeConfig.color
                        onAccepted: pane.applyHex(hexInput.text)
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

            // ── Keyboard lighting ─────────────────────────────────────
            // Grouped in a card: header + on/off, a live color preview bar
            // (dimmed to hint brightness), then constant-width dropdown rows.
            Ui.Card {
                Layout.fillWidth: true
                Layout.topMargin: 6
                glyph: "\u{F030C}"   // nf-md-keyboard
                title: "Keyboard lighting"
                subtitle: "Match the backlight to your theme."
                trailing: Component {
                    Ui.Toggle {
                        checked: KeyboardConfig.enabled
                        onToggled: (v) => KeyboardConfig.setEnabled(v)
                    }
                }

                // Live color preview bar — fades with the chosen brightness.
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    visible: KeyboardConfig.enabled
                    radius: 8
                    color: pane.kbColor
                    opacity: pane.kbDim
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                // Option rows — fixed label column + fill-width dropdowns,
                // so every dropdown is exactly the same width.
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: KeyboardConfig.enabled
                    spacing: 10

                    // Color source
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            Layout.preferredWidth: 78
                            text: "Color"
                            color: Theme.surfaceText
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                        Ui.Dropdown {
                            Layout.fillWidth: true
                            model: pane.kbColorModes
                            textRole: "label"
                            currentIndex: pane.kbIndexOf(pane.kbColorModes, KeyboardConfig.colorMode)
                            onActivated: (i) => KeyboardConfig.setColorMode(pane.kbColorModes[i].key)
                        }
                    }

                    // Custom swatches + hex (only in custom mode), indented
                    // to line up under the dropdown column.
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 88
                        visible: KeyboardConfig.colorMode === "custom"
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Repeater {
                                model: KeyboardConfig.presets
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool selected:
                                        (KeyboardConfig.color || "").toLowerCase() === modelData.toLowerCase()
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 26
                                    radius: 13
                                    color: modelData
                                    border.width: selected ? 3 : 1
                                    border.color: selected ? Theme.surfaceText : Theme.outline
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: KeyboardConfig.setColor(modelData)
                                    }
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }

                        Ui.TextField {
                            id: kbHexInput
                            variant: "field"
                            maxLength: 7
                            fontSize: 13
                            Layout.preferredWidth: 150
                            text: KeyboardConfig.color
                            onAccepted: pane.applyKbHex(kbHexInput.text)
                        }
                    }

                    // Effect
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            Layout.preferredWidth: 78
                            text: "Effect"
                            color: Theme.surfaceText
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                        Ui.Dropdown {
                            Layout.fillWidth: true
                            model: pane.kbEffects
                            textRole: "label"
                            currentIndex: pane.kbIndexOf(pane.kbEffects, KeyboardConfig.effect)
                            onActivated: (i) => KeyboardConfig.setEffect(pane.kbEffects[i].key)
                        }
                    }

                    // Brightness
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            Layout.preferredWidth: 78
                            text: "Brightness"
                            color: Theme.surfaceText
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                        Ui.Dropdown {
                            Layout.fillWidth: true
                            model: pane.kbBrightnessLevels
                            textRole: "label"
                            currentIndex: pane.kbIndexOf(pane.kbBrightnessLevels, KeyboardConfig.brightness)
                            onActivated: (i) => KeyboardConfig.setBrightness(pane.kbBrightnessLevels[i].key)
                        }
                    }

                    // Speed — only breathe responds to it.
                    RowLayout {
                        Layout.fillWidth: true
                        visible: KeyboardConfig.effect === "breathe"
                        spacing: 10
                        Text {
                            Layout.preferredWidth: 78
                            text: "Speed"
                            color: Theme.surfaceText
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                        Ui.Dropdown {
                            Layout.fillWidth: true
                            model: pane.kbSpeedLevels
                            textRole: "label"
                            currentIndex: pane.kbIndexOf(pane.kbSpeedLevels, KeyboardConfig.speed)
                            onActivated: (i) => KeyboardConfig.setSpeed(pane.kbSpeedLevels[i].key)
                        }
                    }
                }
            }

            // ── Surface style ─────────────────────────────────────────
            Text {
                text: "Surface style"
                color: Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                Layout.topMargin: 6
            }
            Text {
                text: "How panels are drawn across the shell. Glass is frosted and "
                    + "translucent; Solid is flat and opaque. Colors still come from "
                    + "your wallpaper either way."
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 12
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Repeater {
                    model: [
                        { key: "glass", label: "Glass" },
                        { key: "solid", label: "Solid" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool selected: Ui.UiStyle.surface === modelData.key
                        Layout.fillWidth: true
                        Layout.preferredHeight: 96
                        radius: 10
                        color: Theme.surfaceContainer
                        border.width: selected ? 2 : 1
                        border.color: selected ? Theme.primary : Theme.outline

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 10
                            // Live preview: a base surface with an inner card, forced
                            // to this card's preset regardless of the global choice.
                            Ui.Surface {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: 120
                                implicitHeight: 44
                                preset: modelData.key
                                level: 0
                                radius: 8
                                Ui.Surface {
                                    anchors.centerIn: parent
                                    width: 88
                                    height: 22
                                    preset: modelData.key
                                    level: 1
                                    radius: 6
                                }
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.label
                                color: parent.parent.selected ? Theme.primary : Theme.surfaceText
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { Ui.UiStyle.surface = modelData.key; Ui.UiStyle.save(); }
                        }
                    }
                }
            }
            // Real compositor backdrop blur — only meaningful for Glass.
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                opacity: Ui.UiStyle.surface === "glass" ? 1.0 : 0.4
                Text {
                    Layout.fillWidth: true
                    text: "Blur desktop behind panels"
                    color: Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
                Ui.Toggle {
                    checked: Ui.UiStyle.desktopBlur
                    onToggled: (v) => { Ui.UiStyle.desktopBlur = v; Ui.UiStyle.save(); }
                }
            }

            // ── Connection layout ─────────────────────────────────────
            Text {
                text: "Connection layout"
                color: Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                Layout.topMargin: 6
            }
            Text {
                text: "How Wi-Fi, Bluetooth, and VPN are arranged in the connection panel."
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 12
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Repeater {
                    model: [
                        { key: "tiles",     label: "Tiles",     glyph: "\u{F1119}", hint: "Toggle tiles" },
                        { key: "accordion", label: "Accordion", glyph: "\u{F0169}", hint: "Collapsible" },
                        { key: "stacked",   label: "Stacked",   glyph: "\u{F0575}", hint: "Scroll all" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool selected: Ui.UiStyle.connectionLayout === modelData.key
                        Layout.fillWidth: true
                        Layout.preferredHeight: 78
                        radius: 10
                        color: Theme.surfaceContainer
                        border.width: selected ? 2 : 1
                        border.color: selected ? Theme.primary : Theme.outline

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.glyph
                                font.family: Theme.glyphFont
                                font.pixelSize: 22
                                color: parent.parent.selected ? Theme.primary : Theme.surfaceText
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.label
                                color: parent.parent.selected ? Theme.primary : Theme.surfaceText
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.hint
                                color: Theme.outline
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { Ui.UiStyle.connectionLayout = modelData.key; Ui.UiStyle.save(); }
                        }
                    }
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

    // ── Live preview components (shown in the cards, on-state / mid value) ──
    Component { id: pvCapsule; Ui.ToggleCapsule { checked: true } }
    Component { id: pvSquare;  Ui.ToggleSquare  { checked: true } }
    Component { id: pvNotch;   Ui.ToggleNotch   { checked: true } }
    Component { id: pvThin;    Ui.SliderThin  { value: 0.6 } }
    Component { id: pvThick;   Ui.SliderThick { value: 0.6 } }
}
