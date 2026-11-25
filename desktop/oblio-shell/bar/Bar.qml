// SPDX-License-Identifier: GPL-3.0-or-later
// The bar, an edge panel (edges/EdgePanel.qml: space, shape, look, showing) on any edge. Its
// widgets (services/BarWidgets.qml) sit in islands, groups of widgets in order along the bar.
// Floating, the bar is one surface, or split into its islands: each is one (continuous) or one
// per widget (scattered). Fit length packs the islands together; fixed and full spread them out
// (place()), and expanding spacers take the free room next to the first and the last island.
// "Along" is x on a top/bottom bar and y on a side bar. A right click opens the bar's menu.
import QtQuick
import Quickshell
import qs.services
import qs.edges
import qs.controls

EdgePanel {
    id: root

    prefix: "bar"

    // floating: one surface, or split into its islands
    readonly property bool split: floating && o.barIslands === "sections"
    readonly property bool spread: shape === "full" || o.barLength === "fixed"
    readonly property int laneGap: split ? 6 : 8
    padding: split ? 0 : floating ? 6 : 10
    drawSurface: !split

    // the islands the bar draws when it's split: a section's, or a widget's
    component Island: Surface {
        edge: root.edge
        shape: "floating"
        material: root.material
        opacityPercent: root.tintOpacity
        tintColor: root.tintColor
        radius: root.rounded(root.thickness)
    }
    forceShown: popover.shown

    // the islands' lanes in order, and those with something to show
    readonly property var lanes: contentItem.children.filter(c => c.isLane === true).sort((a, b) => a.order - b.order)
    readonly property var lanesShown: lanes.filter(l => l.natural > 0)
    contentLength: lanesShown.reduce((n, l) => n + l.natural, 0) + Math.max(0, lanesShown.length - 1) * laneGap

    function openPopup(widget, component, width) {
        popupContent.sourceComponent = component
        popover.cardWidth = width
        popover.open(screen, screenRect(widget), edge, widget)
    }
    // the bar's own menu, at the pointer
    function openMenu(item, x, y) {
        const r = screenRect(item)
        popupContent.sourceComponent = barMenu
        popover.cardWidth = 220
        popover.open(screen, Qt.rect(r.x + x, r.y + y, 0, 0), edge, "bar-menu")
    }
    Component {
        id: barMenu
        Column {
            MenuEntry {
                icon: Icons.settings
                text: "Settings"
                onClicked: { root.closePopup(); Menus.openSettings() }
            }
            MenuEntry {
                icon: Icons.bar
                text: "Bar settings"
                onClicked: { root.closePopup(); Menus.openSettings("Bar") }
            }
        }
    }

    // right clicks between widgets
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: m => root.openMenu(this, m.x, m.y)
    }

    function closePopup() { popover.close() }
    // the widget whose popup is open
    readonly property var popupOwner: popover.shown ? popover.owner : null

    Popover {
        id: popover
        Loader {
            id: popupContent
            active: popover.showing
            width: parent.width
        }
    }

    // one widget: its padding, its island (scattered) or hover highlight, the widget file
    component Slot: Item {
        id: slot
        required property string modelData
        property var lane
        // the section is set right after the slot is made
        readonly property bool scattered: lane ? lane.scattered : false
        readonly property var entry: BarWidgets.entry(modelData)
        readonly property var info: entry ? BarWidgets.info(entry.type) : null
        readonly property var item: loader.item
        readonly property bool shows: item !== null && item.length > 0
        // continuous: room around each widget for its hover highlight; scattered: inside its island
        readonly property real pad: item && item.island ? Math.round(root.thickness * (scattered ? 0.4 : 0.26)) * item.reveal : 0
        readonly property real natural: shows ? item.length + 2 * pad : 0
        readonly property bool stretchy: shows && item.expand && root.spread
        readonly property bool expanding: stretchy && lane !== undefined && lane.grows
        readonly property real along: natural + (expanding ? lane.extra : 0)
        visible: shows
        width: root.vertical ? root.thickness : along
        height: root.vertical ? along : root.thickness

        Island {
            visible: slot.scattered && slot.item !== null && slot.item.island
            anchors.fill: parent
        }

        Rectangle {
            visible: slot.item !== null && slot.item.interactive && slot.item.hovered
            anchors.fill: parent
            anchors.margins: slot.scattered ? 3 : Math.round(root.thickness * 0.12)
            radius: root.rounded(height)
            color: Theme.hover
        }

        Loader {
            id: loader
            x: root.vertical ? 0 : slot.pad
            y: root.vertical ? slot.pad : 0
            width: root.vertical ? parent.width : parent.width - 2 * slot.pad
            height: root.vertical ? parent.height - 2 * slot.pad : parent.height
            source: slot.info ? Qt.resolvedUrl("widgets/" + slot.info.file + ".qml") : ""
            onLoaded: item.bar = root
        }
        Binding {
            when: loader.item !== null
            target: loader.item
            property: "entry"
            value: slot.entry
        }
        Binding {
            when: loader.item !== null
            target: loader.item
            property: "inScattered"
            value: slot.scattered
        }
    }

    component Lane: Item {
        id: section
        required property string modelData
        readonly property bool isLane: true
        readonly property int order: BarWidgets.islandUids.indexOf(modelData)
        readonly property bool scattered: root.split && BarWidgets.island(modelData)?.style === "scattered"
        // a continuous island of a split bar is drawn as one, with room at its ends
        readonly property bool boxed: root.split && !scattered
        readonly property real pad: boxed ? 6 : 0
        // how long it is without expanding spacers, how long it may get, and where it starts
        readonly property real natural: {
            let n = 0, c = 0
            for (const ch of grid.children) if (ch.natural > 0) { n += ch.natural; c++ }
            return c > 0 ? n + (c - 1) * grid.spacing + 2 * pad : 0
        }
        readonly property bool stretchy: {
            for (const ch of grid.children) if (ch.stretchy) return true
            return false
        }
        readonly property int expanders: {
            let c = 0
            for (const ch of grid.children) if (ch.expanding) c++
            return c
        }
        readonly property var placed: root.placement[modelData] ?? { at: 0, room: natural, grows: false, end: false }
        readonly property bool grows: placed.grows
        readonly property real room: placed.room
        readonly property real extra: expanders > 0 ? Math.max(0, room - natural) / expanders : 0
        readonly property real size: root.vertical ? height : width
        // the last island keeps to the far end, however long its spacers make it
        readonly property real at: placed.end ? root.span - size : placed.at
        x: root.vertical ? 0 : at
        y: root.vertical ? at : 0
        width: root.vertical ? root.thickness : (natural > 0 ? grid.width + 2 * pad : 0)
        height: root.vertical ? (natural > 0 ? grid.height + 2 * pad : 0) : root.thickness

        Island {
            visible: section.boxed && section.natural > 0
            anchors.fill: parent
        }

        Grid {
            id: grid
            x: root.vertical ? 0 : section.pad
            y: root.vertical ? section.pad : 0
            rows: root.vertical ? -1 : 1
            columns: root.vertical ? 1 : -1
            flow: root.vertical ? Grid.TopToBottom : Grid.LeftToRight
            // between its widgets only: Grid leaves the ends alone
            spacing: (section.scattered ? 6 : 0) + (BarWidgets.island(section.modelData)?.spacing ?? 0)

            Repeater {
                model: ScriptModel { values: BarWidgets.uids(section.modelData) }
                Slot { lane: section }
            }
        }
    }

    // Where each island goes, from how long they are without stretching: island i of n sits
    // i/(n-1) of the way along the free travel, so the first at the start, the last at the end
    // and the ones between spread evenly (with three, the middle one centered), moved aside where
    // a neighbour is too long; a lone island in the middle. Free room next to the first and the last island is theirs to
    // stretch into (shared when both want the same room); the others keep their place.
    readonly property real span: vertical ? contentItem.height : contentItem.width
    readonly property var placement: {
        const shown = lanesShown, n = shown.length, g = laneGap, S = span
        const len = shown.map(l => l.natural)
        const at = shown.map((l, i) => n === 1 ? (S - len[0]) / 2 : S * i / (n - 1) - len[i] * i / (n - 1))
        for (let i = 1; i < n - 1; i++) at[i] = Math.max(at[i], at[i - 1] + len[i - 1] + g)
        for (let i = n - 2; i >= 1; i--) at[i] = Math.min(at[i], at[i + 1] - g - len[i])
        const p = {}
        shown.forEach((l, i) => p[l.modelData] = { at: at[i], room: len[i], grows: false, end: n > 1 && i === n - 1 })
        if (n === 1) {
            if (shown[0].stretchy) p[shown[0].modelData] = { at: 0, room: S, grows: true, end: false }
            return p
        }
        const first = shown[0], last = shown[n - 1]
        // the room between the first island and the next, and between the last and the one before
        const after = at[1] - len[0] - g, before = at[n - 1] - (at[n - 2] + len[n - 2]) - g
        const both = n === 2 && first.stretchy && last.stretchy
        if (first.stretchy) Object.assign(p[first.modelData], { grows: true, room: len[0] + Math.max(0, after) / (both ? 2 : 1) })
        if (last.stretchy) Object.assign(p[last.modelData], { grows: true, room: len[n - 1] + Math.max(0, before) / (both ? 2 : 1) })
        return p
    }

    Repeater {
        model: ScriptModel { values: BarWidgets.islandUids }
        Lane {}
    }
}
