pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    readonly property var list: server.trackedNotifications
    readonly property int count: server.trackedNotifications.values.length

    property var toasts: []
    property bool dnd: false

    property var times: ({})
    property bool historyOpen: false
    signal historyRequested()

    function hideToast(notification) {
        root.toasts = root.toasts.filter(n => n !== notification)
    }

    function clear() {
        [...server.trackedNotifications.values].forEach(n => n.dismiss())
    }

    function activate(notification) {
        const action = [...notification.actions].find(a => a.identifier === "default")
        if (action) action.invoke()
    }

    NotificationServer {
        id: server

        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true

        onNotification: notification => {
            notification.tracked = true
            root.times = Object.assign({}, root.times, { [notification.id]: new Date() })
            notification.closed.connect(() => root.hideToast(notification))
            if (!root.dnd)
                root.toasts = [...root.toasts, notification]
        }
    }
}
