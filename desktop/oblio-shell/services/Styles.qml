// SPDX-License-Identifier: GPL-3.0-or-later
// Styles: the one place the look of the shell's parts and of apps comes from. A style is a
// material (solid, blur or glass), an opacity and a tint (one for dark mode, one for light), applied
// to targets: parts of the shell (services/Parts.qml) and apps
// (by window class, or all apps at once), added by hand. A target is in one style at most: once in
// one, no other can take it. Shell parts in no style follow Default, which is always first, can't
// be removed and takes no apps; apps in no style are left as they are.
// Settings.opts.styles holds them in order: uid, name, material, opacity, tint, tintLight, targets,
// (fresh lists the rest with their defaults) for every material the outline around a shell part:
// outlineWidth (px, 0 = none), outlineOpacity (%), outlineColor (theme: white in dark mode, black
// in light, or #hex); for blur and glass: blur (strength, 0..12), brightness,
// saturation, contrast, noise (%); for glass only: refraction (%), refractionMode bulge|concave, edge
// (px), falloff, cornerRadius (px, -1 = the shape's), fringing (%); highlightSize (px),
// highlightAngle (deg), highlightOpacity (%), highlightFollow (the rim lights up around the pointer)
// and highlightStrength (% of that).
// Blur and glass are drawn by oblio-glass (services/Glass.qml), each style in its own og.style
// preset (blur: glass with no bending and no light). Without the plugin Hyprland's blur draws them,
// in Default's look (hyprBlur). Hyprland gets one named rule per target (blur behind a shell part's
// layer; an app's opacity and blur; oblio-glass tags for an app), the presets and its blur; all
// applied live and written to settings.lua: sending a name again replaces that rule.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    // the shell's parts (services/Parts.qml)
    readonly property var parts: Parts.list
    function part(id) { return parts.find(p => p.id === id) ?? null }

    // apps: "apps" is every app not in a style of its own, "app:CLASS" one app's windows
    readonly property string allApps: "apps"
    function isApp(target) { return target === allApps || target.startsWith("app:") }

    readonly property var fresh: ({
        material: "blur", opacity: 70, tint: "theme", tintLight: "theme",
        outlineWidth: 1, outlineOpacity: 9, outlineColor: "theme",
        blur: 4, refraction: 50, refractionMode: "bulge", edge: 16, falloff: 1.0, cornerRadius: -1, fringing: 0,
        brightness: 100, saturation: 100, contrast: 100, noise: 0,
        highlightSize: 4, highlightAngle: 315, highlightOpacity: 50, highlightFollow: true, highlightStrength: 50,
    })
    readonly property var list: {
        const l = Array.from(Settings.opts.styles ?? []).map(s => Object.assign({}, fresh, s, { targets: Array.from(s.targets ?? []) }))
        const at = l.findIndex(s => s.uid === "default")
        const d = at < 0 ? Object.assign({}, fresh, { uid: "default", targets: [] }) : l.splice(at, 1)[0]
        d.name = "Default"
        d.targets = []
        return [d].concat(l)
    }
    readonly property var uids: list.map(s => s.uid)
    function style(uid) { return list.find(s => s.uid === uid) ?? null }

    // the style a target follows: shell parts fall back to Default, apps to none (null)
    function styleOf(target) {
        return list.find(s => s.targets.includes(target)) ?? (isApp(target) ? null : list[0])
    }
    // how opaque an app's windows are (1: no style has it), as its rule matches them: the class
    // in any case, else all apps. The dock's flying pictures of windows match it
    function appOpacity(cls) {
        const c = "app:" + String(cls ?? "").toLowerCase()
        const s = list.find(s => s.targets.some(t => t.toLowerCase() === c)) ?? styleOf(allApps)
        return s ? s.opacity / 100 : 1
    }
    // the shell parts no other style has
    readonly property var defaultParts: parts.filter(p => !list.some(s => s.targets.includes(p.id)))

    // oblio-glass draws blur and glass; while it isn't loaded both are Hyprland's blur. Opaque blur
    // shows nothing behind it (opaque glass still has its light)
    function engine(s) {
        return Glass.available && (s.material === "glass" || (s.material === "blur" && s.opacity < 100))
    }
    function blurs(s) { return s.material !== "solid" && !engine(s) && s.opacity < 100 }
    function presetName(s) { return "oblio-style-" + s.uid }
    // apps draw their own background at the style's opacity: theirs is the preset with no tint
    function appPresetName(s) { return presetName(s) + "-app" }
    // the oblio-glass preset a shell part is drawn in, "" when oblio-glass doesn't draw it
    function glassStyle(target) {
        const s = styleOf(target)
        return s && engine(s) ? presetName(s) : ""
    }
    // the tint for the current mode: a chosen one keeps text drawn for the mode readable
    function tint(s) {
        const t = Theme.dark ? s.tint : s.tintLight
        return Qt.color(/^#[0-9a-fA-F]{6}$/.test(t) ? t : Theme.solid)
    }
    // the outline's color at its opacity, transparent when it has no width
    function outline(s) {
        const t = s.outlineColor
        const c = Qt.color(/^#[0-9a-fA-F]{6}$/.test(t) ? t : Theme.dark ? "#ffffff" : "#000000")
        return Qt.rgba(c.r, c.g, c.b, s.outlineWidth > 0 ? s.outlineOpacity / 100 : 0)
    }
    // how a style draws a surface: fill (the tint at the opacity, kept above floor while it blurs
    // so Hyprland still blurs under it; oblio-glass carries the tint itself, so then nothing),
    // line and lineWidth (its outline)
    function paint(s, floor) {
        const c = tint(s)
        return {
            tint: c,
            fill: engine(s) ? "transparent" : Qt.rgba(c.r, c.g, c.b, Math.max(s.opacity / 100, blurs(s) ? floor + 0.01 : 0)),
            line: outline(s),
            lineWidth: s.outlineWidth,
        }
    }
    // how a shell part draws its surface
    function look(target) { return paint(styleOf(target) ?? list[0], part(target)?.floor ?? 0.01) }

    // what a target is called and shows: a shell part's glyph, an app's icon
    function describe(target) {
        const p = part(target)
        if (p) return { name: p.name, glyph: p.icon, image: "" }
        if (target === allApps) return { name: "All apps", glyph: Icons.windows, image: "" }
        const cls = target.slice(4)
        const e = Apps.entry(cls)
        return { name: e?.name || cls, glyph: "", image: Apps.appIcon(cls, "application-x-executable") }
    }

    // changes: each works on a copy and saves it whole
    function change(fn) {
        const l = JSON.parse(JSON.stringify(list))
        const r = fn(l)
        Settings.set("styles", l)
        return r
    }
    function add() {
        return change(l => {
            const uid = "style-" + Date.now().toString(36) + Math.floor(Math.random() * 1296).toString(36)
            let n = l.length
            while (l.some(s => s.name === "Style " + n)) n++
            l.push(Object.assign({ uid, name: "Style " + n, targets: [] }, fresh))
            return uid
        })
    }
    // its targets go back to Default (shell parts) or to how they were (apps)
    function remove(uid) {
        change(l => { const at = l.findIndex(s => s.uid === uid); if (at > 0) l.splice(at, 1) })
    }
    // changes: { material, opacity, tint, tintLight }
    function set(uid, changes) {
        change(l => { const s = l.find(s => s.uid === uid); if (s) Object.assign(s, changes) })
    }
    function rename(uid, name) {
        if (uid !== "default" && name.trim()) set(uid, { name: name.trim() })
    }
    // a target in no style yet (shell parts in Default count as none): only those can be added
    function free(target) { return !list.some(s => s.targets.includes(target)) }
    // a target follows one style: giving it to one takes it from the others; Default takes none
    function assign(uid, target) {
        change(l => {
            for (const s of l) s.targets = s.targets.filter(t => t !== target)
            if (uid !== "default") l.find(s => s.uid === uid)?.targets.push(target)
        })
    }
    function unassign(target) { assign("default", target) }

    // Hyprland: one rule per target, named after it
    function esc(s) { return s.replace(/[.*+?^$()[\]{}|\\]/g, "\\$&") }
    function str(s) { return JSON.stringify(s) }
    readonly property var rules: {
        const r = []
        for (const p of parts) {
            r.push({ name: "oblio-style-" + p.id, kind: "layer",
                     body: `match = { namespace = ${str("^(" + p.namespaces.map(esc).join("|") + ")$")} }, blur = ${blurs(styleOf(p.id))}, ignore_alpha = ${p.floor ?? 0.01}, no_anim = true` })
        }
        // all apps leaves out the ones with a style of their own, so no two rules meet
        const own = []
        for (const s of list) for (const t of s.targets) if (t.startsWith("app:")) own.push(esc(t.slice(4)))
        // an app oblio-glass draws: its window rule, and two tags that give it oblio-glass in its preset
        const windows = (target, cls, s) => {
            const a = (s.opacity / 100).toFixed(2)
            const match = `match = { class = ${str(cls)} }`
            const w = [{ name: "oblio-style-" + target, kind: "window", body: `${match}, opacity = "${a} override ${a} override", no_blur = ${s.material === "solid" || engine(s)}` }]
            if (engine(s)) {
                w.push({ name: "oblio-glass-" + target, kind: "window", body: `${match}, tag = "+oblio_glass_enabled"` })
                w.push({ name: "oblio-glass-preset-" + target, kind: "window", body: `${match}, tag = ${str("+oblio_glass_preset_" + appPresetName(s))}` })
            }
            return w
        }
        for (const s of list) for (const t of s.targets) {
            if (t === allApps) r.push(...windows("apps", own.length ? `negative:(?i)^(${own.join("|")})$` : ".*", s))
            else if (t.startsWith("app:")) r.push(...windows(t, `(?i)^(${esc(t.slice(4))})$`, s))
        }
        return r
    }
    function lua(r) { return r.map(x => `hl.${x.kind}_rule({ name = ${str(x.name)}, ${x.body} })`).join("\n") }

    // each blur and glass style as an oblio-glass preset, on Apple's look ("pomme"). Tint and tone go
    // in both theme variants (the current mode's), so the preset's own never win. Refraction 100 % =
    // 4, twice pomme's; the highlight's opacity is the rim line, its strength the glow at the pointer.
    // Blur is the same glass with no bending, no fringing and no light. A style with apps also gets
    // its app preset, untinted
    function hex(t, fallback) { return String(/^#[0-9a-fA-F]{6}$/.test(t) ? t : fallback).slice(1, 7) }
    function f(v) { return Number(v).toFixed(2) }
    function preset(s, name, tinted) {
        const tintHex = Theme.dark ? hex(s.tint, Theme.solidDark) : hex(s.tintLight, Theme.solidLight)
        const alpha = tinted ? Math.round(s.opacity / 100 * 255) : 0
        const mode = `tint_color = 0x${tintHex}${alpha.toString(16).padStart(2, "0")}, `
            + `brightness = ${f(s.brightness / 100)}, saturation = ${f(s.saturation / 100)}, contrast = ${f(s.contrast / 100)}`
        const fields = [`inherits = "pomme"`, `blur_strength = ${f(s.blur)}`, `noise_strength = ${f(s.noise / 100)}`]
        if (s.material === "glass") {
            fields.push(`refraction_strength = ${f(s.refraction / 25)}`, `refraction_mode = ${s.refractionMode === "concave" ? 1 : 0}`,
                `edge_thickness_px = ${f(s.edge)}`, `refraction_falloff = ${f(s.falloff)}`, `chromatic_aberration = ${f(s.fringing / 100)}`,
                `bevel_size = ${f(s.highlightSize)}`, `bevel_angle = ${f(s.highlightAngle)}`,
                `bevel_strength = ${f(s.highlightOpacity / 100)}`, `pointer_glow = ${f(s.highlightFollow ? s.highlightStrength / 100 : 0)}`)
            if (s.cornerRadius >= 0) fields.push(`refraction_corner_radius = ${f(s.cornerRadius)}`)
        } else {
            fields.push("refraction_strength = 0", "chromatic_aberration = 0", "fresnel_strength = 0",
                "specular_strength = 0", "bevel_strength = 0", "pointer_glow = 0")
        }
        return `og.style(${str(name)}, { ${fields.join(", ")}, dark = { ${mode} }, light = { ${mode} } })`
    }
    readonly property string glassPresets: list.filter(s => s.material !== "solid").map(s =>
        preset(s, presetName(s), true) + (s.targets.some(t => isApp(t)) ? "\n" + preset(s, appPresetName(s), false) : "")
    ).join("\n")
    readonly property string glassLua: glassPresets ? `do local og = hl.plugin.oblio_glass; if og then\n${glassPresets}\nend end` : ""

    // Hyprland's own blur: the fallback while oblio-glass isn't loaded, and what blurs translucent
    // apps in no style. Default's look, converted so both draw alike. Measured:
    // a sharp edge blurs to 14.4 px (10-90 %) per unit of strength in oblio-glass; in Hyprland to
    // 10.71 px per size + 4.5 at 3 passes, 5.02 + 2.5 at 2, 2.8 + 0.4 at 1. Contrast is the same
    // curve in both; vibrancy can only add color (1 ~ saturation 150 %); Hyprland's noise lies under
    // the tint and shows 1.73 times weaker than oblio-glass's, which lies on top
    readonly property var hyprBlur: {
        const s = list[0], width = 14.4 * s.blur
        const fits = [{ passes: 3, a: 10.71, b: 4.5 }, { passes: 2, a: 5.02, b: 2.5 }, { passes: 1, a: 2.8, b: 0.4 }]
        const fit = fits.find(p => Math.round((width - p.b) / p.a) >= 1) ?? fits[2]
        return {
            size: Math.max(1, Math.round((width - fit.b) / fit.a)), passes: fit.passes,
            brightness: s.brightness / 100, contrast: s.contrast / 100,
            vibrancy: Math.min(1, Math.max(0, (s.saturation - 100) / 50)),
            noise: s.noise / 100 * 0.1 * 1.73 / Math.max(0.05, 1 - s.opacity / 100),
        }
    }
    readonly property string blurLua: {
        const b = hyprBlur
        return `hl.config({ decoration = { blur = { size = ${b.size}, passes = ${b.passes}, brightness = ${f(b.brightness)}, `
            + `contrast = ${f(b.contrast)}, vibrancy = ${f(b.vibrancy)}, noise = ${b.noise.toFixed(4)} } } })`
    }

    // what settings.lua holds
    readonly property string hyprRules: blurLua + "\n" + lua(rules) + (glassLua ? "\n" + glassLua : "")

    // live: the rules as they are, and the ones gone since switched off
    property var applied: []
    onHyprRulesChanged: applyTimer.restart()
    Component.onCompleted: applyTimer.restart()
    Timer {
        id: applyTimer
        interval: 40
        onTriggered: {
            const names = root.rules.map(x => x.name)
            const gone = root.applied.filter(a => !names.includes(a.name)).map(a => ({ name: a.name, kind: a.kind,
                body: `match = { ${a.kind === "layer" ? "namespace" : "class"} = "^$" }, enabled = false` }))
            Hyprland.dispatch(`function() ${root.blurLua}\n${root.lua(gone.concat(root.rules))}\n${root.glassLua} end`)
            root.applied = root.rules.map(x => ({ name: x.name, kind: x.kind }))
        }
    }
}
