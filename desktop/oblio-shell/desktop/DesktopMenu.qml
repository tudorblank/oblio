// SPDX-License-Identifier: GPL-3.0-or-later
// The desktop's right-click menus and questions, opened by services/Desktop.qml. For files: open,
// open with, rename, copy, cut, trash, show in Files, a launcher's trust. For the desktop: new
// folder, paste, arrange by, keep arranged, terminal, wallpaper, settings. Questions: running a
// launcher that isn't trusted, deleting for good.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.controls

Scope {
    id: root

    function screen(name) { return Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0] }

    // what the menu is for: files (none: the desktop) and the spot it opened at
    property var files: []
    property var at: null
    readonly property bool forFiles: files.length > 0
    readonly property var first: forFiles ? Desktop.info[files[0]] ?? null : null
    readonly property bool oneLauncher: files.length === 1 && Desktop.isLauncher(files[0])
    // the order kept, or the one to keep once "Keep arranged" is on
    readonly property string keep: Parts.option("desktop", "arrange")
    property string sortBy: "name"

    Connections {
        target: Desktop
        function onMenuAsked(where) {
            root.files = where.paths
            root.at = where.at
            apps.list = []
            if (root.forFiles) {
                // apps for the files' kind, when they're all one kind
                const types = new Set(root.files.map(p => Desktop.info[p]?.type ?? ""))
                if (types.size === 1 && !root.first?.isDir && !root.oneLauncher) {
                    apps.command = ["gio", "mime", [...types][0]]
                    apps.running = true
                }
            } else Desktop.checkPaste()
            menu.open(root.screen(where.screen), Qt.rect(where.x, where.y, 0, 0), "top")
        }
        function onAsked(what, paths) {
            prompt.what = what
            prompt.files = paths
            const s = root.screen(Desktop.placed[paths[0]]?.screen ?? "")
            prompt.open(s, Qt.rect(s.width / 2, s.height / 2, 0, 0), "center")
        }
    }

    // the apps registered for a kind of file (gio mime lists them indented)
    Process {
        id: apps
        property var list: []
        stdout: StdioCollector {
            onStreamFinished: {
                const ids = [...new Set(text.split("\n").filter(l => l.startsWith("\t")).map(l => l.trim()))]
                apps.list = ids.map(id => ({ id, name: Apps.entry(id.replace(/\.desktop$/, ""))?.name ?? id })).slice(0, 4)
            }
        }
    }

    Popover {
        id: menu
        cardWidth: 240
        padding: 6

        // a menu row that closes the menu first
        component Entry: MenuEntry {
            signal activated()
            inset: menu.padding
            iconColumn: true
            onClicked: {
                menu.close()
                activated()
            }
        }

        Column {
            width: parent.width

            // files
            Entry {
                visible: root.forFiles
                text: "Open"
                onActivated: Desktop.open(root.files)
            }
            Repeater {
                model: root.forFiles ? apps.list : []
                Entry {
                    required property var modelData
                    text: "Open with " + modelData.name
                    onActivated: Desktop.openWith(root.files, modelData.id)
                }
            }
            Entry {
                visible: root.files.length === 1
                text: "Rename…"
                onActivated: Desktop.renaming = root.files[0]
            }
            Divider { visible: root.forFiles }
            Entry {
                visible: root.forFiles
                text: "Copy"
                onActivated: Desktop.copy(root.files, false)
            }
            Entry {
                visible: root.forFiles
                text: "Cut"
                onActivated: Desktop.copy(root.files, true)
            }
            Entry {
                visible: root.forFiles
                icon: Icons.trash
                text: "Move to Trash"
                danger: true
                onActivated: Desktop.trash(root.files)
            }
            Divider { visible: root.forFiles }
            Entry {
                visible: root.oneLauncher
                icon: root.first?.exec ? Icons.check : ""
                text: "Allow Launching"
                onActivated: Desktop.trust(root.files[0], !root.first.exec)
            }
            Entry {
                visible: root.forFiles
                icon: Icons.folder
                text: "Show in Files"
                onActivated: Desktop.showInFiles(root.files)
            }

            // the desktop
            Entry {
                visible: !root.forFiles
                text: "New Folder"
                onActivated: Desktop.newFolder(root.at)
            }
            Entry {
                visible: !root.forFiles
                text: "Paste"
                dim: !Desktop.canPaste
                onActivated: if (Desktop.canPaste) Desktop.paste(root.at)
            }
            Divider { visible: !root.forFiles }
            SectionLabel {
                visible: !root.forFiles
                leftPadding: 12
                topPadding: 4
                bottomPadding: 4
                text: "ARRANGE BY"
            }
            Repeater {
                model: root.forFiles ? [] : [{ key: "name", label: "Name" }, { key: "kind", label: "Kind" },
                                             { key: "modified", label: "Date modified" }, { key: "size", label: "Size" }]
                // kept arranged: the order to keep; else they're sorted once
                Entry {
                    required property var modelData
                    icon: root.keep === modelData.key ? Icons.check : ""
                    text: modelData.label
                    onActivated: {
                        root.sortBy = modelData.key
                        if (root.keep !== "none") Parts.set("desktop", "arrange", modelData.key)
                        else Desktop.arrange(modelData.key)
                    }
                }
            }
            Entry {
                visible: !root.forFiles
                icon: root.keep !== "none" ? Icons.check : ""
                text: "Keep Arranged"
                onActivated: Parts.set("desktop", "arrange", root.keep !== "none" ? "none" : root.sortBy)
            }
            Divider { visible: !root.forFiles }
            Entry {
                visible: !root.forFiles
                text: "Open Terminal Here"
                onActivated: Desktop.terminalHere()
            }
            Entry {
                visible: !root.forFiles
                icon: Icons.wallpaper
                text: "Change Wallpaper…"
                onActivated: Menus.openSettings("Wallpaper")
            }
            Entry {
                visible: !root.forFiles
                icon: Icons.settings
                text: "Desktop Settings…"
                onActivated: Menus.openSettings("Desktop")
            }
        }
    }

    // a question in the middle of the screen
    Popover {
        id: prompt
        property string what: ""
        property var files: []
        readonly property string name: Desktop.label(files[0] ?? "")
        cardWidth: 340
        padding: 18

        Column {
            width: parent.width
            spacing: 14

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: prompt.what === "erase"
                      ? (prompt.files.length === 1 ? `Delete “${prompt.name}” for good?` : `Delete ${prompt.files.length} items for good?`)
                      : `Run “${prompt.name}”?`
                color: Theme.text
                font.family: Theme.fontUi
                font.pixelSize: Theme.textTitle
                font.weight: Font.DemiBold
            }
            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: prompt.what === "erase" ? `${prompt.files.length === 1 ? "It" : "They"} won't go to the Trash, and this can't be undone.`
                    : "This launcher isn't marked as trusted. Only run it if you know where it came from."
                color: Theme.subtext
                font.family: Theme.fontUi
                font.pixelSize: Theme.textBody
                lineHeight: 1.2
            }
            Row {
                anchors.right: parent.right
                spacing: 8
                Button {
                    text: "Cancel"
                    onClicked: prompt.close()
                }
                Button {
                    primary: true
                    text: prompt.what === "erase" ? "Delete" : "Trust and Run"
                    onClicked: {
                        prompt.close()
                        if (prompt.what === "erase") Desktop.erase(prompt.files)
                        else {
                            Desktop.trust(prompt.files[0], true)
                            Desktop.launch(prompt.files[0])
                        }
                    }
                }
            }
        }
    }
}
