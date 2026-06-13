import QtQuick
import QtQuick.Layouts
import ".."

// One zone (start / center / end). Renders BarConfig.resolved[zone] in order:
// a Loader per key picks the matching widget from the registry below, so a
// widget exists once, in exactly one zone, in the configured order.
//
// NB: the id is NOT `z` — `z` is Item's stacking-order property and would
// shadow the id inside child Items (Loaders), breaking `<id>.componentFor`.
GridLayout {
    id: zoneRoot
    property string zone: "start"
    property bool horizontal: false
    property var barScreen: null

    rows: horizontal ? 1 : -1
    columns: horizontal ? -1 : 1
    rowSpacing: 12
    columnSpacing: 12

    // ── Widget registry: key -> Component ──
    Component { id: cWorkspaces; Workspaces { horizontal: BarConfig.horizontal; barScreen: zoneRoot.barScreen } }
    Component { id: cClock;      Clock      { horizontal: BarConfig.horizontal } }
    Component { id: cBattery;    Battery    { horizontal: BarConfig.horizontal } }
    Component { id: cTray;       Tray       { horizontal: BarConfig.horizontal } }
    Component { id: cVolume;     Volume     { horizontal: BarConfig.horizontal } }
    Component { id: cNetwork;    Network    { horizontal: BarConfig.horizontal } }
    Component { id: cResources;  Resources  { horizontal: BarConfig.horizontal } }
    Component { id: cMedia;      Media      { horizontal: BarConfig.horizontal } }
    Component { id: cWindow;     ActiveWindow { horizontal: BarConfig.horizontal } }

    function componentFor(key) {
        switch (key) {
            case "workspaces": return cWorkspaces;
            case "clock":      return cClock;
            case "battery":    return cBattery;
            case "tray":       return cTray;
            case "volume":     return cVolume;
            case "network":    return cNetwork;
            case "resources":  return cResources;
            case "media":      return cMedia;
            case "window":     return cWindow;
        }
        return null;
    }

    Repeater {
        model: BarConfig.resolved[zoneRoot.zone]
        delegate: Loader {
            required property string modelData
            Layout.alignment: Qt.AlignCenter
            sourceComponent: zoneRoot.componentFor(modelData)
        }
    }
}
