// SPDX-License-Identifier: GPL-3.0-or-later
// Glass: the shell's side of oblio-glass (desktop/glass), the Hyprland plugin that draws blur and glass.
// The plugin draws it behind the shapes the shell sends for each layer surface; GlassShape items
// (controls/GlassShape.qml) register here, and their shapes go out per layer and screen, live, once
// per frame while anything moves (coalesced, never held back) and only when they changed. available: the plugin is loaded and active
// (a Hyprland update pauses it until setup builds it again); without it Hyprland's blur draws them.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property bool available: false
    property string status: "Checking"

    Process {
        id: probe
        command: ["hyprctl", "-j", "plugin", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list = []
                try { list = JSON.parse(text) } catch (e) {}
                const p = Array.isArray(list) ? list.find(p => p.name === "oblio-glass") : null
                const paused = p && /^Paused/.test(p.description ?? "")
                root.status = !p ? "oblio-glass isn't loaded" : paused ? p.description : ""
                root.available = !!p && !paused
                root.sent = ({})
                root.changed()
            }
        }
    }
    Component.onCompleted: probe.running = true
    // a reload can load, pause or drop the plugin
    Connections {
        target: Hyprland
        function onRawEvent(event) { if (event.name === "configreloaded") probe.running = true }
    }

    // the GlassShape items on screen
    property var items: []
    function register(item) { if (!items.includes(item)) { items = items.concat([item]); changed() } }
    function unregister(item) { if (items.includes(item)) { items = items.filter(i => i !== item); changed() } }
    // all the shapes a frame changed go out together, right after it
    property bool pending: false
    function changed() {
        if (pending) return
        pending = true
        Qt.callLater(flush)
    }

    function num(v) { return Math.round(v * 2) / 2 }
    function shapeLua(s) {
        const r = Array.isArray(s.radius) ? `{ ${s.radius.map(num).join(", ")} }` : num(s.radius)
        return s.full ? `{ full = true, radius = ${r}, strength = ${s.strength.toFixed(2)} }`
            : `{ x = ${num(s.x)}, y = ${num(s.y)}, w = ${num(s.w)}, h = ${num(s.h)}, radius = ${r}, strength = ${s.strength.toFixed(2)} }`
    }

    // layer + screen -> the Lua call that gives the plugin its shapes; what it last got
    property var sent: ({})
    function flush() {
        pending = false
        const calls = {}
        if (root.available) {
            const groups = {}
            for (const item of root.items) {
                const s = item.shape()
                if (!s) continue
                const key = item.namespace + "@" + item.screenName
                if (!groups[key]) groups[key] = { ns: item.namespace, screen: item.screenName, style: item.style, shapes: [] }
                groups[key].shapes.push(s)
            }
            for (const key in groups) {
                const g = groups[key]
                calls[key] = `og.shapes(${JSON.stringify(g.ns)}, { ${g.shapes.map(root.shapeLua).join(", ")} }, ${JSON.stringify(g.style)}${g.screen ? ", " + JSON.stringify(g.screen) : ""})`
            }
        }
        // ones no longer drawn get no glass
        for (const key in root.sent) if (!(key in calls)) {
            const at = key.lastIndexOf("@")
            calls[key] = `og.shapes(${JSON.stringify(key.slice(0, at))}, nil, nil${at < key.length - 1 ? ", " + JSON.stringify(key.slice(at + 1)) : ""})`
        }
        const out = Object.keys(calls).filter(k => root.sent[k] !== calls[k])
        if (!out.length) return
        Hyprland.dispatch(`function() local og = hl.plugin.oblio_glass; if og then ${out.map(k => calls[k]).join(" ")} end end`)
        const s = {}
        for (const k in calls) if (!calls[k].includes(", nil, nil")) s[k] = calls[k]
        root.sent = s
    }
}
