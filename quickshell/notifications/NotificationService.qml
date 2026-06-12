pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    // Full history — backed by NotificationServer's tracked list. Popups view
    // and Drawer both iterate this same model directly; no parallel array.
    readonly property alias notifications: server.trackedNotifications

    // Notifications whose popup card has already been dismissed (via 5s
    // timeout or ✕) but which remain in the history. Stored as a JS Set keyed
    // by Notification QObject identity. dismissedRev is a tickle counter so
    // bindings that read the Set re-evaluate when it mutates (Set mutations
    // don't trigger QML property change signals on their own).
    property var dismissedPopups: new Set()
    property int dismissedRev: 0

    // Do Not Disturb — when on, incoming notifications skip the popup and land
    // straight in history (still tracked). Persists only for the session.
    property bool doNotDisturb: false

    // Arrival timestamps (ms since epoch) keyed by Notification QObject identity,
    // used to render relative time on each card. nowMs ticks so those bindings
    // refresh without per-card timers.
    property var arrivalTimes: new Map()
    property double nowMs: Date.now()

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.nowMs = Date.now()
    }

    // History bucketed by app, newest-first, newest group first. JS array model
    // for the drawer — one entry per app: { key, app, items: [Notification…] }.
    readonly property var grouped: {
        const vals = server.trackedNotifications.values;
        const order = [];
        const byApp = ({});
        for (let i = vals.length - 1; i >= 0; i--) {
            const n = vals[i];
            const key = n.appName || "Notification";
            if (!(key in byApp)) {
                byApp[key] = { key: key, app: key, items: [] };
                order.push(byApp[key]);
            }
            byApp[key].items.push(n);
        }
        return order;
    }

    function relativeTime(notification) {
        const t = arrivalTimes.get(notification);
        if (t === undefined) return "";
        const s = Math.floor(Math.max(0, nowMs - t) / 1000);
        if (s < 60) return "now";
        const m = Math.floor(s / 60);
        if (m < 60) return m + "m";
        const h = Math.floor(m / 60);
        if (h < 24) return h + "h";
        return Math.floor(h / 24) + "d";
    }

    function toggleDoNotDisturb() {
        doNotDisturb = !doNotDisturb;
    }

    readonly property int activePopupCount: {
        dismissedRev;
        const items = server.trackedNotifications.values;
        let n = 0;
        for (let i = 0; i < items.length; i++) {
            if (!dismissedPopups.has(items[i])) n++;
        }
        return n;
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;
            root.arrivalTimes.set(notif, Date.now());
            // Do Not Disturb: collect into history without popping up — but let
            // critical notifications (e.g. low battery) through.
            if (root.doNotDisturb && notif.urgency !== NotificationUrgency.Critical)
                root.markPopupDismissed(notif);
        }
    }

    function markPopupDismissed(notification) {
        if (notification && !dismissedPopups.has(notification)) {
            dismissedPopups.add(notification);
            dismissedRev++;
        }
    }

    function dismiss(notification) {
        if (!notification) return;
        if (dismissedPopups.delete(notification)) dismissedRev++;
        arrivalTimes.delete(notification);
        notification.dismiss();
    }

    function invokeAction(notification, identifier) {
        if (!notification || !notification.actions) return;
        for (let i = 0; i < notification.actions.length; i++) {
            if (notification.actions[i].identifier === identifier) {
                notification.actions[i].invoke();
                // freedesktop spec: close after action unless 'resident' hint set
                if (!notification.resident) dismiss(notification);
                return;
            }
        }
    }

    function clearAll() {
        const list = server.trackedNotifications.values.slice();
        let cleared = false;
        for (let i = list.length - 1; i >= 0; i--) {
            if (list[i].urgency === NotificationUrgency.Critical) continue;
            dismissedPopups.delete(list[i]);
            arrivalTimes.delete(list[i]);
            list[i].dismiss();
            cleared = true;
        }
        if (cleared) dismissedRev++;
    }
}
