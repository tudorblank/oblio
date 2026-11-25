// SPDX-License-Identifier: GPL-3.0-or-later
// Shared state of the desktop-space engine (edges/EdgePanel): the panels on each screen, so panels
// on the left and right fit between the top and bottom ones; and fresh window positions for
// panels that hide when a window reaches into them.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property var panels: []
    function add(panel) { panels = panels.concat([panel]) }
    function remove(panel) { panels = panels.filter(p => p !== panel) }

    // how far into the screen the panels along one edge reach, shown or hidden: side panels keep
    // clear of them in every mode (a hidden panel slides back in over that space)
    function occupied(screenName, edge) {
        let n = 0
        for (const p of panels)
            if (p.screen && p.screen.name === screenName && p.edge === edge && !p.empty) n += p.extent
        return n
    }

    // Hyprland has no event for windows being moved or resized: while any panel hides
    // smartly, ask for window positions right after each event and twice a second
    readonly property int watchers: panels.filter(p => p.watching).length
    Timer {
        running: root.watchers > 0
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
        enabled: root.watchers > 0
        function onRawEvent(event) { soon.restart() }
    }
}
