import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."
import "../ui" as Ui

// Fullscreen SUPER+TAB overview. This file owns the shared concerns —
// layershell surface, focus grab, click-outside-to-close, and keyboard handling
// (sticky HJKL nav + armed alt-tab Super-release commit). The visible layout is
// dispatched from OverviewConfig.resolvedLayout into one of the layout
// components below; each is a self-contained, self-animating Item that arranges
// its own content within this panel.
PanelWindow {
    id: root

    required property var screen

    anchors { left: true; right: true; top: true; bottom: true }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    // Both modes grab the keyboard. Sticky uses it for Escape; armed uses it to
    // catch the Super-key RELEASE in QML (Hyprland can't dispatch a bind on a
    // modifier-key release — verified). Tab cycling still runs via the Hyprland
    // submap, which fires from compositor-level binds regardless of this grab.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: Ui.Surfaces.blurNamespace

    color: "transparent"

    HyprlandFocusGrab {
        active: true
        windows: [root]
        onCleared: OverviewState.close()
    }

    // Click-outside-to-close. Layout content sits above this and absorbs its own
    // clicks (each layout swallows clicks on its background/padding).
    MouseArea {
        anchors.fill: parent
        onClicked: OverviewState.close()
    }

    // ── Layout dispatcher ────────────────────────────────────────────────
    // Loader auto-resizes each layout to fill the panel; layouts position their
    // own content (grid centers, dock docks bottom, side docks an edge, exposé
    // fills). Rebinding on OverviewConfig.resolvedLayout re-renders live when the
    // user picks a different layout in Settings while the overview is open.
    Loader {
        id: layoutLoader
        anchors.fill: parent
        sourceComponent: {
            switch (OverviewConfig.resolvedLayout) {
            case "dock":    return dockComp;
            case "expose":  return exposeComp;
            case "side":    return sideComp;
            case "mission": return missionComp;
            case "grid":
            default:        return gridComp;
            }
        }
    }

    Component {
        id: gridComp
        Item {
            anchors.fill: parent
            OverviewBackdrop {}
            OverviewWidget { }   // self-positions from OverviewConfig.gridPosition
        }
    }
    Component { id: dockComp;    OverviewDock { } }
    Component { id: exposeComp;  OverviewExpose { } }
    Component { id: sideComp;    OverviewSide { } }
    Component { id: missionComp; OverviewMission { } }

    // ── Shared keyboard handling ─────────────────────────────────────────
    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: OverviewState.altTabCancel()

        // Sticky-mode (Super+Tab) keyboard navigation: HJKL/arrows move the
        // selection to the geometrically nearest window, Enter focuses it.
        // Armed alt-tab (Super+Alt+Tab) drives its own keys via the Hyprland
        // submap + Super-release below, so bail out when armed.
        Keys.onPressed: (event) => {
            if (OverviewState.armed)
                return;
            switch (event.key) {
            case Qt.Key_H: case Qt.Key_Left:
                OverviewState.selectStep("h"); event.accepted = true; break;
            case Qt.Key_L: case Qt.Key_Right:
                OverviewState.selectStep("l"); event.accepted = true; break;
            case Qt.Key_K: case Qt.Key_Up:
                OverviewState.selectStep("k"); event.accepted = true; break;
            case Qt.Key_J: case Qt.Key_Down:
                OverviewState.selectStep("j"); event.accepted = true; break;
            case Qt.Key_Return: case Qt.Key_Enter:
                OverviewState.selectCommit(); event.accepted = true; break;
            }
        }

        // Armed alt-tab commits when Super is released. The Hyprland submap
        // consumes key PRESSES (driving Tab cycling), but RELEASES fall through
        // to this focused surface — so we catch the Super release here, which
        // Hyprland itself can't bind. Note Qt delivers the Super key as
        // Key_Meta (Super_L/R covered defensively for other keyboards).
        Keys.onReleased: (event) => {
            if (OverviewState.armed
                && (event.key === Qt.Key_Meta
                 || event.key === Qt.Key_Super_L
                 || event.key === Qt.Key_Super_R)) {
                OverviewState.altTabCommit();
                event.accepted = true;
            }
        }
    }
}
