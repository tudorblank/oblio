// SPDX-License-Identifier: GPL-3.0-or-later
// Who is logged in: name, full name and profile picture. The picture is a copy in ~/.face (where
// login screens look for one); scripts/apply-theme passes it on to Oblio's login screen.
pragma Singleton

import QtQuick
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string name: Quickshell.env("USER")
    property string fullName: ""
    readonly property string display: fullName || name
    readonly property string face: Quickshell.env("HOME") + "/.face"
    // bumped on every change, so images reload the same path
    property int version: 0
    readonly property string faceUrl: "file://" + face + "?v=" + version

    property bool picking: false
    function pick() {
        picking = true
        dialog.open()
    }

    FileDialog {
        id: dialog
        title: "Profile picture"
        currentFolder: "file://" + Quickshell.env("HOME") + "/Pictures"
        nameFilters: ["Pictures (*.jpg *.jpeg *.png *.webp *.bmp)"]
        onAccepted: {
            copy.command = ["sh", "-c", 'cp -f -- "$1" "$2.new" && chmod 644 "$2.new" && mv -f -- "$2.new" "$2"',
                            "sh", decodeURIComponent(String(selectedFile).replace(/^file:\/\//, "")), root.face]
            copy.running = true
            root.picking = false
        }
        onRejected: root.picking = false
    }

    Process {
        id: copy
        onExited: root.version++
    }

    Process {
        running: true
        command: ["getent", "passwd", root.name]
        stdout: StdioCollector { onStreamFinished: root.fullName = (text.split(":")[4] ?? "").split(",")[0].trim() }
    }
}
