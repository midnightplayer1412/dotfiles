import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import ".."

// Focused-window readout. The Hyprland class is a raw app id (e.g.
// "com.mitchellh.ghostty", "brave-browser"); we resolve it to the friendly
// desktop-entry name ("Ghostty", "Brave …"), falling back to a prettified id.
// Width is hard-capped and the title ellipsised so a long title can never push
// the bar's center zone off-centre.
Item {
    id: win
    property bool horizontal: false
    property int maxWidth: 200          // horizontal-bar cap before the title ellipsises

    readonly property var activeTop: Hyprland.activeToplevel
    readonly property string appClass: activeTop?.lastIpcObject?.class ?? ""
    readonly property string title: activeTop?.lastIpcObject?.title ?? ""

    readonly property var entry: appClass.length ? DesktopEntries.heuristicLookup(appClass) : null
    readonly property string appName:
        (entry && entry.name) ? entry.name
        : (win._prettify(appClass) || (title.length ? title : "Desktop"))

    // Last segment of a reverse-DNS id, dashes/underscores → spaces, capitalised.
    function _prettify(c) {
        if (!c) return "";
        let s = c.indexOf(".") >= 0 ? c.split(".").pop() : c;
        s = s.replace(/[-_]/g, " ").trim();
        return s.length ? s.charAt(0).toUpperCase() + s.slice(1) : "";
    }

    readonly property real _rowNatural:
        appText.implicitWidth + (titleText.visible ? rowL.spacing + titleText.implicitWidth : 0)

    implicitWidth:  horizontal ? Math.min(win._rowNatural, win.maxWidth)
                               : Math.min(colT.implicitWidth, BarConfig.thickness - 10)
    implicitHeight: horizontal ? rowL.implicitHeight : colT.implicitHeight

    // Horizontal: "App name — window title", title ellipsised to fit the cap.
    RowLayout {
        id: rowL
        anchors.fill: parent
        visible: win.horizontal
        spacing: 6
        Text {
            id: appText
            text: win.appName
            color: Theme.surfaceText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            elide: Text.ElideRight
            Layout.maximumWidth: win.maxWidth
        }
        Text {
            id: titleText
            visible: win.title.length > 0 && win.title !== win.appName
            text: win.title
            color: Theme.outline
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeMedium
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    // Vertical: app name only, elided to the bar width.
    Text {
        id: colT
        anchors.centerIn: parent
        visible: !win.horizontal
        width: BarConfig.thickness - 10
        text: win.appName
        color: Theme.surfaceText
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
    }
}
