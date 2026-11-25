// SPDX-License-Identifier: GPL-3.0-or-later
// The bar, an edge panel (edges/EdgePanel.qml: space, shape, look, showing) on any edge. Its
// widgets (services/BarWidgets.qml) sit in three sections: start, center, end. Floating, it's one
// island, or (scattered) one island per widget. Fit length packs the sections together; fixed
// and full spread them out, and expanding spacers share the free room of their section.
// "Along" is x on a top/bottom bar and y on a side bar. A right click opens the bar's menu.
import QtQuick
import Quickshell
import qs.services
import qs.edges
import qs.controls

EdgePanel {
    id: root

    prefix: "bar"

    // floating, each section is continuous or scattered (one island per widget); once any section
    // is scattered the bar splits: every section is an island of its own, or a row of them
    function scatteredLane(name) {
        return floating && o["barIslands" + { start: "Start", center: "Center", end: "End" }[name]] === "scattered"
    }
    readonly property bool split: scatteredLane("start") || scatteredLane("center") || scatteredLane("end")
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

    readonly property var lanesShown: [startLane, centerLane, endLane].filter(l => l.natural > 0)
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
        readonly property real pad: item && item.island ? Math.round(root.thickness * (scattered ? 0.4 : 0.26)) : 0
        readonly property real natural: shows ? item.length + 2 * pad : 0
        readonly property bool expanding: shows && item.expand && root.spread && lane !== undefined && lane.name !== "center"
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
        property string name
        readonly property bool scattered: root.scatteredLane(name)
        // a continuous section of a split bar is one island, with room at its ends
        readonly property bool boxed: root.split && !scattered
        readonly property real pad: boxed ? 6 : 0
        // how long it is without expanding spacers, and how long it may get
        readonly property real natural: {
            let n = 0, c = 0
            for (const ch of grid.children) if (ch.natural > 0) { n += ch.natural; c++ }
            return c > 0 ? n + (c - 1) * grid.spacing + 2 * pad : 0
        }
        readonly property int expanders: {
            let c = 0
            for (const ch of grid.children) if (ch.expanding) c++
            return c
        }
        property real room: natural
        readonly property real extra: expanders > 0 ? Math.max(0, room - natural) / expanders : 0
        // where it starts along the bar
        property real at: 0
        readonly property real size: root.vertical ? height : width
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
            spacing: section.scattered ? 6 : 0

            Repeater {
                model: ScriptModel { values: BarWidgets.uids(section.name) }
                Slot { lane: section }
            }
        }
    }

    // free room on each side: half of what the center leaves, or shared with the other side
    readonly property real span: vertical ? contentItem.height : contentItem.width
    readonly property real freeSides: centerLane.natural > 0
        ? (span - centerLane.natural) / 2 - laneGap
        : span - laneGap
    Lane {
        id: startLane
        name: "start"
        room: centerLane.natural > 0 ? root.freeSides
            : startLane.natural + Math.max(0, root.freeSides - startLane.natural - endLane.natural) / (endLane.expanders > 0 ? 2 : 1)
    }
    Lane {
        id: endLane
        name: "end"
        at: root.span - size
        room: centerLane.natural > 0 ? root.freeSides
            : endLane.natural + Math.max(0, root.freeSides - startLane.natural - endLane.natural) / (startLane.expanders > 0 ? 2 : 1)
    }
    Lane {
        id: centerLane
        name: "center"
        at: {
            const lo = startLane.natural > 0 ? startLane.size + root.laneGap : 0
            const hi = root.span - size - (endLane.natural > 0 ? endLane.size + root.laneGap : 0)
            return Math.max(lo, Math.min((root.span - size) / 2, hi))
        }
    }
}
