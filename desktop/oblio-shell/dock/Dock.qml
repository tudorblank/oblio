// SPDX-License-Identifier: GPL-3.0-or-later
// The dock, an edge panel (edges/EdgePanel.qml: space, shape, look, showing): pinned apps, a
// divider, then other running apps. Window actions go through Hyprland (modules/windows.lua),
// which never moves the pointer. Left click: open, focus, minimize when focused, or bring back.
// Middle click: new window. Right click: menu (its windows, new window, pin to dock, quit).
// Gone when it has no apps. Works on any edge.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.edges

EdgePanel {
    id: root

    prefix: "dock"
    // proportions of the macOS dock: icons ~60% of its thickness, gaps ~30% of an icon
    readonly property int iconSize: Math.round(thickness * 0.6)
    readonly property int pad: Math.round((thickness - iconSize) / 2)
    // window dots under each icon, all sized from the icon: a dot, the gap between dots (also
    // between the icon and its dots), and how many before a plus takes over
    readonly property int dot: Math.max(3, Math.round(iconSize / 9))
    readonly property int dotGap: Math.max(2, Math.round(dot * 0.75))
    readonly property int maxDots: 4
    padding: pad
    contentLength: vertical ? list.implicitHeight : list.implicitWidth
    overflow: vertical ? 200 : 48   // room for the app names on hover
    empty: appKeys.length === 0
    forceShown: menuOpen || dragging || previewKey !== ""

    readonly property var pinned: Settings.opts.dockPinned
    readonly property bool menuOpen: menu.shown
    DockMenu { id: menu; dock: root }
    DockPreviews { dock: root }
    Genie { dock: root }

    // where a window's app icon is on this screen (minimize and restore fly to and from it); an
    // app without an icon here uses the middle of the dock
    function iconRect(address) {
        const t = Hyprland.toplevels.values.find(t => "0x" + t.address === address)
        const key = t ? appIdOf(t).toLowerCase() : ""
        for (const c of list.children)
            if (c.modelData === key) return screenRect(c)
        const r = screenRect(list)
        return Qt.rect(r.x + r.width / 2 - iconSize / 2, r.y + r.height / 2 - iconSize / 2, iconSize, iconSize)
    }

    // window previews of the running app under the pointer: they open after a moment, follow the
    // pointer to other running apps at once, and stay while the pointer moves over to them
    property string hoverKey: ""
    property Item hoverItem: null
    property string previewKey: ""
    property Item previewItem: null
    property bool previewHovered: false
    // a window was just closed from the card, which then shrinks: the pointer may end up outside
    // it for a moment without that meaning "away"
    property bool previewHeld: false
    function holdPreview() { previewHeld = true; holdTimer.restart() }
    // clicked: no previews for that icon until the pointer leaves it
    property string quietKey: ""
    function runningKey(k) { return k !== "" && (apps[k]?.windows.length ?? 0) > 0 }
    function hoverIcon(key, item, on) {
        if (on) { hoverKey = key; hoverItem = item }
        else if (hoverKey === key) { hoverKey = ""; if (quietKey === key) quietKey = "" }
        syncPreview()
    }
    function pressIcon(key) {
        quietKey = key
        syncPreview()
    }
    function showPreview(key) {
        previewKey = key
        previewItem = key ? hoverItem : null
    }
    function syncPreview() {
        if (dragging || menuOpen || (previewKey && !runningKey(previewKey))) {
            showTimer.stop()
            showPreview("")
            return
        }
        if (runningKey(hoverKey) && hoverKey !== quietKey) {
            hideTimer.stop()
            if (previewKey) showPreview(hoverKey)
            else showTimer.restart()
        } else {
            showTimer.stop()
            if (hoverKey) showPreview("")
            else if (!previewHovered && !previewHeld) hideTimer.restart()
        }
    }
    onPreviewHoveredChanged: syncPreview()
    onDraggingChanged: syncPreview()
    onMenuOpenChanged: syncPreview()
    onAppsChanged: syncPreview()
    Timer {
        id: showTimer
        interval: 450
        onTriggered: if (root.runningKey(root.hoverKey) && root.hoverKey !== root.quietKey) root.showPreview(root.hoverKey)
    }
    Timer {
        id: hideTimer
        interval: 280
        onTriggered: if (!root.previewHovered && !root.previewHeld && !root.hoverKey) root.showPreview("")
    }
    Timer {
        id: holdTimer
        interval: 1500
        onTriggered: { root.previewHeld = false; root.syncPreview() }
    }

    function appIdOf(t) {
        if (t.wayland && t.wayland.appId) return t.wayland.appId
        const ipc = t.lastIpcObject
        return ipc && ipc.class ? ipc.class : ""
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
    // the order of apps that aren't pinned: shared with the docks on other screens
    readonly property var otherKeys: {
        const rank = k => { const i = DockState.otherOrder.indexOf(k); return i < 0 ? 1e6 : i }
        return appKeys.filter(k => !apps[k].pinned)
            .map((k, i) => [k, i]).sort((a, b) => rank(a[0]) - rank(b[0]) || a[1] - b[1]).map(p => p[0])
    }

    // Dragging an icon rearranges it; dropping it before or after the divider pins or unpins
    // it. With nothing pinned there is no divider: the first pin comes from the right-click menu.
    // "|" is the divider in these lists. Positions are along the dock (x, or y on a side edge).
    readonly property var baseList: pinnedKeys.length ? pinnedKeys.concat(["|"], otherKeys) : otherKeys
    property string dragKey: ""
    property string dragIcon: ""
    property real dragPos: 0
    property int dropIndex: -1
    readonly property bool dragging: dragKey !== ""
    readonly property var shownList: {
        if (!dragging) return baseList
        const list = baseList.filter(k => k !== dragKey)
        list.splice(Math.max(0, Math.min(dropIndex, list.length)), 0, dragKey)
        return list
    }
    readonly property bool dividerShown: pinnedKeys.length > 0 && (dragging || (Settings.opts.dockDivider && otherKeys.length > 0))
    readonly property Item listItem: list

    function startDrag(key, icon, pos) {
        dragKey = key
        dragIcon = icon
        dropIndex = baseList.indexOf(key)
        moveDrag(pos)
    }

    // the drop index is how many other slots sit before the pointer, measured where they are
    // drawn now (so a neighbour swaps once the pointer passes its middle)
    function moveDrag(pos) {
        dragPos = pos
        let at = 0, index = 0
        for (const k of shownList) {
            const w = k === "|" ? (dividerShown ? 1 : 0) : iconSize
            if (k !== dragKey && at + w / 2 < pos) index++
            if (w) at += w + list.spacing
        }
        dropIndex = index
    }

    function endDrag(cancel) {
        if (!cancel && dragging) {
            // the dragged app can be gone by now (its last window closed)
            const list = shownList.filter(k => k === "|" || k in apps)
            const cut = list.indexOf("|")
            if (cut >= 0) {
                const ids = list.slice(0, cut).map(k => apps[k].id)
                if (JSON.stringify(ids) !== JSON.stringify(pinned)) Settings.set("dockPinned", ids)
            }
            DockState.otherOrder = cut >= 0 ? list.slice(cut + 1) : list
        }
        dragKey = ""
        dropIndex = -1
    }

    function click(app, entry) {
        if (app.windows.length === 0) {
            if (entry) entry.execute()
        } else {
            Windows.toggleApp(app.windows)
        }
    }

    // a minimized window's preview: brings that one back; the previews step aside for its flight
    function restoreWindow(t) {
        quietKey = previewKey
        showPreview("")
        Windows.restore(t)
    }
    // one window from its preview (its X, or a middle click): the previews stay while the rest move up
    function closeWindow(t) {
        holdPreview()
        Windows.close([t])
    }

    function togglePin(app) {
        const list = pinned.slice()
        const i = list.findIndex(id => id.toLowerCase() === app.id.toLowerCase())
        if (i >= 0) list.splice(i, 1)
        else list.push(app.id)
        Settings.set("dockPinned", list)
    }

    function openMenu(item) {
        menu.show(item)
    }

    // towards the screen (away from the edge): +1 or -1 along the depth axis
    readonly property real inward: edge === "bottom" || edge === "right" ? -1 : 1
    // only a dock longer than its icons has room to place them
    readonly property string align: shape === "full" || o.dockLength === "fixed" ? o.dockAlign : "center"
    function place(room, size) { return align === "start" ? 0 : align === "end" ? room - size : (room - size) / 2 }

    // nudged off the edge a little, so icons and their dots sit centered together
    Grid {
        id: list
        x: root.vertical ? (parent.width - width) / 2 + 2 * root.inward : root.place(parent.width, width)
        y: root.vertical ? root.place(parent.height, height) : (parent.height - height) / 2 + 2 * root.inward
        rows: root.vertical ? -1 : 1
        columns: root.vertical ? 1 : -1
        flow: root.vertical ? Grid.TopToBottom : Grid.LeftToRight
        spacing: Math.round(root.iconSize * 0.3)

        move: Transition { NumberAnimation { properties: "x,y"; duration: 180; easing.type: Easing.OutCubic } }

        Repeater {
            model: ScriptModel { values: root.shownList }

            Item {
                id: slot
                required property string modelData
                readonly property bool divider: modelData === "|"
                visible: !divider || root.dividerShown
                width: divider && !root.vertical ? 1 : root.iconSize
                height: divider && root.vertical ? 1 : root.iconSize

                Rectangle {
                    visible: slot.divider
                    anchors.centerIn: parent
                    width: root.vertical ? parent.width * 0.7 : 1
                    height: root.vertical ? 1 : parent.height * 0.7
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

    // the icon being dragged, under the pointer, lifted a little off the dock
    Image {
        visible: root.dragging
        x: list.x + (root.vertical ? 6 * root.inward : root.dragPos - width / 2)
        y: list.y + (root.vertical ? root.dragPos - height / 2 : 6 * root.inward)
        width: root.iconSize
        height: root.iconSize
        sourceSize: Qt.size(root.iconSize * 2, root.iconSize * 2)
        smooth: true
        mipmap: true
        scale: 1.1
        source: root.dragIcon
    }
}
