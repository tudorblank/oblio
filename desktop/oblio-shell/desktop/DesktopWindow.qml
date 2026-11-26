// SPDX-License-Identifier: GPL-3.0-or-later
// The desktop's files on one screen: over the wallpaper, under every window. Anchored to every
// edge with no space of its own, Hyprland fits the layer between the bar and the dock and resizes
// it when they change (the same room windows get); services/Desktop.qml places the icons in it.
// A click on it takes the keyboard (windows.lua gives it back when a window is clicked); a click
// on empty space clears the selection, a drag there selects with a band, a right click opens the
// desktop's menu; files dropped on it come in.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

PanelWindow {
    id: win

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: Parts.namespace("desktop")
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"

    readonly property string name: screen?.name ?? ""
    function report() {
        if (!name || width <= 0 || height <= 0) return
        Desktop.setArea(name, width, height)
        Hyprland.refreshMonitors()
    }
    onWidthChanged: report()
    onHeightChanged: report()
    onNameChanged: report()
    Component.onCompleted: report()
    Component.onDestruction: {
        Desktop.keys(name, false)
        Desktop.removeArea(name)
    }

    // where the window sits on its screen: inside the space the bar and dock keep (Hyprland's
    // reserved, read again whenever the window resizes)
    readonly property var reserved: Hyprland.monitorFor(screen)?.lastIpcObject?.reserved ?? [0, 0, 0, 0]
    // a menu at a point in the window, for some files or (none) the desktop
    function menuAt(x, y, paths) {
        Desktop.menuAsked({ screen: name, x: reserved[0] + x, y: reserved[1] + y, paths,
                            at: { screen: name, x: x - Desktop.cellWidth / 2, y: y - Desktop.iconSize / 2 } })
    }

    // the desktop's keys go here (it has the keyboard after a click on it)
    function takeKeys() { scope.forceActiveFocus() }
    function key(e) {
        const ctrl = e.modifiers & Qt.ControlModifier, shift = e.modifiers & Qt.ShiftModifier
        const sel = Desktop.selected
        const step = ({ [Qt.Key_Left]: [-1, 0], [Qt.Key_Right]: [1, 0], [Qt.Key_Up]: [0, -1], [Qt.Key_Down]: [0, 1] })[e.key]
        if (step) {
            const p = Desktop.neighbour(step[0], step[1])
            if (p) Desktop.select(p, shift ? "add" : "only")
        } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) Desktop.open(sel)
        else if (e.key === Qt.Key_F2 && sel.length === 1) Desktop.renaming = sel[0]
        else if (e.key === Qt.Key_Delete && shift) { if (sel.length) Desktop.asked("erase", sel) }
        else if (e.key === Qt.Key_Delete) Desktop.trash(sel)
        else if (ctrl && e.key === Qt.Key_A) Desktop.selectAll()
        else if (ctrl && e.key === Qt.Key_C) Desktop.copy(sel, false)
        else if (ctrl && e.key === Qt.Key_X) Desktop.copy(sel, true)
        else if (ctrl && e.key === Qt.Key_V) Desktop.paste(null)
        else if (e.key === Qt.Key_Escape) Desktop.clearSelection()
        else return
        e.accepted = true
    }

    FocusScope {
        id: scope
        anchors.fill: parent
        focus: true
        onActiveFocusChanged: Desktop.keys(win.name, activeFocus)
        Keys.onPressed: e => win.key(e)

        MouseArea {
            id: space
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            property point from
            property var base: ({})
            property bool banding: false
            onPressed: m => {
                win.takeKeys()
                if (m.button === Qt.RightButton) {
                    Desktop.clearSelection()
                    win.menuAt(m.x, m.y, [])
                    return
                }
                // Ctrl or Shift adds to what's selected
                const adding = m.modifiers & (Qt.ControlModifier | Qt.ShiftModifier)
                base = adding ? Desktop.selection : ({})
                if (!adding) Desktop.clearSelection()
                from = Qt.point(m.x, m.y)
            }
            onPositionChanged: m => {
                if (!(m.buttons & Qt.LeftButton)) return
                banding = true
                Desktop.selectArea(win.name, band.area, base)
            }
            onReleased: banding = false
        }
        Rectangle {
            id: band
            visible: space.banding
            readonly property rect area: Qt.rect(Math.min(space.from.x, space.mouseX), Math.min(space.from.y, space.mouseY),
                                                 Math.abs(space.mouseX - space.from.x), Math.abs(space.mouseY - space.from.y))
            x: area.x
            y: area.y
            width: area.width
            height: area.height
            radius: 4
            color: Theme.tint(Theme.accent, 0.15)
            border.width: 1
            border.color: Theme.tint(Theme.accent, 0.6)
        }

        DropArea {
            anchors.fill: parent
            keys: ["text/uri-list", Desktop.dragKey]
            onDropped: d => {
                Desktop.dropped(win.name, d.x, d.y, d)
                d.accept(d.proposedAction)
            }
        }

        Repeater {
            model: ScriptModel { values: Desktop.onScreen[win.name] ?? [] }
            DesktopIcon { window: win }
        }
    }
}
