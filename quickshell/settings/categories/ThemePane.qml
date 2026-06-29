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

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight
        clip: true
        ScrollBar.vertical: Ui.ScrollBar { visible: flick.contentHeight > flick.height + 1 }
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            // Leave a gutter on the right so the scrollbar sits clear of the content
            // (8px bar + breathing room) instead of hugging its edge.
            width: parent.width - 24
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

            // ── Keyboard lighting ─────────────────────────────────────
            // Grouped in a card: header + on/off, a live color preview bar
            // (dimmed to hint brightness), then constant-width dropdown rows.
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 6
                radius: 12
                color: Theme.surfaceContainer
                border.width: 1
                border.color: Theme.outline
                implicitHeight: kbCard.implicitHeight + 28

                ColumnLayout {
                    id: kbCard
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    spacing: 12

                    // Header — keyboard glyph, title/subtitle, master toggle.
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            text: "\u{F030C}"   // nf-md-keyboard
                            color: Theme.primary
                            font.family: "Monaspace Argon NF"
                            font.pixelSize: 20
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                text: "Keyboard lighting"
                                color: Theme.surfaceText
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                            }
                            Text {
                                text: "Match the backlight to your theme."
                                color: Theme.outline
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                        }
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

                            Rectangle {
                                Layout.preferredWidth: 150
                                Layout.preferredHeight: 32
                                radius: 8
                                color: Theme.surface
                                border.width: 1
                                border.color: kbHexInput.activeFocus ? Theme.primary : Theme.outline
                                TextInput {
                                    id: kbHexInput
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
                                    text: KeyboardConfig.color
                                    inputMethodHints: Qt.ImhNoAutoUppercase
                                    maximumLength: 7
                                    onAccepted: pane.applyKbHex(text)
                                }
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
