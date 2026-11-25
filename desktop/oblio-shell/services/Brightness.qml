// SPDX-License-Identifier: GPL-3.0-or-later
// The built-in screen's backlight (the first /sys/class/backlight device), on the brightness
// keys' curve (brightnessctl -e4). sysfs doesn't announce changes, so it reads it once a second
// while something shows it (users). set() is throttled: a slider drag doesn't start a process
// per step.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int users: 0
    property string device: ""
    readonly property bool present: device !== "" && max > 0
    readonly property real raw: parseInt(now.text()) || 0
    readonly property real max: parseInt(top.text()) || 0
    readonly property int percent: max > 0 ? Math.round(Math.pow(raw / max, 0.25) * 100) : 0

    // "40%", "5%+", "5%-"
    function set(arg) {
        pendingArg = arg
        if (!throttle.running) throttle.start()
    }
    property string pendingArg: ""

    Process {
        running: true
        command: ["sh", "-c", "ls /sys/class/backlight | head -n1"]
        stdout: StdioCollector { onStreamFinished: root.device = text.trim() }
    }
    FileView { id: now; path: root.device ? `/sys/class/backlight/${root.device}/brightness` : ""; blockLoading: true }
    FileView { id: top; path: root.device ? `/sys/class/backlight/${root.device}/max_brightness` : ""; blockLoading: true }
    Timer { running: root.device !== "" && root.users > 0; interval: 1000; repeat: true; onTriggered: now.reload() }

    Timer {
        id: throttle
        interval: 60
        onTriggered: {
            Quickshell.execDetached(["brightnessctl", "-e4", "-n2", "-d", root.device, "set", root.pendingArg])
            reread.restart()
        }
    }
    Timer { id: reread; interval: 120; onTriggered: now.reload() }
}
