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
        notification.dismiss();
    }

    function clearAll() {
        const list = server.trackedNotifications.values.slice();
        dismissedPopups.clear();
        dismissedRev++;
        for (let i = list.length - 1; i >= 0; i--) {
            list[i].dismiss();
        }
    }
}
