import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."
import "../ui" as Ui

PanelWindow {
    id: root

    required property var screen

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    color: "transparent"

    // ── App inventory (deduped, blacklisted) ──────────────────────────
    readonly property var blacklist: new Set([
        "avahi-discover", "bvnc", "bssh", "xfce4-about",
        "kcm_fcitx5", "cmake-gui", "uuctl", "imv",
    ])
    readonly property var allApps: {
        const seen = new Set();
        return DesktopEntries.applications.values.filter(app => {
            if (root.blacklist.has(app.id)) return false;
            if (seen.has(app.id)) return false;
            seen.add(app.id);
            return true;
        });
    }
    // Most-used apps (frecency) that still exist, for the Recent section/strip.
    readonly property var recentApps: {
        const byId = {};
        for (const a of root.allApps) byId[a.id] = a;
        return UsageStore.topIds(5).map(id => byId[id]).filter(Boolean);
    }

    // Wrap a DesktopEntry as a unified result row.
    function wrapApp(app) {
        return {
            name: app.name,
            icon: app.icon ?? "",
            comment: app.comment ?? "",
            isHeader: false,
            run: () => { app.execute(); UsageStore.record(app.id); }
        };
    }

    // ── Selection helpers (skip header rows) ──────────────────────────
    function resetSelection() {
        const vals = filteredModel.values;
        let idx = 0;
        while (idx < vals.length && vals[idx] && vals[idx].isHeader) idx++;
        resultsList.currentIndex = idx < vals.length ? idx : 0;
    }
    function moveSel(dir) {
        const vals = filteredModel.values;
        if (!vals.length) return;
        let idx = resultsList.currentIndex;
        do { idx += dir; } while (idx >= 0 && idx < vals.length && vals[idx] && vals[idx].isHeader);
        if (idx >= 0 && idx < vals.length) resultsList.currentIndex = idx;
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: true
        windows: [root]
        onCleared: LauncherState.close()
    }

    // Click-outside-to-close: covers the whole screen, sits behind the panel
    MouseArea {
        anchors.fill: parent
        onClicked: LauncherState.close()
    }

    Rectangle {
        id: content

        width: Theme.launcherWidth
        height: Theme.launcherHeight
        anchors.horizontalCenter: parent.horizontalCenter
        // Position is configurable (Settings → Launcher): pinned bottom, or
        // centered like a floating window. Unused anchor is left undefined.
        anchors.bottom: LauncherConfig.position === "center" ? undefined : parent.bottom
        anchors.bottomMargin: Theme.launcherMargin
        anchors.verticalCenter: LauncherConfig.position === "center" ? parent.verticalCenter : undefined
        opacity: 0

        Component.onCompleted: entryAnim.start()

        transform: Translate { id: slideTransform; y: 30 }

        ParallelAnimation {
            id: entryAnim
            NumberAnimation { target: content; property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { target: slideTransform; property: "y"; from: 30; to: 0; duration: 200; easing.type: Easing.OutCubic }
        }
        radius: Theme.launcherRadius
        color: Theme.surface
        border.color: Theme.outline
        border.width: 1
        clip: true

        // Absorb clicks on the panel's empty padding so they don't bubble to the outer click-catcher
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.launcherMargin
            spacing: 8

            // Search bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.launcherSearchHeight
                radius: Theme.launcherSearchHeight / 2
                color: Theme.surfaceContainer

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 8

                    Image {
                        source: Quickshell.iconPath("search", 16)
                        sourceSize.width: 16
                        sourceSize.height: 16
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                    }

                    TextInput {
                        id: searchInput

                        Layout.fillWidth: true
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: Theme.primary
                        clip: true
                        focus: true

                        // Reset highlight whenever the result set may have changed.
                        onTextChanged: root.resetSelection()

                        Text {
                            anchors.fill: parent
                            text: searchInput.text.startsWith("/") ? "  Type a command..."
                                : searchInput.text.startsWith("!") ? "  Type a shell command..."
                                : searchInput.text.startsWith("=") ? "  Type a calculation..."
                                : "Search applications..."
                            color: Theme.outline
                            font: searchInput.font
                            visible: !searchInput.text || searchInput.text === "/" || searchInput.text === "!" || searchInput.text === "="
                            verticalAlignment: Text.AlignVCenter
                        }

                        Keys.priority: Keys.BeforeItem
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Down
                                    || (event.key === Qt.Key_J && (event.modifiers & Qt.ControlModifier))) {
                                root.moveSel(1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Tab) {
                                if (searchInput.text.startsWith("/") && !searchInput.text.includes(" ")
                                        && resultsList.currentIndex >= 0
                                        && resultsList.currentIndex < filteredModel.values.length) {
                                    const item = filteredModel.values[resultsList.currentIndex];
                                    searchInput.text = item.name + (item.takesArgs ? " " : "");
                                    searchInput.cursorPosition = searchInput.text.length;
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up
                                    || (event.key === Qt.Key_K && (event.modifiers & Qt.ControlModifier))) {
                                root.moveSel(-1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                const vals = filteredModel.values;
                                const idx = resultsList.currentIndex;
                                if (idx >= 0 && idx < vals.length && typeof vals[idx].run === "function") {
                                    vals[idx].run();
                                    LauncherState.close();
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                LauncherState.close();
                                event.accepted = true;
                            }
                        }
                    }
                }
            }

            // Recent chip strip (chips layout, empty query only)
            ColumnLayout {
                id: chipSection
                Layout.fillWidth: true
                Layout.fillHeight: false          // take content height, don't fight the ListView
                spacing: 4
                visible: searchInput.text === ""
                         && LauncherConfig.recentsLayout === "chips"
                         && root.recentApps.length > 0

                Text {
                    text: "RECENT"
                    color: Theme.outline
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: 64
                    spacing: 8
                    Repeater {
                        model: root.recentApps
                        delegate: Rectangle {
                            required property var modelData
                            Layout.preferredWidth: 72
                            Layout.preferredHeight: 56
                            radius: 10
                            color: chipMouse.containsMouse ? Theme.surfaceContainer : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                Image {
                                    Layout.alignment: Qt.AlignHCenter
                                    property string iconName: modelData.icon ?? ""
                                    source: iconName.startsWith("/") ? iconName : Quickshell.iconPath(iconName, 32)
                                    sourceSize.width: 32; sourceSize.height: 32
                                    Layout.preferredWidth: 32; Layout.preferredHeight: 32
                                    asynchronous: true
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.maximumWidth: 64
                                    text: modelData.name
                                    color: Theme.surfaceText
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                            MouseArea {
                                id: chipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    modelData.execute();
                                    UsageStore.record(modelData.id);
                                    LauncherState.close();
                                }
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }   // left-align chips
                }
            }

            // Empty-state hint (no app matches)
            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                visible: filteredModel.noMatches
                text: "No matching apps"
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }

            // Results list
            ListView {
                id: resultsList

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.vertical: Ui.ScrollBar { visible: resultsList.contentHeight > resultsList.height + 1 }
                currentIndex: 0
                highlightMoveDuration: 100

                model: ScriptModel {
                    id: filteredModel

                    // True when an app query returned nothing (drives the hint).
                    property bool noMatches: false

                    values: {
                        const text = searchInput.text;

                        // Calculator mode
                        if (text.startsWith("=")) { filteredModel.noMatches = false; return Commands.filterCalc(text); }

                        // Command mode
                        if (text.startsWith("/")) {
                            filteredModel.noMatches = false;
                            return Commands.filter(text).map(c => {
                                const r = Object.assign({}, c);
                                r.run = () => {
                                    if (text.includes(" ")) Commands.execute(text);
                                    else Commands.execute("/" + c.match);
                                };
                                return r;
                            });
                        }

                        // Shell mode
                        if (text.startsWith("!")) {
                            filteredModel.noMatches = false;
                            return Commands.filterShell(text).map(c => {
                                const r = Object.assign({}, c);
                                r.run = () => Commands.runShell(text);
                                return r;
                            });
                        }

                        // App mode
                        const apps = root.allApps;
                        const query = text.toLowerCase().trim();

                        if (!query) {
                            filteredModel.noMatches = false;
                            const all = [...apps].sort((a, b) => a.name.localeCompare(b.name));

                            // Chips layout: recents shown in the strip above; list is all apps.
                            if (LauncherConfig.recentsLayout === "chips") {
                                return all.map(a => root.wrapApp(a));
                            }

                            // Rows layout: Recent section then All section.
                            const recents = root.recentApps;
                            const out = [];
                            if (recents.length) {
                                out.push({ isHeader: true, name: "", icon: "", comment: "", label: "RECENT" });
                                for (const a of recents) out.push(root.wrapApp(a));
                                out.push({ isHeader: true, name: "", icon: "", comment: "", label: "ALL" });
                            }
                            for (const a of all) out.push(root.wrapApp(a));
                            return out;
                        }

                        // Fuzzy match + frecency ranking.
                        const scored = [];
                        for (const a of apps) {
                            const mn = Matcher.match(query, a.name);
                            const mc = Matcher.match(query, a.comment ?? "");
                            if (!mn.hit && !mc.hit) continue;
                            const base = Math.max(mn.hit ? mn.score : 0, mc.hit ? mc.score * 0.5 : 0);
                            scored.push({ a: a, s: base + UsageStore.score(a.id) });
                        }
                        if (scored.length === 0) {
                            filteredModel.noMatches = true;
                            return [Commands.webResult(query)];
                        }
                        filteredModel.noMatches = false;
                        scored.sort((x, y) => (y.s - x.s) || x.a.name.localeCompare(y.a.name));
                        return scored.map(x => root.wrapApp(x.a));
                    }
                }

                // Reset the highlight to the first selectable row when results change.
                Connections {
                    target: filteredModel
                    function onValuesChanged() { root.resetSelection(); }
                }

                delegate: Item {
                    id: rowDelegate
                    required property var modelData
                    required property int index

                    width: resultsList.width
                    height: modelData.isHeader ? 24 : Theme.launcherItemHeight

                    // Section header row
                    Text {
                        visible: rowDelegate.modelData.isHeader === true
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: rowDelegate.modelData.label ?? ""
                        color: Theme.outline
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }

                    // Result row
                    LauncherItem {
                        visible: rowDelegate.modelData.isHeader !== true
                        width: parent.width
                        entry: rowDelegate.modelData
                        selected: rowDelegate.index === resultsList.currentIndex

                        onClicked: {
                            if (typeof rowDelegate.modelData.run === "function") rowDelegate.modelData.run();
                            LauncherState.close();
                        }
                        onHoveredChanged: {
                            if (hovered) resultsList.currentIndex = rowDelegate.index;
                        }
                    }
                }
            }
        }
    }
}
