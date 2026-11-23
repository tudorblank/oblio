// SPDX-License-Identifier: GPL-3.0-or-later
// Bottom dock: pinned apps, a divider, then other running apps. Window actions go
// through Hyprland (modules/windows.lua), which never moves the pointer.
// Left click: open, focus, minimize when focused, or bring back. Middle click: new
// window. Right click: menu (its windows, new window, pin to dock, quit).
// Modes: always shown, auto-hide (shows when the pointer touches the bottom edge),
// smart (hides while a window reaches into its area). Gone when it has no apps.

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

PanelWindow {
    id: root

    readonly property var pinned: Settings.opts.dockPinned
    readonly property string mode: Settings.opts.dockMode
    readonly property string minimizedWorkspace: "special:minimized"
    // proportions of the macOS dock: icons ~60% of its height, gaps ~30% of an icon
    readonly property int size: Settings.opts.dockSize
    readonly property int iconSize: Math.round(size * 0.6)
    readonly property int pad: Math.round((size - iconSize) / 2)
    readonly property int margin: 8

    readonly property bool menuOpen: menu.visible
    DockMenu { id: menu; dock: root }

    readonly property bool empty: appKeys.length === 0
    property bool hovering: false
    readonly property bool shown: !empty && (mode === "always" || hovering || menuOpen || (mode === "smart" && !covered))

    // the window spans the whole bottom edge and never resizes; only the dock itself takes input
    anchors { bottom: true; left: true; right: true }
    implicitHeight: size + margin + 48   // room above for labels
    exclusiveZone: mode === "always" && !empty ? size + margin : 0
    color: "transparent"
    WlrLayershell.namespace: "oblio-dock"
    mask: Region { item: root.empty ? nothing : root.shown ? area : edge }

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

    function hypr(code) {
        Quickshell.execDetached(["hyprctl", "dispatch", code])
    }

    function lua(list) {
        return "{ " + list.map(t => `"${address(t)}"`).join(", ") + " }"
    }

    // apps by key: pinned first, then everything else that has a window
    readonly property var apps: {
        const groups = {}
        for (const id of pinned)
            groups[id.toLowerCase()] = { id: id, pinned: true, windows: [] }
        for (const t of Hyprland.toplevels.values) {
            const id = appIdOf(t)
            if (!id) continue
            const key = id.toLowerCase()
            if (!groups[key]) groups[key] = { id: id, pinned: false, windows: [] }
            groups[key].windows.push(t)
        }
        return groups
    }
    // the icons are keyed by app, so a window opening elsewhere doesn't rebuild them
    readonly property var appKeys: Object.keys(apps)
    readonly property var pinnedKeys: appKeys.filter(k => apps[k].pinned)
    // unpinned apps in the order they were dragged to this session, new ones at the end
    property var otherOrder: []
    readonly property var otherKeys: {
        const rank = k => { const i = otherOrder.indexOf(k); return i < 0 ? 1e6 : i }
        return appKeys.filter(k => !apps[k].pinned)
            .map((k, i) => [k, i]).sort((a, b) => rank(a[0]) - rank(b[0]) || a[1] - b[1]).map(p => p[0])
    }

    // Dragging an icon rearranges it; dropping it left or right of the divider pins or unpins
    // it. With nothing pinned there is no divider: the first pin comes from the right-click menu.
    // "|" is the divider in these lists.
    readonly property var baseList: pinnedKeys.length ? pinnedKeys.concat(["|"], otherKeys) : otherKeys
    property string dragKey: ""
    property string dragIcon: ""
    property real dragX: 0
    property int dropIndex: -1
    readonly property bool dragging: dragKey !== ""
    readonly property var shownList: {
        if (!dragging) return baseList
        const list = baseList.filter(k => k !== dragKey)
        list.splice(Math.max(0, Math.min(dropIndex, list.length)), 0, dragKey)
        return list
    }
    readonly property bool dividerShown: pinnedKeys.length > 0 && (dragging || (Settings.opts.dockDivider && otherKeys.length > 0))
    readonly property Item rowItem: row

    function startDrag(key, icon, x) {
        dragKey = key
        dragIcon = icon
        dropIndex = baseList.indexOf(key)
        moveDrag(x)
    }

    // x is in the row's coordinates; the drop index is how many other slots sit left of it,
    // measured where they are drawn now (so a neighbour swaps once the pointer passes its middle)
    function moveDrag(x) {
        dragX = x
        let pos = 0, index = 0
        for (const k of shownList) {
            const w = k === "|" ? (dividerShown ? 1 : 0) : iconSize
            if (k !== dragKey && pos + w / 2 < x) index++
            if (w) pos += w + row.spacing
        }
        dropIndex = index
    }

    function endDrag(cancel) {
        if (!cancel && dragging) {
            const list = shownList
            const cut = list.indexOf("|")
            if (cut >= 0) {
                const ids = list.slice(0, cut).map(k => apps[k].id)
                if (JSON.stringify(ids) !== JSON.stringify(pinned)) Settings.set("dockPinned", ids)
            }
            otherOrder = cut >= 0 ? list.slice(cut + 1) : list
        }
        dragKey = ""
        dropIndex = -1
    }

    function click(app, entry) {
        if (app.windows.length === 0) {
            if (entry) entry.execute()
        } else {
            hypr(`function() oblio.toggle_app(${lua(app.windows)}) end`)
        }
    }

    function focusWindow(t) { hypr(`function() oblio.focus("${address(t)}") end`) }
    function quit(app)      { hypr(`function() oblio.close(${lua(app.windows)}) end`) }

    function togglePin(app) {
        const list = pinned.slice()
        const i = list.findIndex(id => id.toLowerCase() === app.id.toLowerCase())
        if (i >= 0) list.splice(i, 1)
        else list.push(app.id)
        Settings.set("dockPinned", list)
    }

    function openMenu(item) {
        menu.item = item
        menu.visible = true
    }

    // smart mode: is any window on this screen's workspace reaching into the dock's area?
    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property bool covered: {
        if (mode !== "smart" || !monitor || !monitor.activeWorkspace) return false
        const ws = monitor.activeWorkspace
        const left = screen.x + (screen.width - background.width) / 2
        const right = left + background.width
        const top = screen.y + screen.height - size - margin
        for (const t of Hyprland.toplevels.values) {
            if (t.workspace !== ws) continue
            const o = t.lastIpcObject
            if (!o || !o.at || !o.size) continue
            if (o.at[0] < right && o.at[0] + o.size[0] > left && o.at[1] + o.size[1] > top) return true
        }
        return false
    }

    // Hyprland has no event for windows being moved or resized, so smart mode asks it
    // for window positions: right after any event, and twice a second for drags
    Timer {
        running: root.mode === "smart" && !root.empty
        interval: 500
        repeat: true
        onTriggered: Hyprland.refreshToplevels()
    }
    Timer {
        id: soon
        interval: 60
        onTriggered: Hyprland.refreshToplevels()
    }
    Connections {
        target: Hyprland
        enabled: root.mode === "smart"
        function onRawEvent(event) { soon.restart() }
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                hideTimer.stop()
                root.hovering = true
            } else {
                hideTimer.restart()
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 400
        onTriggered: root.hovering = false
    }

    Item { id: nothing }

    // the dock and the gap below it, so the pointer resting on the screen edge keeps it open
    Item {
        id: area
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: background.width
        height: root.size + root.margin
    }

    // a thin strip at the bottom edge that brings a hidden dock back
    Item {
        id: edge
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: background.width
        height: 3
    }

    // frosted glass: Hyprland blurs what's behind (layer rule in windowrules.lua)
    Rectangle {
        id: background
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.shown ? parent.height - height - root.margin : parent.height + 2
        width: row.implicitWidth + root.pad * 2
        height: root.size
        radius: Math.round(height * 0.32)
        color: Theme.tint(Theme.glass, Settings.opts.dockOpacity / 100)
        border.width: 1
        border.color: Theme.border

        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        Row {
            id: row
            anchors.left: parent.left
            anchors.leftMargin: root.pad
            // icon + its running dot are centered together, not the icon alone
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -2
            spacing: Math.round(root.iconSize * 0.3)

            move: Transition { NumberAnimation { properties: "x"; duration: 180; easing.type: Easing.OutCubic } }

            Repeater {
                model: ScriptModel { values: root.shownList }

                Item {
                    id: slot
                    required property string modelData
                    readonly property bool divider: modelData === "|"
                    visible: !divider || root.dividerShown
                    width: divider ? 1 : root.iconSize
                    height: root.iconSize

                    Rectangle {
                        visible: slot.divider
                        anchors.centerIn: parent
                        width: 1
                        height: parent.height * 0.7
                        color: Theme.border
                    }

                    Loader {
                        active: !slot.divider
                        sourceComponent: DockItem {
                            key: slot.modelData
                            dock: root
                            // its place stays open while it's carried
                            opacity: root.dragKey === slot.modelData ? 0 : 1
                        }
                    }
                }
            }
        }

        // the icon being dragged, under the pointer
        Image {
            visible: root.dragging
            x: row.x + root.dragX - width / 2
            y: row.y - 6
            width: root.iconSize
            height: root.iconSize
            sourceSize: Qt.size(root.iconSize * 2, root.iconSize * 2)
            smooth: true
            mipmap: true
            scale: 1.1
            source: root.dragIcon
        }
    }
}
