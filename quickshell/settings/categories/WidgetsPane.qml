import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../ui" as Ui
import "../../widgets" as Widgets
import "../.."

// Widgets settings: enable each widget per surface, open its gear for the
// widget's own options, reorder the dashboard, and restore defaults. Rows are
// driven by the registry, so newly-registered widgets appear here automatically,
// and a widget's settings panel is rendered generically from its schema.
Item {
    id: pane

    // Which widget's inline settings panel is open (one at a time; "" = none).
    property string expandedId: ""

    // Screen options for the lyrics-strip monitor picker: "Primary (auto)" plus
    // every connected screen by name.
    readonly property var lyricsScreens: {
        const out = [{ key: "", label: "Primary (auto)" }];
        for (const s of Quickshell.screens) out.push({ key: s.name, label: s.name });
        return out;
    }

    Ui.ScrollView {
        anchors.fill: parent
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Widgets"; color: Theme.primary; Layout.fillWidth: true
                font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true
            }
            Ui.Button {
                kind: "ghost"; text: "Restore default layout"; fontSize: 12
                onClicked: Widgets.WidgetsConfig.restoreDefaults()
            }
        }
        Text {
            Layout.fillWidth: true
            text: "Toggle each widget on the desktop or the SUPER+W dashboard, and open the gear for a widget's own options. Drag widgets on the desktop to place them; positions are saved."
            color: Theme.surfaceText; opacity: 0.7; wrapMode: Text.WordWrap
            font.family: Theme.fontFamily; font.pixelSize: 12
        }

        // Per-widget surface toggles + settings gear.
        Rectangle {
            Layout.fillWidth: true; Layout.topMargin: 4
            radius: 12; color: Qt.darker(Theme.surface, 1.06)
            border.width: 1; border.color: Theme.outline
            implicitHeight: toggles.implicitHeight + 28

            ColumnLayout {
                id: toggles
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Text { text: "Desktop"; color: Theme.surfaceText; opacity: 0.6
                           Layout.preferredWidth: 80; horizontalAlignment: Text.AlignHCenter
                           font.family: Theme.fontFamily; font.pixelSize: 11 }
                    Text { text: "Dashboard"; color: Theme.surfaceText; opacity: 0.6
                           Layout.preferredWidth: 80; horizontalAlignment: Text.AlignHCenter
                           font.family: Theme.fontFamily; font.pixelSize: 11 }
                }

                Repeater {
                    model: Widgets.WidgetRegistry.ids
                    delegate: ColumnLayout {
                        id: wrow
                        required property var modelData
                        readonly property var rd: Widgets.WidgetsConfig.resolvedDesktop
                        readonly property var rdash: Widgets.WidgetsConfig.resolvedDashboard
                        readonly property var schema: Widgets.WidgetRegistry.descriptors[modelData].settings || []
                        readonly property bool expanded: pane.expandedId === modelData
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: Widgets.WidgetRegistry.descriptors[wrow.modelData].label
                                color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: 13
                            }
                            Ui.IconButton {
                                visible: wrow.schema.length > 0
                                Layout.alignment: Qt.AlignVCenter
                                glyph: "\u{F0493}"   // nf-md-cog
                                glyphSize: 19
                                size: 32
                                active: wrow.expanded
                                onClicked: pane.expandedId = wrow.expanded ? "" : wrow.modelData
                            }
                            Item {
                                Layout.preferredWidth: 80
                                Layout.alignment: Qt.AlignVCenter
                                implicitHeight: dtog.implicitHeight
                                Ui.Toggle {
                                    id: dtog; anchors.centerIn: parent
                                    checked: wrow.rd.enabled[wrow.modelData]
                                    onToggled: Widgets.WidgetsConfig.toggleDesktop(wrow.modelData)
                                }
                            }
                            Item {
                                Layout.preferredWidth: 80
                                Layout.alignment: Qt.AlignVCenter
                                implicitHeight: btog.implicitHeight
                                Ui.Toggle {
                                    id: btog; anchors.centerIn: parent
                                    checked: wrow.rdash.enabled[wrow.modelData]
                                    onToggled: Widgets.WidgetsConfig.toggleDashboard(wrow.modelData)
                                }
                            }
                        }

                        // Inline settings panel — rendered generically from the schema.
                        // Spans the same width as the parent rows so a field's 80px
                        // right column lines its toggle up with the row's toggles.
                        Rectangle {
                            visible: wrow.expanded && wrow.schema.length > 0
                            Layout.fillWidth: true
                            radius: 8; color: Qt.darker(Theme.surface, 1.16)
                            border.width: 1; border.color: Theme.outline
                            implicitHeight: fields.implicitHeight + 20

                            ColumnLayout {
                                id: fields
                                anchors { left: parent.left; right: parent.right; top: parent.top
                                          leftMargin: 14; rightMargin: 0; topMargin: 10 }
                                spacing: 10

                                Repeater {
                                    model: wrow.schema
                                    delegate: RowLayout {
                                        id: field
                                        required property var modelData   // the field spec
                                        readonly property string wid: wrow.modelData
                                        readonly property var f: modelData
                                        readonly property var cur: Widgets.WidgetsConfig.setting(wid, f.key)
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Text {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            text: field.f.label
                                            color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: 12
                                        }

                                        // toggle — 80px right column matching the parent row's toggles
                                        Item {
                                            visible: field.f.type === "toggle"
                                            Layout.preferredWidth: 80
                                            Layout.alignment: Qt.AlignVCenter
                                            implicitHeight: ftog.implicitHeight
                                            Ui.Toggle {
                                                id: ftog; anchors.centerIn: parent
                                                checked: field.cur === true
                                                onToggled: (v) => Widgets.WidgetsConfig.setSetting(field.wid, field.f.key, v)
                                            }
                                        }

                                        // enum — segmented buttons
                                        Row {
                                            visible: field.f.type === "enum"
                                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                            Layout.rightMargin: 14
                                            spacing: 6
                                            Repeater {
                                                model: field.f.options || []
                                                delegate: Rectangle {
                                                    required property var modelData   // { value, label }
                                                    readonly property bool sel: field.cur === modelData.value
                                                    width: 48; height: 28; radius: 6
                                                    color: sel ? Theme.primaryContainer
                                                         : ehover.hovered ? Theme.surfaceContainer
                                                         :                   Qt.darker(Theme.surface, 1.2)
                                                    border.width: sel ? 2 : 1
                                                    border.color: sel ? Theme.primary : Theme.outline
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: modelData.label
                                                        color: sel ? Theme.primary : Theme.surfaceText
                                                        font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: sel
                                                    }
                                                    HoverHandler { id: ehover }
                                                    TapHandler { onTapped: Widgets.WidgetsConfig.setSetting(field.wid, field.f.key, modelData.value) }
                                                }
                                            }
                                        }

                                        // text / number
                                        Rectangle {
                                            visible: field.f.type === "text" || field.f.type === "number"
                                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                            Layout.rightMargin: 14
                                            Layout.preferredWidth: 130; implicitHeight: 30; radius: 8
                                            color: Qt.darker(Theme.surface, 1.2)
                                            border.width: 1; border.color: Theme.outline
                                            TextInput {
                                                anchors.fill: parent; anchors.margins: 8
                                                verticalAlignment: Text.AlignVCenter
                                                clip: true
                                                color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: 13
                                                text: String(field.cur)
                                                inputMethodHints: field.f.type === "number" ? Qt.ImhFormattedNumbersOnly : Qt.ImhNone
                                                onEditingFinished: {
                                                    if (field.f.type === "number") {
                                                        const v = parseFloat(text);
                                                        if (!isNaN(v)) Widgets.WidgetsConfig.setSetting(field.wid, field.f.key, v);
                                                    } else {
                                                        Widgets.WidgetsConfig.setSetting(field.wid, field.f.key, text);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Lyrics strip — an edge-docked overlay, not a grid widget, so it gets its
        // own card using the same gear-to-expand settings pattern as the rows above.
        Rectangle {
            id: lyrCard
            Layout.fillWidth: true; Layout.topMargin: 8
            radius: 12; color: Qt.darker(Theme.surface, 1.06)
            border.width: 1; border.color: Theme.outline
            implicitHeight: lyrCol.implicitHeight + 28
            property bool expanded: false

            // Small reusable field helpers below keep each row terse.
            ColumnLayout {
                id: lyrCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                spacing: 12

                // Header: glyph + label + gear + master enable.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        text: "\u{F0387}"   // nf-md-music
                        font.family: Theme.glyphFont; font.pixelSize: 20
                        color: Theme.primary; Layout.alignment: Qt.AlignVCenter
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text {
                            text: "Lyrics strip"; color: Theme.surfaceText
                            font.family: Theme.fontFamily; font.pixelSize: 13; font.bold: true
                        }
                        Text {
                            text: "Synced lyrics docked to a screen edge while media plays."
                            color: Theme.outline; font.family: Theme.fontFamily; font.pixelSize: 11
                            Layout.fillWidth: true; wrapMode: Text.WordWrap
                        }
                    }
                    Ui.IconButton {
                        Layout.alignment: Qt.AlignVCenter
                        glyph: "\u{F0493}"   // nf-md-cog
                        glyphSize: 19; size: 32
                        active: lyrCard.expanded
                        onClicked: lyrCard.expanded = !lyrCard.expanded
                    }
                    Ui.Toggle {
                        Layout.alignment: Qt.AlignVCenter
                        checked: Widgets.LyricsConfig.enabled
                        onToggled: (v) => Widgets.LyricsConfig.set("enabled", v)
                    }
                }

                // Expanded settings — all lyrics options, grouped.
                ColumnLayout {
                    visible: lyrCard.expanded && Widgets.LyricsConfig.enabled
                    Layout.fillWidth: true
                    spacing: 10

                    // ── Placement ──────────────────────────────────
                    Text { text: "Placement"; color: Theme.primary; Layout.topMargin: 2
                           font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        Text { Layout.preferredWidth: 88; text: "Position"; color: Theme.surfaceText
                               font.family: Theme.fontFamily; font.pixelSize: 13 }
                        Repeater {
                            model: [{ key: "top", label: "Top" }, { key: "bottom", label: "Bottom" }]
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool sel: Widgets.LyricsConfig.position === modelData.key
                                Layout.fillWidth: true; Layout.preferredHeight: 32; radius: 8
                                color: Theme.surfaceContainer
                                border.width: sel ? 2 : 1; border.color: sel ? Theme.primary : Theme.outline
                                Text { anchors.centerIn: parent; text: modelData.label
                                       color: parent.sel ? Theme.primary : Theme.surfaceText
                                       font.family: Theme.fontFamily; font.pixelSize: 12 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: Widgets.LyricsConfig.set("position", modelData.key) }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        visible: Quickshell.screens.length > 1
                        Text { Layout.preferredWidth: 88; text: "Screen"; color: Theme.surfaceText
                               font.family: Theme.fontFamily; font.pixelSize: 13 }
                        Ui.Dropdown {
                            Layout.fillWidth: true
                            model: pane.lyricsScreens
                            textRole: "label"
                            currentIndex: Math.max(0, pane.lyricsScreens.findIndex(
                                e => e.key === Widgets.LyricsConfig.screenName))
                            onActivated: (i) => Widgets.LyricsConfig.set("screenName", pane.lyricsScreens[i].key)
                        }
                    }

                    // ── Appearance ─────────────────────────────────
                    Text { text: "Appearance"; color: Theme.primary; Layout.topMargin: 4
                           font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        Text { Layout.preferredWidth: 88; text: "Layout"; color: Theme.surfaceText
                               font.family: Theme.fontFamily; font.pixelSize: 13 }
                        Repeater {
                            model: [{ key: "single", label: "Single" }, { key: "triple", label: "Triple" }, { key: "scroll", label: "Scroll" }]
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool sel: Widgets.LyricsConfig.layoutMode === modelData.key
                                Layout.fillWidth: true; Layout.preferredHeight: 32; radius: 8
                                color: Theme.surfaceContainer
                                border.width: sel ? 2 : 1; border.color: sel ? Theme.primary : Theme.outline
                                Text { anchors.centerIn: parent; text: modelData.label
                                       color: parent.sel ? Theme.primary : Theme.surfaceText
                                       font.family: Theme.fontFamily; font.pixelSize: 12 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: Widgets.LyricsConfig.set("layoutMode", modelData.key) }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        Text { Layout.fillWidth: true; text: "Transparent background"; color: Theme.surfaceText
                               font.family: Theme.fontFamily; font.pixelSize: 13 }
                        Ui.Toggle {
                            checked: Widgets.LyricsConfig.background === "transparent"
                            onToggled: (v) => Widgets.LyricsConfig.set("background", v ? "transparent" : "theme")
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        Text { Layout.preferredWidth: 88; text: "Font size"; color: Theme.surfaceText
                               font.family: Theme.fontFamily; font.pixelSize: 13 }
                        Ui.Slider {
                            Layout.fillWidth: true; from: 0.8; to: 1.6; stepSize: 0.05
                            value: Widgets.LyricsConfig.fontScale
                            onMoved: (v) => Widgets.LyricsConfig.fontScale = Math.round(v * 20) / 20
                            onReleased: Widgets.LyricsConfig.save()
                        }
                        Text { Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight
                               text: Widgets.LyricsConfig.fontScale.toFixed(2) + "x"; color: Theme.outline
                               font.family: Theme.fontFamily; font.pixelSize: 12 }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        Text { Layout.preferredWidth: 88; text: "Strip height"; color: Theme.surfaceText
                               font.family: Theme.fontFamily; font.pixelSize: 13 }
                        Ui.Slider {
                            Layout.fillWidth: true; from: 0.7; to: 1.6; stepSize: 0.05
                            value: Widgets.LyricsConfig.heightScale
                            onMoved: (v) => Widgets.LyricsConfig.heightScale = Math.round(v * 20) / 20
                            onReleased: Widgets.LyricsConfig.save()
                        }
                        Text { Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight
                               text: Widgets.LyricsConfig.heightScale.toFixed(2) + "x"; color: Theme.outline
                               font.family: Theme.fontFamily; font.pixelSize: 12 }
                    }

                    // ── Lyrics source ──────────────────────────────
                    Text { text: "Lyrics source"; color: Theme.primary; Layout.topMargin: 4
                           font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        Text { Layout.fillWidth: true; text: "Use local .lrc files"; color: Theme.surfaceText
                               font.family: Theme.fontFamily; font.pixelSize: 13 }
                        Ui.Toggle {
                            checked: Widgets.LyricsConfig.useLocalFiles
                            onToggled: (v) => Widgets.LyricsConfig.set("useLocalFiles", v)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        visible: Widgets.LyricsConfig.useLocalFiles
                        Text { Layout.preferredWidth: 88; text: "Lyrics folder"; color: Theme.surfaceText
                               font.family: Theme.fontFamily; font.pixelSize: 13 }
                        Ui.TextField {
                            id: lyrDirInput
                            variant: "field"; fontSize: 13
                            Layout.fillWidth: true
                            text: Widgets.LyricsConfig.lyricsDir
                            onAccepted: Widgets.LyricsConfig.set("lyricsDir", lyrDirInput.text)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 1
                            Text { text: "Cached lyrics"; color: Theme.surfaceText
                                   font.family: Theme.fontFamily; font.pixelSize: 13 }
                            Text { text: "Wipe downloaded lyrics so the current track re-fetches."
                                   color: Theme.outline; font.family: Theme.fontFamily; font.pixelSize: 11
                                   Layout.fillWidth: true; wrapMode: Text.WordWrap }
                        }
                        Ui.Button {
                            kind: "ghost"; text: "Clear cache"; fontSize: 12
                            onClicked: Widgets.LyricsService.clearCache()
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 1
                            Text { text: "Save lyrics to disk"; color: Theme.surfaceText
                                   font.family: Theme.fontFamily; font.pixelSize: 13 }
                            Text {
                                Layout.fillWidth: true; wrapMode: Text.WordWrap
                                color: Widgets.LyricsService.saveStatus === "failed" ? Theme.error : Theme.outline
                                font.family: Theme.fontFamily; font.pixelSize: 11
                                text: Widgets.LyricsService.saveStatus === "saved" ? "Saved ✓"
                                    : Widgets.LyricsService.saveStatus === "failed" ? "Save failed"
                                    : Widgets.LyricsService.canSaveLrc ? "Write a .lrc next to the track, or into your lyrics folder."
                                    : "Play a local track, or set a lyrics folder above, to save."
                            }
                        }
                        Ui.Button {
                            kind: "ghost"; text: "Save .lrc"; fontSize: 12
                            enabled: Widgets.LyricsService.canSaveLrc
                            opacity: enabled ? 1 : 0.4
                            onClicked: Widgets.LyricsService.saveLrc()
                        }
                    }

                    // ── Behavior ───────────────────────────────────
                    Text { text: "Behavior"; color: Theme.primary; Layout.topMargin: 4
                           font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        Text { Layout.fillWidth: true; text: "Slide in/out animation"; color: Theme.surfaceText
                               font.family: Theme.fontFamily; font.pixelSize: 13 }
                        Ui.Toggle {
                            checked: Widgets.LyricsConfig.animate
                            onToggled: (v) => Widgets.LyricsConfig.set("animate", v)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        Text { Layout.fillWidth: true; text: "Auto-hide when paused"; color: Theme.surfaceText
                               font.family: Theme.fontFamily; font.pixelSize: 13 }
                        Ui.Toggle {
                            checked: Widgets.LyricsConfig.hideWhenPaused
                            onToggled: (v) => Widgets.LyricsConfig.set("hideWhenPaused", v)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        Text { Layout.fillWidth: true; text: "Show “No lyrics found”"; color: Theme.surfaceText
                               font.family: Theme.fontFamily; font.pixelSize: 13 }
                        Ui.Toggle {
                            checked: Widgets.LyricsConfig.showWhenEmpty
                            onToggled: (v) => Widgets.LyricsConfig.set("showWhenEmpty", v)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        Text { Layout.preferredWidth: 88; text: "Sync offset"; color: Theme.surfaceText
                               font.family: Theme.fontFamily; font.pixelSize: 13 }
                        Ui.Slider {
                            Layout.fillWidth: true; from: -2000; to: 2000; stepSize: 50
                            value: Widgets.LyricsConfig.offsetMs
                            onMoved: (v) => Widgets.LyricsConfig.offsetMs = Math.round(v)
                            onReleased: Widgets.LyricsConfig.save()
                        }
                        Text { Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight
                               text: (Widgets.LyricsConfig.offsetMs / 1000).toFixed(2) + "s"; color: Theme.outline
                               font.family: Theme.fontFamily; font.pixelSize: 12 }
                    }
                }
            }
        }

        // Dashboard order (drag a row to reorder).
        Rectangle {
            Layout.fillWidth: true; Layout.topMargin: 8
            radius: 12; color: Qt.darker(Theme.surface, 1.06)
            border.width: 1; border.color: Theme.outline
            implicitHeight: orderCol.implicitHeight + 28

            ColumnLayout {
                id: orderCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                spacing: 8

                Text { text: "Dashboard order"; color: Theme.primary
                       font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true }

                Text {
                    Layout.fillWidth: true
                    text: "Drag to reorder how widgets appear in the dashboard."
                    color: Theme.surfaceText; opacity: 0.7; wrapMode: Text.WordWrap
                    font.family: Theme.fontFamily; font.pixelSize: 12
                }

                // Drag-to-reorder board (same pattern as the Bar widget board):
                // stable Repeater model (registry ids), a mutable `slots` array the
                // drag mutates, rows bound to computed y so siblings reflow live.
                Item {
                    id: orderBoard
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    Layout.preferredHeight: Math.max(1, orderBoard.slots.length) * orderBoard.rowH

                    readonly property real rowH: 38
                    // Mutable order. Re-synced from config when idle; mutated freely
                    // during a drag (never rebound mid-drag, so motion isn't clobbered).
                    property var slots: []
                    property string dragKey: ""
                    property real dragY: 0
                    property real dragBaseY: 0

                    function syncSlots() {
                        if (orderBoard.dragKey !== "") return;
                        orderBoard.slots = Widgets.WidgetsConfig.resolvedDashboard.order.slice();
                    }
                    Component.onCompleted: orderBoard.syncSlots()
                    Connections {
                        target: Widgets.WidgetsConfig
                        function onResolvedDashboardChanged() { orderBoard.syncSlots() }
                    }

                    function updateDrag(ty) {
                        orderBoard.dragY = orderBoard.dragBaseY + ty;
                        const cur = orderBoard.slots.indexOf(orderBoard.dragKey);
                        if (cur < 0) return;
                        let tgt = Math.round(orderBoard.dragY / orderBoard.rowH);
                        tgt = Math.max(0, Math.min(orderBoard.slots.length - 1, tgt));
                        if (tgt !== cur) {
                            const ns = orderBoard.slots.slice();
                            ns.splice(cur, 1);
                            ns.splice(tgt, 0, orderBoard.dragKey);
                            orderBoard.slots = ns;
                        }
                    }
                    function commitDrag() {
                        if (orderBoard.dragKey === "") return;
                        const o = orderBoard.slots.slice();
                        orderBoard.dragKey = "";
                        Widgets.WidgetsConfig.setDashboardOrder(o);
                    }

                    Repeater {
                        model: Widgets.WidgetRegistry.ids
                        delegate: Rectangle {
                            id: chip
                            required property string modelData
                            readonly property int slot: orderBoard.slots.indexOf(modelData)
                            readonly property bool dragging: orderBoard.dragKey === modelData

                            visible: slot >= 0
                            x: 0
                            width: orderBoard.width
                            height: orderBoard.rowH - 6
                            y: dragging ? orderBoard.dragY : slot * orderBoard.rowH
                            z: dragging ? 10 : 1
                            radius: 8
                            color: dragging ? Theme.primary : Theme.surfaceContainer
                            border.width: 1
                            border.color: dragging ? Theme.primary : Theme.outline

                            Behavior on y { enabled: !chip.dragging; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10; anchors.rightMargin: 8
                                spacing: 6
                                Text {
                                    Layout.fillWidth: true
                                    text: Widgets.WidgetRegistry.descriptors[chip.modelData].label
                                    elide: Text.ElideRight
                                    color: chip.dragging ? Theme.primaryText : Theme.surfaceText
                                    font.family: Theme.fontFamily; font.pixelSize: 13
                                }
                                Text {
                                    text: "\u{F01DB}"   // nf-md-drag
                                    font.family: Theme.glyphFont; font.pixelSize: 15
                                    color: chip.dragging ? Theme.primaryText : Theme.outline
                                }
                            }

                            DragHandler {
                                target: null
                                xAxis.enabled: false
                                yAxis.enabled: true
                                cursorShape: Qt.ClosedHandCursor
                                onActiveChanged: {
                                    if (active) {
                                        orderBoard.dragKey = chip.modelData;
                                        orderBoard.dragBaseY = chip.slot * orderBoard.rowH;
                                        orderBoard.dragY = orderBoard.dragBaseY;
                                    } else {
                                        orderBoard.commitDrag();
                                    }
                                }
                                onActiveTranslationChanged: if (active) orderBoard.updateDrag(activeTranslation.y)
                            }
                        }
                    }
                }
            }
        }

        // Desktop placement — snap grid (resize is the widget's corner handle).
        Rectangle {
            Layout.fillWidth: true; Layout.topMargin: 8
            radius: 12; color: Qt.darker(Theme.surface, 1.06)
            border.width: 1; border.color: Theme.outline
            implicitHeight: placeCol.implicitHeight + 28

            ColumnLayout {
                id: placeCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                spacing: 12

                Text { text: "Desktop placement"; color: Theme.primary
                       font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: "Snap to grid"; color: Theme.surfaceText
                        font.family: Theme.fontFamily; font.pixelSize: 13
                    }
                    Ui.Toggle {
                        checked: Widgets.WidgetsConfig.snapEnabled
                        onToggled: (v) => { Widgets.WidgetsConfig.snapEnabled = v; Widgets.WidgetsConfig.save(); }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Text {
                        text: "Grid size"; color: Theme.surfaceText; Layout.preferredWidth: 72
                        font.family: Theme.fontFamily; font.pixelSize: 13
                    }
                    Ui.Slider {
                        Layout.fillWidth: true
                        from: Widgets.WidgetsConfig.gridMin
                        to: Widgets.WidgetsConfig.gridMax
                        stepSize: 1
                        value: Widgets.WidgetsConfig.gridSize
                        onMoved: (v) => Widgets.WidgetsConfig.gridSize = v
                        onReleased: Widgets.WidgetsConfig.save()
                    }
                    Text {
                        text: Widgets.WidgetsConfig.resolvedGridSize + " px"
                        color: Theme.surfaceText; Layout.preferredWidth: 44
                        horizontalAlignment: Text.AlignRight
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Widgets snap to this grid while dragging on the desktop. Hold Shift to place freely. Drag a widget's bottom-right corner to resize it."
                    color: Theme.surfaceText; opacity: 0.6; wrapMode: Text.WordWrap
                    font.family: Theme.fontFamily; font.pixelSize: 11
                }
            }
        }
    }
}
