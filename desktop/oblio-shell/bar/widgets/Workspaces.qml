// SPDX-License-Identifier: GPL-3.0-or-later
// This screen's workspaces: the first few always, more when they're in use. Click to go there,
// scroll to move through them.
import QtQuick
import Quickshell.Hyprland
import qs.services
import qs.bar

BarWidget {
    id: w

    readonly property var monitor: bar ? Hyprland.monitorFor(bar.screen) : null
    readonly property int active: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 1
    // this screen's: other monitors' windows don't make a pill look busy here
    readonly property var used: Hyprland.workspaces.values.filter(ws => ws.id > 0 && (!monitor || ws.monitor === monitor))
    readonly property int last: Math.max(opt("count"), active, ...used.map(ws => ws.id))
    readonly property bool numbers: opt("style") === "numbers"
    function windows(id) {
        const ws = used.find(x => x.id === id)
        return ws ? ws.toplevels.values.length : 0
    }
    function go(target) { Hyprland.dispatch(`hl.dsp.focus({ workspace = ${typeof target === "number" ? target : `"${target}"`} })`) }

    interactive: false
    onScrolled: s => go(s > 0 ? "m-1" : "m+1")
    length: vertical ? row.implicitHeight : row.implicitWidth

    // pills along the bar: a row, or a column on a side bar
    Grid {
        id: row
        anchors.centerIn: parent
        rows: w.vertical ? -1 : 1
        columns: w.vertical ? 1 : -1
        flow: w.vertical ? Grid.TopToBottom : Grid.LeftToRight
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
        spacing: w.numbers ? 0 : w.m.gap

        Repeater {
            model: w.last

            Item {
                id: ws
                required property int index
                readonly property int number: index + 1
                readonly property bool current: number === w.active
                readonly property bool occupied: w.windows(number) > 0
                // the current one is a longer pill along the bar
                readonly property real along: w.numbers ? w.m.cell : current ? w.m.pill : w.m.dot
                readonly property real across: w.numbers ? w.m.cell : w.m.dot
                width: w.vertical ? across : along
                height: w.vertical ? along : across

                Behavior on width { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    radius: Math.min(width, height) / 2
                    color: ws.current ? Theme.accent
                         : w.numbers ? (area.containsMouse ? Theme.hover : "transparent")
                         : Theme.tint(Theme.text, ws.occupied ? (area.containsMouse ? 0.75 : 0.55) : (area.containsMouse ? 0.4 : 0.2))
                    Behavior on color { ColorAnimation { duration: Theme.ms(160) } }
                }

                Text {
                    visible: w.numbers
                    anchors.centerIn: parent
                    text: ws.number
                    color: ws.current ? Theme.accentFg : Theme.text
                    opacity: ws.current || ws.occupied ? 1 : 0.45
                    font.family: Theme.fontUi
                    font.pixelSize: w.m.text
                    font.weight: ws.current ? Font.Bold : Font.Medium
                    font.features: { "tnum": 1 }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    anchors.margins: w.numbers ? 0 : -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: w.go(ws.number)
                }
            }
        }
    }
}
