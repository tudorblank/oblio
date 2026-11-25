// SPDX-License-Identifier: GPL-3.0-or-later
// Styles: the one place the look of the shell's parts and of apps comes from. A style is a
// material (solid or blur; glass comes next), an opacity and a tint (one for dark mode, one for
// light), applied to targets: parts of the shell (bar, dock, menus, settings, launcher) and apps
// (by window class, or all apps at once), added by hand. A target is in one style at most: once in
// one, no other can take it. Shell parts in no style follow Default, which is always first, can't
// be removed and takes no apps; apps in no style are left as they are.
// Settings.opts.styles holds them in order: uid, name, material, opacity, tint, tintLight, targets.
// Hyprland gets one named rule per target (blur behind a shell part's layer; an app's opacity and
// blur), applied live and written to settings.lua: sending a name again replaces that rule.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    // the shell's parts, by their layer namespaces. Menus are everything the shell opens over the
    // desktop for a moment: the bar's popups, right-click menus, the dock's window previews,
    // notification cards, the color picker; a new one draws Styles.look("menus") and goes in its
    // namespaces. floor: the alpha Hyprland doesn't blur under, so what a surface draws around
    // itself stays clear (the settings panel dims the screen); a blurred surface keeps its fill above it
    readonly property var parts: [
        { id: "bar", name: "Bar", icon: Icons.bar, namespaces: ["oblio-bar"] },
        { id: "dock", name: "Dock", icon: Icons.dock, namespaces: ["oblio-dock"] },
        { id: "menus", name: "Menus", icon: Icons.menu, namespaces: ["oblio-popup", "oblio-previews", "oblio-notifications"] },
        { id: "settings", name: "Settings", icon: Icons.settings, namespaces: ["oblio-settings"], floor: 0.12 },
        { id: "launcher", name: "App launcher", icon: Icons.apps, namespaces: ["rofi"] },
    ]
    function part(id) { return parts.find(p => p.id === id) ?? null }

    // apps: "apps" is every app not in a style of its own, "app:CLASS" one app's windows
    readonly property string allApps: "apps"
    function isApp(target) { return target === allApps || target.startsWith("app:") }

    readonly property var fresh: ({ material: "blur", opacity: 70, tint: "theme", tintLight: "theme" })
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

    function blurs(s) { return s.material !== "solid" && s.opacity < 100 }
    // the tint for the current mode: a chosen one keeps text drawn for the mode readable
    function tint(s) {
        const t = Theme.dark ? s.tint : s.tintLight
        return Qt.color(/^#[0-9a-fA-F]{6}$/.test(t) ? t : Theme.solid)
    }
    // how a style draws a surface: fill (the tint at the opacity, kept above floor while it blurs
    // so Hyprland still blurs under it), line (its outline)
    function paint(s, floor) {
        const c = tint(s)
        return {
            tint: c,
            fill: Qt.rgba(c.r, c.g, c.b, Math.max(s.opacity / 100, blurs(s) ? floor + 0.01 : 0)),
            line: s.opacity >= 100 ? Theme.hairline : Theme.border,
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
                     body: `match = { namespace = ${str("^(" + p.namespaces.map(esc).join("|") + ")$")} }, blur = ${blurs(styleOf(p.id))}, ignore_alpha = ${p.floor ?? 0.01}` })
        }
        // all apps leaves out the ones with a style of their own, so no two rules meet
        const own = []
        for (const s of list) for (const t of s.targets) if (t.startsWith("app:")) own.push(esc(t.slice(4)))
        const windows = (name, cls, s) => {
            const a = (s.opacity / 100).toFixed(2)
            return { name, kind: "window", body: `match = { class = ${str(cls)} }, opacity = "${a} override ${a} override", no_blur = ${s.material === "solid"}` }
        }
        for (const s of list) for (const t of s.targets) {
            if (t === allApps) r.push(windows("oblio-style-apps", own.length ? `negative:(?i)^(${own.join("|")})$` : ".*", s))
            else if (t.startsWith("app:")) r.push(windows("oblio-style-" + t, `(?i)^(${esc(t.slice(4))})$`, s))
        }
        return r
    }
    function lua(r) { return r.map(x => `hl.${x.kind}_rule({ name = ${str(x.name)}, ${x.body} })`).join("\n") }
    // what settings.lua holds
    readonly property string hyprRules: lua(rules)

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
            Hyprland.dispatch(`function() ${root.lua(gone.concat(root.rules))} end`)
            root.applied = root.rules.map(x => ({ name: x.name, kind: x.kind }))
        }
    }
}
