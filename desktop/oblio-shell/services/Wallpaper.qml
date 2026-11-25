// SPDX-License-Identifier: GPL-3.0-or-later
// The desktop and lock screen pictures. Settings > Wallpaper edits a draft that takes effect
// only when applied; the login screen gets its copy through scripts/apply-theme.
pragma Singleton

import QtQuick
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    property string pictures: home + "/Pictures"
    readonly property string folder: Settings.opts.wallpaperFolder || pictures + "/Wallpapers"

    // what the screens show now
    readonly property string desktop: Settings.opts.wallpaper
    readonly property string lock: Settings.opts.wallpaperLockSame ? desktop : Settings.opts.wallpaperLock

    // choices made in Settings, not applied yet
    readonly property var applied: ({ desktop: Settings.opts.wallpaper, lock: Settings.opts.wallpaperLock, same: Settings.opts.wallpaperLockSame })
    property var draft: ({})
    readonly property var edited: Object.assign({}, applied, draft)
    readonly property bool dirty: JSON.stringify(edited) !== JSON.stringify(applied)

    function edit(changes) { draft = Object.assign({}, draft, changes) }
    function discard() { draft = ({}) }
    function apply() {
        const e = edited
        Settings.set("wallpaper", e.desktop)
        Settings.set("wallpaperLock", e.lock)
        Settings.set("wallpaperLockSame", e.same)
        draft = ({})
    }

    readonly property var extensions: ["jpg", "jpeg", "png", "webp", "bmp", "tif", "tiff"]
    function isImage(path) { return extensions.includes(String(path).split(".").pop().toLowerCase()) }
    function url(path) { return path ? "file://" + path.split("/").map(encodeURIComponent).join("/") : "" }
    function path(url) { return decodeURIComponent(String(url).replace(/^file:\/\//, "")) }
    function pretty(path) { return path.startsWith(home + "/") ? "~" + path.slice(home.length) : path }
    function name(path) { return path.split("/").pop() }

    // a file picker (GTK's, through Qt) for "desktop", "lock" or "folder". It's a normal window,
    // so the settings panel steps aside while it's open
    property bool picking: false
    property string pickFor: ""
    function pick(target) {
        pickFor = target
        picking = true
        if (target === "folder") {
            folderDialog.currentFolder = url(folder)
            folderDialog.open()
        } else {
            fileDialog.currentFolder = url(folder)
            fileDialog.open()
        }
    }

    FileDialog {
        id: fileDialog
        title: root.pickFor === "lock" ? "Lock screen wallpaper" : "Desktop wallpaper"
        nameFilters: ["Pictures (" + root.extensions.map(e => "*." + e).join(" ") + ")"]
        onAccepted: {
            root.edit({ [root.pickFor]: root.path(selectedFile) })
            root.picking = false
        }
        onRejected: root.picking = false
    }

    FolderDialog {
        id: folderDialog
        title: "Wallpaper folder"
        onAccepted: {
            Settings.set("wallpaperFolder", root.path(selectedFolder))
            root.picking = false
        }
        onRejected: root.picking = false
    }

    Process {
        running: true
        command: ["xdg-user-dir", "PICTURES"]
        stdout: StdioCollector { onStreamFinished: if (text.trim()) root.pictures = text.trim() }
    }
}
