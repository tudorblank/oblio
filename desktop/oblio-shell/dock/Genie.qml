// SPDX-License-Identifier: GPL-3.0-or-later
// Windows flying into and out of the dock: the drawing half of minimize and restore
// (services/Windows.qml says who does what). A live picture of the window, over everything,
// between where the window is and its app's icon. The side across the dock gathers in a little
// ahead of the move towards it: a light magic lamp.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.services

Scope {
    id: fx

    required property var dock
    readonly property var screen: dock.screen
    readonly property bool sideways: dock.vertical

    ListModel { id: flights }

    function onScreen(r) {
        const cx = r.x + r.width / 2, cy = r.y + r.height / 2
        return cx >= screen.x && cx < screen.x + screen.width && cy >= screen.y && cy < screen.y + screen.height
    }
    function start(kind, address, r, active) {
        if (!onScreen(r)) return
        for (let i = flights.count - 1; i >= 0; i--)
            if (flights.get(i).address === address) flights.remove(i)
        const icon = dock.iconRect(address)
        flights.append({
            kind: kind, address: address, active: active,
            wx: r.x - screen.x, wy: r.y - screen.y, ww: r.width, wh: r.height,
            ix: icon.x, iy: icon.y, iw: icon.width, ih: icon.height,
        })
    }

    Connections {
        target: Windows
        function onLeaving(address, from, active) { fx.start("out", address, from, active) }
        function onArriving(address, to) { fx.start("in", address, to, true) }
    }

    // always mapped, as an empty 1x1 surface while nothing flies: Hyprland fades in every layer
    // that appears (its no_anim rule doesn't stop that), which would show the picture half
    // transparent over the window; growing an existing surface has no fade
    PanelWindow {
        id: win
        readonly property bool flying: flights.count > 0
        readonly property bool ready: flying && width === fx.screen.width && height === fx.screen.height
        screen: fx.screen
        anchors { top: true; left: true }
        implicitWidth: flying ? fx.screen.width : 1
        implicitHeight: flying ? fx.screen.height : 1
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "oblio-fx"

        Repeater {
            model: flights

            Item {
                id: flight
                required property int index
                required property string kind
                required property string address
                required property bool active
                required property real wx
                required property real wy
                required property real ww
                required property real wh
                required property real ix
                required property real iy
                required property real iw
                required property real ih

                readonly property var toplevel: Hyprland.toplevels.values.find(t => "0x" + t.address === address) ?? null
                // the picture is on screen, at full size (or there won't be one)
                readonly property bool shown: (shot.hasContent || noPicture.fired) && win.ready
                property bool reported: false

                // 0: where the window is, 1: in the icon
                property real p: kind === "out" ? 0 : 1
                function ease(t) { t = Math.max(0, Math.min(1, t)); return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2 }
                function lerp(a, b, t) { return a + (b - a) * t }
                readonly property real across: ease(p / 0.85)
                readonly property real toward: ease((p - 0.08) / 0.92)
                readonly property real cx: lerp(wx + ww / 2, ix + iw / 2, fx.sideways ? toward : across)
                readonly property real cy: lerp(wy + wh / 2, iy + ih / 2, fx.sideways ? across : toward)
                readonly property real w: lerp(ww, iw, fx.sideways ? toward : across)
                readonly property real h: lerp(wh, ih, fx.sideways ? across : toward)

                x: Math.round(cx - w / 2)
                y: Math.round(cy - h / 2)
                width: Math.max(1, Math.round(w))
                height: Math.max(1, Math.round(h))
                // as see-through as the window (its style); fades as it reaches the icon, so it ends
                // inside it, not on top of it
                opacity: Styles.appOpacity(toplevel?.wayland?.appId) * (p < 0.7 ? 1 : 1 - (p - 0.7) / 0.3)

                // one frame after the picture is up, tell windows.lua; it answers with go
                onShownChanged: if (shown) settle.restart()
                Timer {
                    id: settle
                    interval: 16
                    onTriggered: {
                        if (flight.reported) return
                        flight.reported = true
                        Windows.ready(flight.address, flight.kind)
                    }
                }
                Connections {
                    target: Windows
                    function onGoing(address, duration) {
                        if (address !== flight.address) return
                        run.duration = duration
                        run.start()
                    }
                    function onDropped(address) { if (address === flight.address) flights.remove(flight.index) }
                }
                Timer {
                    id: noPicture
                    property bool fired: false
                    running: true
                    interval: 250
                    onTriggered: fired = true
                }

                NumberAnimation {
                    id: run
                    target: flight
                    property: "p"
                    to: flight.kind === "out" ? 1 : 0
                    easing.type: Easing.Linear
                    onFinished: {
                        Windows.done(flight.address, flight.kind)
                        // arriving: the picture, a live copy exactly over the window that takes no
                        // clicks, stays until windows.lua drops it (the window fades in under it)
                        if (flight.kind === "out") flights.remove(flight.index)
                    }
                }

                // the picture at the window's own size, where it fills exactly, then stretched to the
                // flight's shape (a capture keeps its proportions inside a differently shaped box)
                Item {
                    width: flight.ww
                    height: flight.wh
                    transform: Scale { xScale: flight.w / flight.ww; yScale: flight.h / flight.wh }

                    // the window's border, as Hyprland draws it around the content
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -Settings.opts.borderSize
                        radius: Settings.opts.rounding + Settings.opts.borderSize
                        color: "transparent"
                        border.width: Settings.opts.borderSize
                        border.color: flight.active ? Theme.accent : Theme.dark ? "#aa595959" : "#aab4b4bc"
                    }

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: Settings.opts.rounding
                        color: "transparent"

                        ScreencopyView {
                            id: shot
                            anchors.fill: parent
                            captureSource: flight.toplevel?.wayland ?? null
                            live: true
                        }
                    }
                }
            }
        }
    }
}
