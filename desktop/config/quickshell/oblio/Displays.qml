// SPDX-License-Identifier: GPL-3.0-or-later
// Connected monitors (hyprctl monitors all), their modes and valid scales, and applying a
// change: it takes effect at once and goes back by itself unless kept within 15 seconds.
// Kept choices are saved through Settings into ~/.config/hypr/settings.lua.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property var monitors: []
    // { key, config, previous, left }: a change waiting to be kept
    property var pending: null
    readonly property int confirmSeconds: 15

    // the Display page: which monitor it shows, and choices made there but not applied yet
    property int selected: 0
    readonly property var current: monitors[Math.min(selected, monitors.length - 1)] ?? null
    readonly property var base: current ? config(current) : null
    property var draft: ({})
    readonly property var edited: base ? Object.assign({}, base, draft) : null
    readonly property bool dirty: edited !== null && JSON.stringify(edited) !== JSON.stringify(base)

    function edit(changes) { draft = Object.assign({}, draft, changes) }
    function discard() { draft = ({}) }
    onSelectedChanged: discard()
    onPendingChanged: if (!pending) discard()

    function refresh() { refreshTimer.restart() }

    // same as oblio.display_key in monitors.lua
    function key(m) { return m.description ? "desc:" + m.description : m.name }
    function builtin(m) { return /^(eDP|LVDS|DSI)/.test(m.name) }
    function label(m) {
        if (builtin(m)) return "Built-in screen"
        return `${m.make ?? ""} ${m.model ?? ""}`.trim() || m.name
    }
    function inches(m) {
        if (!m.physicalWidth || !m.physicalHeight) return 0
        return Math.sqrt(m.physicalWidth ** 2 + m.physicalHeight ** 2) / 25.4
    }

    function modes(m) {
        const list = []
        for (const s of m?.availableModes ?? []) {
            const r = s.match(/^(\d+)x(\d+)@([\d.]+)Hz$/)
            if (r) list.push({ width: +r[1], height: +r[2], rate: +r[3] })
        }
        return list
    }
    // "WxH", biggest first; the first mode a monitor lists is its native one
    function resolutions(m) {
        const seen = []
        for (const o of modes(m)) {
            const r = `${o.width}x${o.height}`
            if (!seen.includes(r)) seen.push(r)
        }
        const native = seen[0]
        return seen.sort((a, b) => {
            const [aw, ah] = a.split("x").map(Number), [bw, bh] = b.split("x").map(Number)
            return bw * bh - aw * ah || bw - aw
        }).map(r => ({ value: r, native: r === native }))
    }
    function rates(m, res) {
        const list = modes(m).filter(o => `${o.width}x${o.height}` === res).map(o => o.rate)
        return [...new Set(list)].sort((a, b) => b - a)
    }
    function closestRate(m, res, rate) {
        const list = rates(m, res)
        return list.reduce((best, r) => Math.abs(r - rate) < Math.abs(best - rate) ? r : best, list[0] ?? 60)
    }

    // Hyprland takes scales in steps of 1/120 that give a whole number of logical pixels
    function valid(w, h, s) {
        const lw = w / s, lh = h / s
        return Math.abs(lw - Math.round(lw)) < 0.005 && Math.abs(lh - Math.round(lh)) < 0.005
    }
    function scales(res) {
        const [w, h] = res.split("x").map(Number)
        const list = []
        for (let k = 120; k <= 360; k++) {
            const s = k / 120
            if (valid(w, h, s)) list.push(Math.round(s * 1e6) / 1e6)
        }
        return list
    }
    // about 115 pixels per inch: shown as a hint, the default stays 100%
    function recommended(m, res) {
        const [w, h] = res.split("x").map(Number)
        if (!m.physicalWidth || !m.physicalHeight) return 1
        const want = Math.sqrt(w * w + h * h) / inches(m) / 115
        let best = 1
        for (const s of [1, 1.25, 1.5, 1.75, 2, 2.5, 3])
            if (valid(w, h, s) && Math.abs(s - want) < Math.abs(best - want)) best = s
        return best
    }
    function closestScale(res, scale) {
        return scales(res).reduce((best, s) => Math.abs(s - scale) < Math.abs(best - scale) ? s : best, 1)
    }

    function nameOf(id) {
        const m = monitors.find(o => String(o.id) === String(id))
        return m ? m.name : ""
    }

    // what a monitor is set to now, in the shape the Display page edits
    function config(m) {
        const saved = Settings.opts.displays[key(m)]
        const res = `${m.width}x${m.height}`
        return {
            resolution: res,
            rate: closestRate(m, res, m.refreshRate),
            scale: closestScale(res, m.scale),
            transform: m.transform,
            position: saved ? saved.position : "auto",
            mirror: m.mirrorOf && m.mirrorOf !== "none" ? nameOf(m.mirrorOf) : "",
            disabled: m.disabled,
        }
    }

    function luaString(s) { return '"' + String(s).replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"' }

    // every field is written: Hyprland keeps fields a newer rule leaves out (mirror, disabled)
    function rule(k, c) {
        return `hl.monitor({ output = ${luaString(k)}, mode = ${luaString(c.resolution + "@" + c.rate)}, ` +
            `position = ${luaString(c.position)}, scale = ${c.scale}, transform = ${c.transform}, ` +
            `mirror = ${luaString(c.mirror)}, disabled = ${c.disabled} })`
    }

    function dispatch(lua) {
        Quickshell.execDetached(["hyprctl", "dispatch", `function() ${lua} end`])
        refresh()
    }

    function apply(m, c) {
        const k = key(m)
        // going back always means the last kept state, however many changes came in between
        let previous
        if (pending && pending.key === k) {
            previous = pending.previous
        } else {
            if (pending) keep()
            // the kept position ("auto", "auto-left", ...), not coordinates: the other
            // monitors are placed around it, and fixed coordinates would shuffle them
            previous = config(m)
        }
        dispatch(rule(k, c))
        pending = { key: k, config: c, previous: previous, left: confirmSeconds }
        countdown.restart()
    }

    function keep() {
        if (!pending) return
        const all = Object.assign({}, Settings.opts.displays)
        all[pending.key] = pending.config
        Settings.set("displays", all)
        pending = null
        countdown.stop()
    }

    function revert() {
        if (!pending) return
        dispatch(rule(pending.key, pending.previous))
        pending = null
        countdown.stop()
    }

    // back to the native mode at 100%, and nothing saved for it
    function reset(m) {
        const k = key(m)
        if (pending && pending.key === k) revert()
        const all = Object.assign({}, Settings.opts.displays)
        delete all[k]
        Settings.set("displays", all)
        const res = resolutions(m)[0]?.value ?? `${m.width}x${m.height}`
        dispatch(rule(k, {
            resolution: res, rate: rates(m, res)[0] ?? 60, scale: 1,
            transform: 0, position: "auto", mirror: "", disabled: false,
        }))
    }

    Timer {
        id: countdown
        interval: 1000
        repeat: true
        onTriggered: {
            if (!root.pending) return stop()
            const p = Object.assign({}, root.pending)
            p.left -= 1
            root.pending = p
            if (p.left <= 0) root.revert()
        }
    }

    Timer {
        id: refreshTimer
        interval: 150
        onTriggered: {
            if (query.running) restart()
            else query.running = true
        }
    }

    Process {
        id: query
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.monitors = JSON.parse(text) } catch (e) {}
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (/^(monitoradded|monitorremoved|configreloaded)/.test(event.name)) root.refresh()
        }
    }

    Component.onCompleted: refresh()
}
