// SPDX-License-Identifier: GPL-3.0-or-later
// Oblio's notification server. Each new notification is an entry: shown as a card for a while
// (notifications/Toasts.qml) unless Do Not Disturb is on (critical ones still are), and kept in the
// history the bar's bell lists, saved in the shell's state folder so it outlasts restarts, until
// removed there. Transient ones (notices like the floating mode's) are only cards.
// An entry: key, app, icon, summary, body, image, time (ms), critical, transient. While the app
// keeps its notification, live[key] is it: its actions work.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property int keep: 100              // entries the history holds
    readonly property int defaultTimeout: 7000   // how long a card stays when the app doesn't say
    readonly property int shortestTimeout: 3000

    // newest first
    readonly property var history: Array.from(store.items ?? [])
    readonly property int unread: history.filter(e => e.time > store.readAt).length
    property var toasts: []                      // entries shown as cards right now, newest first
    property var live: ({})                      // key -> the server's notification
    readonly property bool dnd: Settings.opts.notifyDnd
    // ticks while anything is listed, so "5 min ago" moves on
    property real now: Date.now()
    Timer { running: root.history.length > 0; interval: 30000; repeat: true; onTriggered: root.now = Date.now() }

    // how long an entry's card stays
    function timeout(e) {
        const t = live[e.key]?.expireTimeout ?? -1
        return t > 0 ? Math.max(t, shortestTimeout) : defaultTimeout
    }
    // its card is done: the app's notification goes too, unless its actions are still wanted
    function hideToast(key) {
        toasts = toasts.filter(e => e.key !== key)
        const n = live[key]
        if (n && (n.transient || n.actions.length === 0)) n.dismiss()
    }
    function remove(key) {
        live[key]?.dismiss()
        store.items = history.filter(e => e.key !== key)
    }
    function clear() {
        for (const e of history) live[e.key]?.dismiss()
        store.items = []
    }
    function markRead() { store.readAt = Date.now() }
    // runs an action of a live one (the default one when id is "default"); false when it's gone
    function invoke(key, id) {
        const a = live[key]?.actions.find(a => a.identifier === id)
        if (!a) return false
        a.invoke()
        hideToast(key)
        return true
    }
    function actions(key) { return (live[key]?.actions ?? []).filter(a => a.identifier !== "default") }
    function ago(e) {
        const s = (now - e.time) / 1000
        return s < 60 ? "now" : s < 3600 ? `${Math.floor(s / 60)} min ago` : Qt.formatTime(new Date(e.time), "HH:mm")
    }
    // the app's icon: what it sent, or its desktop entry's (by id, or found by the app's name)
    function icon(e) { return Apps.icon(e.icon) }

    NotificationServer {
        id: server
        keepOnReload: false
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true
            // one the app replaces takes its entry's place
            const old = Object.keys(root.live).find(k => root.live[k] === n)
            const key = old ?? Date.now().toString(36) + "-" + n.id
            const e = {
                key, time: Date.now(),
                app: n.appName || "Notification",
                icon: n.appIcon || n.desktopEntry || n.appName,
                summary: n.summary, body: n.body, image: n.image,
                critical: n.urgency === NotificationUrgency.Critical,
                transient: n.transient,
            }
            root.live = Object.assign({}, root.live, { [key]: n })
            root.now = e.time
            // pictures the app sent as data don't outlast the shell: the history keeps files only
            if (!e.transient) {
                const kept = Object.assign({}, e, { image: /^(\/|file:)/.test(e.image) ? e.image : "" })
                store.items = [kept].concat(root.history.filter(h => h.key !== key)).slice(0, root.keep)
            }
            if (!root.dnd || e.critical)
                root.toasts = [e].concat(root.toasts.filter(t => t.key !== key))
        }
    }

    // the app closed one: its card goes, its entry stays in the history
    Connections {
        target: server.trackedNotifications
        function onValuesChanged() {
            const tracked = server.trackedNotifications.values
            const l = {}
            for (const k in root.live) if (tracked.includes(root.live[k])) l[k] = root.live[k]
            root.live = l
            const kept = root.toasts.filter(e => l[e.key] !== undefined)
            if (kept.length !== root.toasts.length) root.toasts = kept
        }
    }

    FileView {
        path: Quickshell.statePath("notifications.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: store
            property var items: []
            property real readAt: 0
        }
    }
}
