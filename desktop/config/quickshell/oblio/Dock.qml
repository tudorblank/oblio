// SPDX-License-Identifier: GPL-3.0-or-later
// Bottom dock: pinned apps, then running apps. Window actions go through
// oblio.lua in Hyprland, so minimized windows land on special:minimized.

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    // desktop file ids (without .desktop)
    property var pinned: ["Alacritty", "org.kde.dolphin"]

    readonly property string minimizedWorkspace: "special:minimized"

    anchors.bottom: true
    implicitWidth: background.width + 40
    implicitHeight: 84
    exclusiveZone: 66
    color: "transparent"
    WlrLayershell.namespace: "oblio-dock"

    // only the dock itself takes clicks, not the empty space above it
    mask: Region { item: background }

    Component.onCompleted: Hyprland.refreshToplevels()

    function appIdOf(t) {
        if (t.wayland && t.wayland.appId) return t.wayland.appId
        const ipc = t.lastIpcObject
        return ipc && ipc.class ? ipc.class : ""
    }

    function isMinimized(t) {
        return t.workspace !== null && t.workspace.name === minimizedWorkspace
    }

    function address(t) {
        return t.address.startsWith("0x") ? t.address : "0x" + t.address
    }

    function hypr(lua) {
        Quickshell.execDetached(["hyprctl", "dispatch", lua])
    }

    function minimize(t) { hypr(`function() oblio.minimize("${address(t)}") end`) }
    function restore(t)  { hypr(`function() oblio.restore("${address(t)}") end`) }
    function focus(t)    { hypr(`hl.dsp.focus({ window = "address:${address(t)}" })`) }

    // pinned apps first, then everything else that has a window, grouped by app
    readonly property var apps: {
        const groups = {}
        const order = []
        for (const id of pinned) {
            groups[id.toLowerCase()] = { id: id, pinned: true, windows: [] }
            order.push(id.toLowerCase())
        }
        for (const t of Hyprland.toplevels.values) {
            const id = appIdOf(t)
            if (!id) continue
            const key = id.toLowerCase()
            if (!groups[key]) {
                groups[key] = { id: id, pinned: false, windows: [] }
                order.push(key)
            }
            groups[key].windows.push(t)
        }
        return order.map(k => groups[k])
    }

    function activate(app, entry) {
        const wins = app.windows
        if (wins.length === 0) {
            if (entry) entry.execute()
            return
        }
        const minimized = wins.filter(isMinimized)
        if (minimized.length > 0) {
            restore(minimized[minimized.length - 1])
            return
        }
        const active = wins.find(t => t.activated)
        if (active) minimize(active)
        else focus(wins[0])
    }

    // right click: minimize all of the app's windows, or bring them all back
    function toggleAll(app) {
        const visible = app.windows.filter(t => !isMinimized(t))
        if (visible.length > 0) visible.forEach(minimize)
        else app.windows.forEach(restore)
    }

    Rectangle {
        id: background
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        width: row.implicitWidth + 20
        height: 60
        radius: 18
        color: "#cc141414"
        border.color: "#26ffffff"
        border.width: 1

        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: root.apps

                DockItem {
                    required property var modelData
                    app: modelData
                    dock: root
                }
            }
        }
    }
}
