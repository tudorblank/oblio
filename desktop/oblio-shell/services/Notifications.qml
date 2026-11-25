// SPDX-License-Identifier: GPL-3.0-or-later
// Oblio's notification server: apps' notifications land here. New ones show as cards
// (notifications/Toasts.qml) unless Do Not Disturb is on (critical ones still do), and all of
// them stay in the list (the bar's bell) until dismissed.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    // newest first
    readonly property var all: server.trackedNotifications.values.slice().reverse()
    property var toasts: []             // shown as cards right now
    property var arrived: ({})          // id -> when it came (ms)
    property real readAt: 0             // when the list was last opened
    readonly property int unread: all.filter(n => (arrived[n.id] ?? 0) > readAt).length
    // ticks while anything is listed, so "5 min ago" moves on
    property real now: Date.now()
    Timer { running: root.all.length > 0; interval: 30000; repeat: true; onTriggered: root.now = Date.now() }
    readonly property bool dnd: Settings.opts.notifyDnd

    function hideToast(n) {
        toasts = toasts.filter(t => t !== n)
        // a transient one isn't meant to stay in the list
        if (n.transient) n.dismiss()
    }
    function clear() { for (const n of all) n.dismiss() }
    function markRead() { readAt = Date.now() }
    function ago(n) {
        const t = arrived[n.id]
        if (!t) return ""
        const s = (now - t) / 1000
        return s < 60 ? "now" : s < 3600 ? `${Math.floor(s / 60)} min ago` : Qt.formatTime(new Date(t), "HH:mm")
    }
    // the app's icon: what it sent, or its desktop entry's (by id, or found by the app's name)
    function icon(n) { return Apps.icon(n.appIcon || n.desktopEntry || n.appName) }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true
            // carried over from before a shell reload: already seen
            if (n.lastGeneration) return
            const a = Object.assign({}, root.arrived)
            a[n.id] = Date.now()
            root.arrived = a
            root.now = Date.now()
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.toasts = [n].concat(root.toasts.filter(t => t !== n))
        }
    }

    // one closed (by the app too) leaves the cards and the arrival times
    Connections {
        target: server.trackedNotifications
        function onValuesChanged() {
            const live = server.trackedNotifications.values
            const kept = root.toasts.filter(t => live.includes(t))
            if (kept.length !== root.toasts.length) root.toasts = kept
            const a = {}
            for (const n of live) if (root.arrived[n.id] !== undefined) a[n.id] = root.arrived[n.id]
            root.arrived = a
        }
    }
}
