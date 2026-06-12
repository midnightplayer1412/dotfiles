import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import ".."

Rectangle {
    id: root

    // Public API
    required property var notif
    property bool compact: false
    // Border color for non-critical notifications. Critical always uses Theme.error.
    property color borderColor: Theme.primary
    signal dismissRequested()

    readonly property bool hasDefaultAction: {
        if (!notif || !notif.actions) return false;
        for (let i = 0; i < notif.actions.length; i++) {
            if (notif.actions[i].identifier === "default") return true;
        }
        return false;
    }

    readonly property var chipActions: {
        if (!notif || !notif.actions) return [];
        const out = [];
        for (let i = 0; i < notif.actions.length; i++) {
            if (notif.actions[i].identifier !== "default") {
                out.push(notif.actions[i]);
            }
        }
        return out;
    }

    readonly property bool isCritical:
        notif && notif.urgency === NotificationUrgency.Critical

    // Icon size derived from compact mode
    property int iconSize: compact ? Theme.notifIconSizeCompact : Theme.notifIconSize

    readonly property int padding: compact ? Theme.notifPaddingCompact : Theme.notifPadding

    // Layout sizing — width set by parent
    implicitHeight: Math.max(
        contentColumn.implicitHeight,
        iconSize
    ) + 2 * padding

    radius: Theme.notifRadius
    color: Theme.surfaceContainer
    border.color: root.isCritical ? Theme.error : root.borderColor
    border.width: root.isCritical ? Theme.notifBorderCritical : 1

    // ── Swipe to dismiss ──────────────────────────────────────────────
    // A horizontal drag past the threshold flings the card off-screen and
    // dismisses it. DragHandler composes with the inner MouseAreas — taps still
    // hit the buttons; only a horizontal drag steals the grab. yAxis is disabled
    // so the drawer's vertical scroll keeps working. x rests at 0 in both the
    // drawer Column and the popup Item, so it's free to animate.
    property real swipeThreshold: width * 0.3
    property real _flingTo: 0

    // Clip so the content squishes cleanly while the slot collapses on dismiss.
    clip: true

    // Fade as the card is dragged away. In popups the parent owns opacity
    // (entrance animation), so this binding is overridden there — slide only.
    opacity: 1 - Math.min(0.8, Math.abs(x) / Math.max(1, width))

    DragHandler {
        id: swipe
        target: root
        xAxis.enabled: true
        yAxis.enabled: false
        cursorShape: Qt.ClosedHandCursor
        onActiveChanged: {
            if (active) {
                settleAnim.stop();
                flingAnim.stop();
                return;
            }
            if (Math.abs(root.x) > root.swipeThreshold) root.flingOut();
            else settleAnim.start();
        }
    }

    // Swipe dismiss: slide off-screen while the slot collapses, then remove —
    // one continuous motion so the cards below follow in real time.
    function flingOut() {
        _flingTo = x > 0 ? width + 24 : -(width + 24);
        flingAnim.start();
    }

    // Non-swipe dismiss (the ✕ glyph): just collapse the slot, then remove.
    function collapseDismiss() {
        collapseAnim.start();
    }

    NumberAnimation {
        id: settleAnim
        target: root
        property: "x"
        to: 0
        duration: 180
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: flingAnim
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "x"
                to: root._flingTo
                duration: 200
                easing.type: Easing.OutCubic
            }
            SequentialAnimation {
                // Let the card start moving before the gap begins closing.
                PauseAnimation { duration: 70 }
                NumberAnimation {
                    target: root
                    property: "height"
                    to: 0
                    duration: 150
                    easing.type: Easing.InOutCubic
                }
            }
        }
        ScriptAction { script: root.dismissRequested() }
    }

    SequentialAnimation {
        id: collapseAnim
        NumberAnimation {
            target: root
            property: "height"
            to: 0
            duration: 160
            easing.type: Easing.InOutCubic
        }
        ScriptAction { script: root.dismissRequested() }
    }

    Row {
        id: rowLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        spacing: Theme.notifIconGap

        Rectangle {
            id: iconSlot
            width: root.iconSize
            height: root.iconSize
            radius: Theme.notifIconRadius
            color: "transparent"
            clip: true
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: iconImage
                anchors.fill: parent
                // notif.image is the rich image hint (album art, contact photo).
                // notif.appIcon may be a theme name OR an absolute path / file: URI.
                // Theme names are existence-checked (iconPath(_, true) returns ""
                // when missing) so an unresolved name yields the letter-avatar
                // fallback below instead of a broken-icon placeholder; the app
                // name (lowercased) is tried as a second candidate.
                source: {
                    if (root.notif?.image) return root.notif.image;
                    const icon = root.notif?.appIcon;
                    if (icon) {
                        if (icon.startsWith("/") || icon.startsWith("file:")) return icon;
                        const p = Quickshell.iconPath(icon, true);
                        if (p) return p;
                    }
                    const nm = root.notif?.appName;
                    if (nm) {
                        const p2 = Quickshell.iconPath(nm.toLowerCase(), true);
                        if (p2) return p2;
                    }
                    return "";
                }
                sourceSize.width: parent.width
                sourceSize.height: parent.height
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
                cache: true
                asynchronous: true
            }

            Rectangle {
                anchors.fill: parent
                visible: iconImage.source == "" || iconImage.status === Image.Error
                radius: parent.radius
                color: Theme.primary
                Text {
                    anchors.centerIn: parent
                    text: (root.notif?.appName || "?").charAt(0).toUpperCase()
                    color: Theme.primaryText
                    font.bold: true
                    font.pixelSize: compact ? 14 : 20
                    font.family: Theme.fontFamily
                }
            }
        }

        Column {
            id: contentColumn
            width: parent.width - root.iconSize - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.notifTextGap

            // App name + dismiss row
            Item {
                width: parent.width
                height: dismissText.height

                Text {
                    anchors.left: parent.left
                    anchors.right: timeText.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.notif?.appName || "Notification"
                    color: Theme.primary
                    font.bold: true
                    font.pixelSize: compact ? 11 : 12
                    font.family: Theme.fontFamily
                    elide: Text.ElideRight
                }

                // Relative arrival time — re-reads nowMs so it ticks on its own.
                Text {
                    id: timeText
                    anchors.right: dismissText.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        NotificationService.nowMs;
                        return root.notif ? NotificationService.relativeTime(root.notif) : "";
                    }
                    color: Theme.outline
                    font.pixelSize: compact ? 10 : 11
                    font.family: Theme.fontFamily
                    visible: text.length > 0
                }

                Text {
                    id: dismissText
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\u{F0156}"   // nf-md-close
                    color: dismissMouse.containsMouse ? Theme.primary : Theme.surfaceText
                    font.family: Theme.glyphFont
                    font.pixelSize: compact ? 12 : 14

                    MouseArea {
                        id: dismissMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.collapseDismiss()
                    }
                }
            }

            // Summary + body wrapped in bodyArea so the default-action MouseArea
            // covers only this region (not the appName row or the chip Flow).
            Item {
                id: bodyArea
                width: parent.width
                height: bodyColumn.implicitHeight

                Column {
                    id: bodyColumn
                    width: parent.width
                    spacing: Theme.notifTextGap

                    Text {
                        text: root.notif?.summary || ""
                        color: Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: compact ? 13 : 14
                        font.bold: true
                        wrapMode: Text.WordWrap
                        width: parent.width
                        visible: text.length > 0
                    }

                    Text {
                        text: root.notif?.body || ""
                        color: Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: compact ? 11 : 12
                        wrapMode: Text.WordWrap
                        width: parent.width
                        visible: text.length > 0
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: root.hasDefaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: root.hasDefaultAction
                    onClicked: NotificationService.invokeAction(root.notif, "default")
                }
            }

            // Chip row — one pill per non-default action
            Flow {
                width: parent.width
                spacing: Theme.notifSectionGap
                visible: root.chipActions.length > 0

                Repeater {
                    model: root.chipActions
                    delegate: Rectangle {
                        required property var modelData
                        radius: Theme.notifChipRadius
                        color: chipMouse.containsMouse ? Theme.primary : Theme.surfaceContainer
                        border.color: Theme.primary
                        border.width: 1
                        implicitWidth: chipLabel.implicitWidth + 2 * Theme.notifChipPadding
                        implicitHeight: compact ? Theme.notifChipHeightCompact : Theme.notifChipHeight

                        Text {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: modelData.text
                            color: chipMouse.containsMouse ? Theme.primaryText : Theme.primary
                            font.pixelSize: compact ? 10 : 11
                            font.family: Theme.fontFamily
                        }

                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationService.invokeAction(root.notif, modelData.identifier)
                        }
                    }
                }
            }
        }
    }
}
