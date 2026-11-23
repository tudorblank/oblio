// SPDX-License-Identifier: GPL-3.0-or-later
// Bottom dock: pinned apps, a divider, then other running apps. Window actions
// go through oblio.lua in Hyprland, so minimized windows land on special:minimized.

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    // desktop file ids (without .desktop)
    property var pinned: ["Alacritty", "org.kde.dolphin"]

    readonly property string minimizedWorkspace: "special:minimized"
    // proportions of the macOS dock: icons ~60% of its height, gaps ~30% of an icon
    readonly property int size: Settings.opts.dockSize
    readonly property int iconSize: Math.round(size * 0.6)
    readonly property int pad: Math.round((size - iconSize) / 2)
    readonly property int margin: 8
    readonly property bool autoHide: Settings.opts.dockAutoHide
    property bool revealed: true

    anchors.bottom: true
    implicitWidth: background.width + 200
    implicitHeight: background.height + margin + 48   // room above for labels
    exclusiveZone: autoHide ? 0 : background.height + margin
    color: "transparent"
    WlrLayershell.namespace: "oblio-dock"

    // only the dock takes clicks; when hidden, a thin strip at the bottom edge
    mask: Region { item: root.revealed ? background : edge }

    Component.onCompleted: Hyprland.refreshToplevels()
    onAutoHideChanged: revealed = !autoHide

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
    readonly property var pinnedApps: apps.filter(a => a.pinned)
    readonly property var otherApps: apps.filter(a => !a.pinned)

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

    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (hovered) {
                hideTimer.stop()
                root.revealed = true
            } else if (root.autoHide) {
                hideTimer.restart()
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 450
        onTriggered: root.revealed = false
    }

    Item {
        id: edge
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: background.width
        height: 3
    }

    // frosted glass: Hyprland blurs what's behind (layer rule in oblio-desktop.lua)
    Rectangle {
        id: background
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.revealed ? parent.height - height - root.margin : parent.height + 2
        width: row.implicitWidth + root.pad * 2
        height: root.size
        radius: Math.round(height * 0.32)
        color: Qt.rgba(0.08, 0.08, 0.09, Settings.opts.dockOpacity / 100)
        border.width: 1
        border.color: "#24ffffff"

        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        Row {
            id: row
            anchors.left: parent.left
            anchors.leftMargin: root.pad
            // icon + its running dot are centered together, not the icon alone
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -2
            spacing: Math.round(root.iconSize * 0.3)

            Repeater {
                model: root.pinnedApps
                DockItem { required property var modelData; app: modelData; dock: root }
            }

            Item {
                visible: Settings.opts.dockDivider && root.pinnedApps.length > 0 && root.otherApps.length > 0
                width: 1
                height: root.iconSize
                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: parent.height * 0.7
                    color: "#26ffffff"
                }
            }

            Repeater {
                model: root.otherApps
                DockItem { required property var modelData; app: modelData; dock: root }
            }
        }
    }
}
