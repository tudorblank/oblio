// SPDX-License-Identifier: GPL-3.0-or-later
// The desktop's files: the Desktop folder (xdg-user-dir DESKTOP), all from GIO, the same as Files
// sees them: gio monitor reports every change in the folder (a file's contents too), then one gio
// info reads every file: name, hidden, modified, icon names, kind and the thumbnail Files made, if
// any. Pictures without one are drawn themselves; videos get one made here (ffmpegthumbnailer,
// into the shell's cache: GLib takes the ones it writes for the shared cache as invalid).
// Launchers (.desktop) show their own name and icon. Drawn by desktop/DesktopWindow.qml, one per
// screen.
// Where each icon is: a position per screen and file name, kept in desktop.json (statePath), in
// pixels from the top left of the screen's free area. Placement "free" keeps any spot, "grid" snaps
// to cells; a new file takes the first free cell, top to bottom, then the next column. "Keep
// arranged by" sorts them into the cells instead, as files come and go. A file whose screen isn't
// there shows on the first screen until it's back.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    // a Desktop folder that is home itself means there is none
    property string folder: ""
    onFolderChanged: {
        monitor.running = false
        info = ({})
        if (folder) watch()
    }

    function option(key) { return Parts.option("desktop", key) }

    // one cell: a name as wide as one and a half icons, under the icon
    readonly property int iconSize: option("iconSize")
    readonly property int spacing: option("spacing")
    readonly property int labelLines: option("labelLines")
    readonly property int labelGap: 4
    readonly property int cellWidth: Math.round(iconSize * 1.5)
    readonly property int cellHeight: iconSize + labelGap + Math.ceil(labelLines * metrics.height)
    readonly property alias labelFont: metrics.font
    FontMetrics {
        id: metrics
        font.family: Theme.fontUi
        font.pixelSize: Theme.textLabel
    }

    // by path: name, uri, isDir, hidden, exec (can be run), size, modified (seconds), icons (theme
    // names, most specific first), type (content type), thumb (a valid thumbnail file)
    property var info: ({})
    // the paths shown, folders first, then by name
    readonly property var paths: {
        const showHidden = option("hidden")
        return sorted(Object.keys(info).filter(p => showHidden || !info[p].hidden), "name")
    }
    // paths in an order: folders first, then by name, kind, date modified (newest first) or size
    // (largest first), then by name
    function sorted(list, key) {
        const by = ({
            kind: (a, b) => a.type.localeCompare(b.type),
            modified: (a, b) => b.modified - a.modified,
            size: (a, b) => b.size - a.size,
        })[key] ?? (() => 0)
        return list.slice().sort((p, q) => {
            const a = info[p], b = info[q]
            return (b.isDir - a.isDir) || by(a, b) || compareNames(a.name, b.name)
        })
    }
    // names in the order Files gives them: numbers by value ("2" before "10"), case aside (Qt's
    // localeCompare ignores its numeric option)
    function compareNames(a, b) {
        const x = a.toLowerCase().match(/\d+|\D+/g) ?? [], y = b.toLowerCase().match(/\d+|\D+/g) ?? []
        for (let i = 0; i < Math.min(x.length, y.length); i++) {
            if (x[i] === y[i]) continue
            if (/^\d/.test(x[i]) && /^\d/.test(y[i])) return (Number(x[i]) - Number(y[i])) || (x[i].length - y[i].length)
            return x[i].localeCompare(y[i])
        }
        return x.length - y.length
    }

    // the free area of each screen with a desktop (DesktopWindow reports it), by screen name
    property var areas: ({})
    function setArea(name, w, h) {
        const a = areas[name]
        if (a && a.w === w && a.h === h) return
        areas = Object.assign({}, areas, { [name]: { w, h } })
        relayout()
    }
    function removeArea(name) {
        const a = Object.assign({}, areas)
        delete a[name]
        areas = a
        relayout()
    }
    readonly property string primary: Quickshell.screens[0]?.name ?? ""

    // the grid: cells top to bottom, then the next column, with spacing around them
    readonly property int pitchX: cellWidth + spacing
    readonly property int pitchY: cellHeight + spacing
    function columns(screen) { return Math.max(1, Math.floor((areas[screen].w - spacing) / pitchX)) }
    function rows(screen) { return Math.max(1, Math.floor((areas[screen].h - spacing) / pitchY)) }
    function cellX(c) { return spacing + c * pitchX }
    function cellY(r) { return spacing + r * pitchY }
    // a saved spot that fits this screen now (it may have shrunk): inside it, on a cell in a grid
    function fit(screen, x, y) {
        const a = areas[screen]
        x = Math.max(0, Math.min(x, a.w - cellWidth))
        y = Math.max(0, Math.min(y, a.h - cellHeight))
        if (option("placement") !== "grid") return [x, y]
        return [cellX(Math.min(columns(screen) - 1, Math.max(0, Math.round((x - spacing) / pitchX)))),
                cellY(Math.min(rows(screen) - 1, Math.max(0, Math.round((y - spacing) / pitchY))))]
    }

    // which cells icons cover, by screen ("column,row"): an icon anywhere covers every cell it overlaps
    function occupancy() {
        const taken = {}
        return {
            mark(screen, x, y) {
                if (!taken[screen]) taken[screen] = new Set()
                const set = taken[screen]
                for (let c = Math.floor((x - spacing) / pitchX); c <= Math.ceil((x - spacing) / pitchX); c++)
                    for (let r = Math.floor((y - spacing) / pitchY); r <= Math.ceil((y - spacing) / pitchY); r++)
                        if (Math.abs(cellX(c) - x) < cellWidth && Math.abs(cellY(r) - y) < cellHeight) set.add(c + "," + r)
            },
            free(screen, c, r) { return !taken[screen]?.has(c + "," + r) },
        }
    }
    // the first free cell: on the first screen, then the others; when all are taken, the last one
    function firstFree(taken) {
        const screens = [primary].concat(Object.keys(areas).filter(s => s !== primary))
        for (const s of screens)
            for (let c = 0; c < columns(s); c++)
                for (let r = 0; r < rows(s); r++)
                    if (taken.free(s, c, r)) return { screen: s, x: cellX(c), y: cellY(r) }
        return { screen: primary, x: cellX(columns(primary) - 1), y: cellY(rows(primary) - 1) }
    }
    // the free cell nearest a spot on a screen
    function nearestFree(taken, screen, x, y) {
        let best = null, d = Infinity
        for (let c = 0; c < columns(screen); c++)
            for (let r = 0; r < rows(screen); r++) {
                const e = (cellX(c) - x) ** 2 + (cellY(r) - y) ** 2
                if (e < d && taken.free(screen, c, r)) { d = e; best = { screen, x: cellX(c), y: cellY(r) } }
            }
        return best ?? firstFree(taken)
    }

    // where every shown icon is: by path { screen, x, y, away (its own screen isn't there) };
    // paths by screen, for each screen's window
    property var placed: ({})
    property var onScreen: ({})
    function relayout() { Qt.callLater(layout) }
    function layout() {
        // every screen's window has reported its area, and the saved spots are read
        if (!loaded || !areas[primary] || Quickshell.screens.some(s => !areas[s.name])) return
        const pos = JSON.parse(JSON.stringify(positions))
        const placed = {}, taken = occupancy()
        let changed = false
        const put = (p, at, away) => {
            placed[p] = { screen: at.screen, x: at.x, y: at.y, away }
            taken.mark(at.screen, at.x, at.y)
        }
        const keep = option("arrange")
        if (keep !== "none") {
            for (const p of sorted(paths, keep)) put(p, firstFree(taken), false)
        } else {
            const later = []
            for (const p of paths) {
                const n = info[p].name
                const s = Object.keys(areas).find(s => pos[s]?.[n])
                if (!s) {
                    later.push(p)
                    continue
                }
                const [x, y] = fit(s, pos[s][n][0], pos[s][n][1])
                put(p, { screen: s, x, y }, false)
            }
            // new files take the spot kept for them (dropped, pasted, renamed) or the first free cell;
            // one saved on a screen that's gone only borrows it
            for (const p of later) {
                const n = info[p].name, away = Object.keys(pos).some(s => pos[s][n])
                const e = expected[n] && areas[expected[n].screen] ? expected[n] : null
                const at = e ? { screen: e.screen, x: fit(e.screen, e.x, e.y)[0], y: fit(e.screen, e.x, e.y)[1] } : firstFree(taken)
                put(p, at, away)
                if (!away) {
                    spot(pos, n, at)
                    changed = true
                }
            }
        }
        // spots of files that are gone (hidden ones keep theirs, and ones about to appear)
        const names = new Set(Object.values(info).map(f => f.name))
        const now = Date.now(), kept = {}
        for (const n in expected) if (expected[n].until > now && !names.has(n)) kept[n] = expected[n]
        if (Object.keys(kept).length !== Object.keys(expected).length) expected = kept
        if (Object.keys(info).length) for (const s in pos) for (const n in pos[s]) if (!names.has(n) && !kept[n]) {
            delete pos[s][n]
            changed = true
        }
        const on = {}
        for (const p of paths) on[placed[p].screen] = (on[placed[p].screen] ?? []).concat([p])
        root.placed = placed
        root.onScreen = on
        if (changed) save(pos)
    }

    // a file's one saved spot: { screen, x, y }
    function spot(pos, name, at) {
        for (const s in pos) delete pos[s][name]
        if (!pos[at.screen]) pos[at.screen] = {}
        pos[at.screen][name] = [at.x, at.y]
    }
    // saves new spots for some icons, in order: where(path, taken) gives each one's; the spots of
    // fixed (paths) count as taken
    function place(order, where, fixed) {
        // never before the saved spots are read: they'd be written over
        if (!loaded) return
        const pos = JSON.parse(JSON.stringify(positions)), taken = occupancy()
        for (const p of fixed ?? []) if (placed[p]) taken.mark(placed[p].screen, placed[p].x, placed[p].y)
        for (const p of order) {
            const at = where(p, taken)
            taken.mark(at.screen, at.x, at.y)
            spot(pos, info[p].name, at)
        }
        save(pos)
        relayout()
    }
    // every icon kept where it is now (not the ones only borrowing a screen); snapped: each on the
    // free cell nearest it, in reading order
    function keepPlaces(snap) {
        const order = paths.filter(p => placed[p] && !placed[p].away)
            .sort((a, b) => (placed[a].x - placed[b].x) || (placed[a].y - placed[b].y))
        place(order, (p, taken) => snap ? nearestFree(taken, placed[p].screen, placed[p].x, placed[p].y) : placed[p])
    }
    // sorts every icon into the cells once (the desktop menu's Arrange by)
    function arrange(key) { place(sorted(paths, key), (p, taken) => firstFree(taken)) }

    onPathsChanged: {
        relayout()
        // what's gone isn't selected; a folder just made is renamed right away
        const sel = {}
        for (const p of paths) if (selection[p]) sel[p] = true
        if (Object.keys(sel).length !== Object.keys(selection).length) selection = sel
        const kept = {}
        for (const p in launchers) if (info[p]) kept[p] = launchers[p]
        if (Object.keys(kept).length !== Object.keys(launchers).length) launchers = kept
        const fresh = folder + "/" + renameNext
        if (renameNext && info[fresh]) {
            renameNext = ""
            select(fresh, "only")
            renaming = fresh
        }
    }

    // spots kept for files about to appear (dropped, pasted, renamed, a new folder), by name:
    // { screen, x, y, until }
    property var expected: ({})
    function expect(name, at) {
        expected = Object.assign({}, expected, { [name]: { screen: at.screen, x: at.x, y: at.y, until: Date.now() + 30000 } })
    }
    // n spots from a place on: there (free placement) or the nearest free cells
    function spotsNear(at, n) {
        const taken = occupancy(), out = []
        for (const p of paths) if (placed[p]) taken.mark(placed[p].screen, placed[p].x, placed[p].y)
        for (let i = 0; i < n; i++) {
            const s = placement !== "grid" && i === 0 ? at : nearestFree(taken, at.screen, at.x, at.y)
            taken.mark(s.screen, s.x, s.y)
            out.push({ screen: s.screen, x: s.x, y: s.y })
        }
        return out
    }

    // the selected paths (path -> true); the anchor is where a Shift range starts and arrows move from
    property var selection: ({})
    property string anchor: ""
    readonly property var selected: paths.filter(p => selection[p])
    // reading order: screen by screen, down each column, then the next
    function order() {
        const rank = s => Math.max(0, Quickshell.screens.findIndex(x => x.name === s))
        return paths.filter(p => placed[p]).sort((a, b) =>
            (rank(placed[a].screen) - rank(placed[b].screen)) || (placed[a].x - placed[b].x) || (placed[a].y - placed[b].y))
    }
    // how: only (just this one), add, toggle, range (from the anchor, in reading order)
    function select(path, how) {
        let sel = how === "only" ? {} : Object.assign({}, selection)
        if (how === "toggle" && sel[path]) delete sel[path]
        else if (how === "range" && placed[anchor]) {
            const o = order(), a = o.indexOf(anchor), b = o.indexOf(path)
            sel = {}
            for (let i = Math.min(a, b); i <= Math.max(a, b); i++) sel[o[i]] = true
        } else sel[path] = true
        selection = sel
        if (how !== "range" || !placed[anchor]) anchor = path
    }
    function selectAll() {
        const sel = {}
        for (const p of paths) sel[p] = true
        selection = sel
    }
    function clearSelection() { selection = ({}) }
    // the icons a rectangle on a screen meets, with base (a selection) kept
    function selectArea(screen, r, base) {
        const sel = Object.assign({}, base)
        for (const p of paths) {
            const at = placed[p]
            if (at && at.screen === screen && at.x < r.x + r.width && at.x + cellWidth > r.x
                && at.y < r.y + r.height && at.y + cellHeight > r.y) sel[p] = true
        }
        selection = sel
    }
    // the nearest icon from the anchor in a direction (arrow keys), on its screen
    function neighbour(dx, dy) {
        const a = placed[anchor]
        if (!a) return order()[0] ?? ""
        let best = anchor, d = Infinity
        for (const p of paths) {
            const b = placed[p]
            if (!b || p === anchor || b.screen !== a.screen) continue
            const along = (b.x - a.x) * dx + (b.y - a.y) * dy
            const across = Math.abs((b.x - a.x) * dy) + Math.abs((b.y - a.y) * dx)
            if (along > 0 && along + 2 * across < d) {
                d = along + 2 * across
                best = p
            }
        }
        return best
    }

    // which screens' desktops have the keyboard: windows.lua hears when any does
    property var keyed: ({})
    property bool hasKeys: false
    function keys(screen, on) {
        const k = Object.assign({}, keyed)
        if (on) k[screen] = true
        else delete k[screen]
        keyed = k
        const any = Object.keys(k).length > 0
        if (any !== hasKeys) {
            hasKeys = any
            Windows.desktopKeys(any)
        }
    }

    // the desktop's menus and questions (desktop/DesktopMenu.qml): a menu { screen, x, y (in the
    // screen), paths (none: the desktop's own), at (a spot there: new folder, paste) }; a question:
    // "launch" an untrusted launcher, "erase" files for good
    signal menuAsked(var where)
    signal asked(string what, var paths)
    function tell(title, body) {
        Quickshell.execDetached(["notify-send", "-e", "-a", "Desktop", "-i", "dialog-warning", title, body])
    }

    // folders open in Files, launchers run (an untrusted one asks first), files open in their app
    function open(list) {
        for (const p of list) {
            const f = info[p]
            if (!f) continue
            if (f.isDir) Quickshell.execDetached(["nautilus", "--new-window", p])
            else if (isLauncher(p) && !f.exec) asked("launch", [p])
            else if (isLauncher(p)) launch(p)
            else Quickshell.execDetached(["gio", "open", p])
        }
    }
    function launch(path) { Quickshell.execDetached(["gio", "launch", path]) }
    // a launcher may run once it's executable, as in Files
    function trust(path, on) { Quickshell.execDetached(["chmod", on ? "+x" : "-x", "--", path]) }
    // with an app, by its desktop entry id (from gio mime)
    function openWith(list, app) {
        Quickshell.execDetached(["sh", "-c", 'app=$1; shift; IFS=:; for d in "${XDG_DATA_HOME:-$HOME/.local/share}" ${XDG_DATA_DIRS:-/usr/local/share:/usr/share}; do [ -f "$d/applications/$app" ] && exec gio launch "$d/applications/$app" "$@"; done', "sh", app].concat(list))
    }
    function showInFiles(list) {
        Quickshell.execDetached(["gdbus", "call", "--session", "--dest", "org.freedesktop.FileManager1",
            "--object-path", "/org/freedesktop/FileManager1", "--method", "org.freedesktop.FileManager1.ShowItems",
            "[" + list.map(p => JSON.stringify(info[p]?.uri ?? "file://" + p)).join(", ") + "]", ""])
    }
    function terminalHere() { Quickshell.execDetached(["alacritty", "--working-directory", folder]) }

    function trash(list) { if (list.length) Quickshell.execDetached(["gio", "trash", "--"].concat(list)) }
    // for good (after asking), and only what's in the Desktop folder
    function erase(list) {
        const l = list.filter(p => p.startsWith(folder + "/"))
        if (l.length) Quickshell.execDetached(["rm", "-rf", "--"].concat(l))
    }

    // a name no file on the desktop has: "name (2).ext", like Files
    function freeName(name, isDir, taken) {
        if (!taken.has(name)) return name
        const dot = isDir ? -1 : name.lastIndexOf(".")
        const base = dot > 0 ? name.slice(0, dot) : name, ext = dot > 0 ? name.slice(dot) : ""
        for (let i = 2; ; i++) if (!taken.has(`${base} (${i})${ext}`)) return `${base} (${i})${ext}`
    }
    function names() { return new Set(Object.values(info).map(f => f.name)) }

    // the icon being renamed in place, and a new folder's name to rename once it shows
    property string renaming: ""
    property string renameNext: ""
    function rename(path, name) {
        renaming = ""
        const f = info[path]
        name = String(name).trim()
        if (!f || !name || name === f.name) return
        if (name.includes("/") || name === "." || name === "..") return tell(`Can't rename “${f.name}”`, "A name can't have / in it")
        if (names().has(name)) return tell(`Can't rename “${f.name}”`, `There's already a “${name}” on the desktop`)
        if (placed[path]) expect(name, placed[path])
        selection = { [folder + "/" + name]: true }
        anchor = folder + "/" + name
        Quickshell.execDetached(["gio", "rename", "--", path, name])
    }
    function newFolder(at) {
        const name = freeName("New Folder", true, names())
        if (at) expect(name, at)
        renameNext = name
        Quickshell.execDetached(["mkdir", "--", folder + "/" + name])
    }

    // copies or moves files into a folder (to; "" for the desktop) under free names; on the desktop
    // they land on spots from at ({ screen, x, y }) on. Moving a file that's already there only
    // moves its icon
    function transfer(list, to, copy, at) {
        const dest = to || folder, taken = names(), spots = at ? spotsNear(at, list.length) : []
        const args = [], stay = []
        list.forEach((src, i) => {
            if (src === dest || dest.startsWith(src + "/")) return
            if (!copy && src.slice(0, src.lastIndexOf("/")) === dest) {
                if (!to && spots[i] && info[src]) stay.push({ path: src, at: spots[i] })
                return
            }
            let name = ""
            if (!to) {
                name = freeName(src.split("/").pop(), info[src]?.isDir ?? false, taken)
                taken.add(name)
                if (spots[i]) expect(name, spots[i])
            }
            args.push(src, dest, name)
        })
        if (stay.length) place(stay.map(s => s.path), p => stay.find(s => s.path === p).at,
                               paths.filter(p => !stay.some(s => s.path === p)))
        if (args.length) {
            jobs = jobs.concat([[copy ? "copy" : "move"].concat(args)])
            if (!mover.running) mover.next()
        }
    }
    property var jobs: []
    Process {
        id: mover
        // each SRC DIR NAME: NAME (or the source's) made free in DIR the way Files does; prints what failed
        function next() {
            if (!root.jobs.length) return
            command = ["sh", "-c", `op=$1; shift
while [ $# -ge 3 ]; do
    src=$1 dir=$2 name=\${3:-\${1##*/}}; shift 3
    base=$name ext=
    [ -d "$src" ] || case $name in ?*.*) base=\${name%.*}; ext=.\${name##*.} ;; esac
    t=$dir/$name i=2
    while [ -e "$t" ] || [ -L "$t" ]; do t="$dir/$base ($i)$ext"; i=$((i+1)); done
    if [ "$op" = copy ]; then cp -a -- "$src" "$t"; else mv -- "$src" "$t"; fi 2>/dev/null || echo "\${src##*/}"
done`, "sh"].concat(root.jobs[0])
            root.jobs = root.jobs.slice(1)
            running = true
        }
        stdout: SplitParser { onRead: name => root.tell(`Couldn't copy or move “${name}”`, "It may be in use, or you can't write there") }
        onExited: next()
    }

    // the clipboard, the way Files uses it: "copy" or "cut", then the files' URIs
    function copy(list, cut) {
        if (!list.length) return
        const text = (cut ? "cut" : "copy") + "\n" + list.map(p => info[p]?.uri ?? "file://" + p).join("\n")
        Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | wl-copy -t x-special/gnome-copied-files', "sh", text])
    }
    // files from the clipboard onto the desktop (at: where, else the first free cells); cut ones move
    function paste(at) {
        clip.at = at ?? null
        clip.running = true
    }
    Process {
        id: clip
        property var at: null
        command: ["sh", "-c", "wl-paste -n -t x-special/gnome-copied-files 2>/dev/null || { echo copy; wl-paste -n -t text/uri-list 2>/dev/null; }"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split(/\r?\n/).filter(l => l)
                const op = lines.shift()
                const list = lines.filter(l => l.startsWith("file://")).map(l => decodeURIComponent(l.slice(7)))
                if (!list.length) return
                root.transfer(list, "", op !== "cut", clip.at)
                if (op === "cut") Quickshell.execDetached(["wl-copy", "--clear"])
            }
        }
    }
    // whether there are files to paste (asked when the desktop's menu opens)
    property bool canPaste: false
    function checkPaste() { pasteCheck.running = true }
    Process {
        id: pasteCheck
        command: ["wl-paste", "--list-types"]
        stdout: StdioCollector {
            onStreamFinished: root.canPaste = /^(x-special\/gnome-copied-files|text\/uri-list)$/m.test(text)
        }
    }

    // our own drags carry dragKey; dragging is what moves, the icon held, where it was held (dx, dy
    // from its cell's top left) and copy (Ctrl was down when it started)
    readonly property string dragKey: "application/x-oblio-desktop"
    property var dragging: null
    function dropPaths(drop) {
        return drop.urls.map(u => String(u)).filter(u => u.startsWith("file://")).map(u => decodeURIComponent(u.slice(7)))
    }
    function own(drop) { return dragging !== null && drop.formats.includes(dragKey) }
    // a drop on the desktop at x, y on a screen: our icons move there; files come in, copied (Shift
    // in Files: moved)
    function dropped(screen, x, y, drop) {
        if (own(drop)) return moveIcons(screen, x - dragging.dx, y - dragging.dy)
        transfer(dropPaths(drop), "", drop.proposedAction !== Qt.MoveAction,
                 { screen, x: x - cellWidth / 2, y: y - iconSize / 2 })
    }
    // a drop on a folder's icon: into that folder
    function droppedOn(target, drop) {
        if (own(drop)) transfer(dragging.paths.filter(p => p !== target), target, dragging.copy)
        else transfer(dropPaths(drop), target, drop.proposedAction !== Qt.MoveAction)
    }
    // the dragged icons to a new place: the held one's cell at x, y, the rest as they were around it
    function moveIcons(screen, x, y) {
        const held = placed[dragging.held]
        if (!held) return
        const moving = dragging.paths.filter(p => placed[p])
        place(order().filter(p => moving.includes(p)), (p, taken) => {
            const nx = x + placed[p].x - held.x, ny = y + placed[p].y - held.y
            return placement === "grid" ? nearestFree(taken, screen, nx, ny) : { screen, x: nx, y: ny }
        }, paths.filter(p => !moving.includes(p)))
    }
    readonly property string placement: option("placement")
    readonly property string keepArranged: option("arrange")
    // what it was before a change (a plain value: a binding would already have the new one)
    property string lastArranged: "none"
    // to a grid: every icon onto a cell; no longer kept arranged: they stay where they were
    onPlacementChanged: if (placement === "grid") keepPlaces(true)
    onKeepArrangedChanged: {
        if (keepArranged === "none" && lastArranged !== "none") keepPlaces(false)
        lastArranged = keepArranged
        relayout()
    }
    // a different cell size: grid icons onto the new cells, once width and height have both changed
    onPitchXChanged: Qt.callLater(resized)
    onPitchYChanged: Qt.callLater(resized)
    function resized() { placement === "grid" && keepArranged === "none" ? keepPlaces(true) : relayout() }

    // the saved spots, by screen name, then file name: [x, y]. Kept as plain JSON: a JsonAdapter
    // property holding this map ignored a second change made right after the first
    property var positions: ({})
    property bool loaded: false
    function save(pos) {
        positions = pos
        store.setText(JSON.stringify({ positions: pos }, null, 2))
    }
    FileView {
        id: store
        path: Quickshell.statePath("desktop.json")
        onLoaded: {
            try { root.positions = JSON.parse(text()).positions ?? {} } catch (e) {}
            root.loaded = true
            root.relayout()
        }
        onLoadFailed: {
            root.loaded = true
            root.relayout()
        }
    }

    IpcHandler {
        target: "desktop"
        // qs -p ~/.config/oblio-shell ipc call desktop arrange name
        function arrange(key: string): void { root.arrange(key) }
    }

    // thumbnails made here, by path
    property var made: ({})

    // what to draw for a file: its picture ("" for none), else its icon
    function picture(path) {
        const i = info[path]
        if (i?.thumb) return Wallpaper.url(i.thumb)
        if (Wallpaper.isImage(path)) return Wallpaper.url(path)
        return made[path] ? Wallpaper.url(made[path]) : ""
    }
    function icon(path) {
        const i = info[path]
        return Apps.themed(i?.icons, i?.isDir ? "folder" : "text-x-generic")
    }
    function isLauncher(path) { return path.endsWith(".desktop") }
    // launchers' own names and icons (by path; their icons read them), and what to call any file
    property var launchers: ({})
    function setLauncher(path, entry) { launchers = Object.assign({}, launchers, { [path]: entry }) }
    function label(path) { return launchers[path]?.name || info[path]?.name || "" }
    // a launcher's [Desktop Entry] name and icon
    function launcher(text) {
        let group = "", name = "", icon = ""
        for (const line of String(text).split("\n")) {
            const l = line.trim()
            if (l.startsWith("[")) group = l
            else if (group === "[Desktop Entry]" && l.startsWith("Name=") && !name) name = l.slice(5)
            else if (group === "[Desktop Entry]" && l.startsWith("Icon=") && !icon) icon = l.slice(5)
        }
        return { name, icon }
    }

    // any change in the folder: read it again, once things settle. It ends with the shell (the
    // shell leaves it running otherwise)
    function watch() {
        monitor.command = ["setpriv", "--pdeathsig", "TERM", "--", "gio", "monitor", "-d", folder]
        monitor.running = true
    }
    Process {
        id: monitor
        stdout: SplitParser { onRead: look.restart() }
        onStarted: look.restart()
        // the folder went away or came back: watch again a moment later
        onExited: if (root.folder) rewatch.restart()
    }
    Timer {
        id: rewatch
        interval: 2000
        onTriggered: if (root.folder) root.watch()
    }
    Timer {
        id: look
        interval: 100
        onTriggered: {
            if (reader.running) reader.again = true
            else reader.running = true
        }
    }
    Process {
        id: reader
        property bool again: false
        onExited: if (again) {
            again = false
            running = true
        }
        command: ["sh", "-c", 'cd "$1" || exit; exec gio info -a "$2" -- * .[!.]* ..?* 2>/dev/null', "sh", root.folder,
                  "standard::name,standard::is-hidden,standard::size,access::can-execute,standard::icon,standard::content-type,time::modified,thumbnail::path,thumbnail::is-valid"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = {}
                let uri = "", cur = null
                for (const line of text.split("\n")) {
                    if (line.startsWith("uri: ")) uri = line.slice(5)
                    else if (line.startsWith("local path: ")) found[line.slice(12)] = cur = { uri, name: "", hidden: false, exec: false, size: 0, modified: 0, icons: [], type: "", thumb: "" }
                    else if (!cur) continue
                    else if (line.startsWith("  standard::name: ")) cur.name = line.slice(18)
                    else if (line === "  standard::is-hidden: TRUE") cur.hidden = true
                    else if (line === "  access::can-execute: TRUE") cur.exec = true
                    else if (line.startsWith("  standard::icon: ")) cur.icons = line.slice(18).split(", ")
                    else if (line.startsWith("  standard::content-type: ")) cur.type = line.slice(26)
                    else if (line.startsWith("  time::modified: ")) cur.modified = Number(line.slice(18))
                    else if (line.startsWith("  standard::size: ")) cur.size = Number(line.slice(18))
                    else if (line.startsWith("  thumbnail::path: ")) cur.thumbPath = line.slice(19)
                    else if (line === "  thumbnail::is-valid: TRUE") cur.valid = true
                }
                for (const p in found) {
                    const f = found[p]
                    f.isDir = f.type === "inode/directory"
                    if (f.valid) f.thumb = f.thumbPath
                    delete f.thumbPath
                    delete f.valid
                }
                root.info = found
                root.makeThumbnails()
            }
        }
    }

    // videos with no thumbnail: one made each, named by the file's URI and modification time, so a
    // changed file gets a new one; ones no file needs any more go
    readonly property string thumbDir: Quickshell.cachePath("thumbnails")
    property var making: ({})
    function makeThumbnails() {
        const args = [], making = {}
        for (const path in info) {
            const f = info[path]
            if (f.thumb || !f.type.startsWith("video/")) continue
            const out = `${thumbDir}/${Qt.md5(f.uri)}-${f.modified}.png`
            args.push(path, out)
            making[out] = path
        }
        root.making = making
        const made = {}
        for (const p in root.made) if (making[root.made[p]] === p) made[p] = root.made[p]
        root.made = made
        if (thumbnailer.running) thumbnailer.again = true
        else thumbnailer.start(args)
    }
    Process {
        id: thumbnailer
        property bool again: false
        function start(a) {
            command = ["sh", "-c", `dir=$1; shift; mkdir -p "$dir"; keep=
while [ $# -gt 1 ]; do
    [ -s "$2" ] || { ffmpegthumbnailer -i "$1" -o "$2.part" -s 256 -c png >/dev/null 2>&1 && mv -f "$2.part" "$2"; } || rm -f "$2.part"
    [ -s "$2" ] && echo "$2"
    keep="$keep \${2##*/}"; shift 2
done
for f in "$dir"/*.png; do case " $keep " in *" \${f##*/} "*) ;; *) rm -f "$f" ;; esac; done`, "sh", thumbDir].concat(a)
            running = true
        }
        stdout: SplitParser {
            onRead: out => {
                const path = root.making[out]
                if (path) root.made = Object.assign({}, root.made, { [path]: out })
            }
        }
        onExited: if (again) {
            again = false
            root.makeThumbnails()
        }
    }

    Process {
        running: true
        command: ["xdg-user-dir", "DESKTOP"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().replace(/\/+$/, "")
                root.folder = p && p !== root.home ? p : ""
            }
        }
    }
}
