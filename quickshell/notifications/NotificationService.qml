pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    // Full history — backed by NotificationServer's tracked list.
    readonly property alias notifications: server.trackedNotifications

    // Currently visible popup cards. Separate from history so a popup expiring
    // (5s timeout) only hides the toast, while the notification stays in the
    // drawer until explicitly dismissed.
    property var popups: []

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
            const arr = root.popups.slice();
            arr.push(notif);
            root.popups = arr;
        }
    }

    function dismissPopup(notification) {
        const arr = root.popups.slice();
        const idx = arr.indexOf(notification);
        if (idx >= 0) {
            arr.splice(idx, 1);
            root.popups = arr;
        }
    }

    function dismiss(notification) {
        dismissPopup(notification);
        if (notification) notification.dismiss();
    }

    function clearAll() {
        const list = server.trackedNotifications.values.slice();
        for (let i = list.length - 1; i >= 0; i--) {
            list[i].dismiss();
        }
        root.popups = [];
    }
}
