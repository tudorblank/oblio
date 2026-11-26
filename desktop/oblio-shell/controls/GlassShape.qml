// SPDX-License-Identifier: GPL-3.0-or-later
// A glass shape: placed exactly over a card or a panel (anchors.fill), it gives oblio-glass the
// shape to draw blur or glass behind (services/Glass.qml), while oblio-glass draws the part's style. Its place,
// size and strength (the opacity it's drawn at, so glass materializes with the card) are read
// after each frame its window draws: nothing runs while the screen is still. (The light around the
// pointer is the plugin's own: it knows where the pointer is.)
import QtQuick
import Quickshell
import qs.services

Item {
    id: g

    property string namespace           // its window's layer namespace
    property string part                // its Styles part: bar, dock, menus, settings
    property var radius: 0              // a number or [tl, tr, br, bl]; -1 = capsule

    readonly property string style: Styles.glassStyle(part)
    readonly property string screenName: QsWindow.window?.screen?.name ?? ""
    readonly property bool active: visible && Glass.available && style !== ""

    // where it is in its window, and how strongly it's drawn; null when it isn't
    function shape() {
        if (!active || width <= 0 || height <= 0) return null
        let strength = 1
        for (let i = g; i; i = i.parent) strength *= i.opacity
        if (strength < 0.01) return null
        // both corners, so a scaled card (an opening animation) is followed exactly
        const p = mapToItem(null, 0, 0), q = mapToItem(null, width, height)
        return { x: p.x, y: p.y, w: q.x - p.x, h: q.y - p.y, radius: radius, strength: strength }
    }

    property var last: null
    function check() {
        const s = JSON.stringify(shape())
        if (s !== last) { last = s; Glass.changed() }
    }
    Connections {
        target: g.Window.window
        enabled: g.active
        function onFrameSwapped() { g.check() }
    }
    onActiveChanged: active ? Glass.register(g) : Glass.unregister(g)
    onRadiusChanged: check()
    Component.onCompleted: if (active) Glass.register(g)
    Component.onDestruction: Glass.unregister(g)
}
