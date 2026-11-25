// SPDX-License-Identifier: GPL-3.0-or-later
// One app in the dock: icon, name on hover, and a dot per window on the edge side.
// Follows the dock's edge: grows away from it, names appear on the windows' side.

import QtQuick
import qs.services
import qs.controls

Item {
    id: item

    property string key
    property var dock
    // looked up by key, so this icon lives on while the dock's app list is recomputed
    readonly property var app: dock.apps[key] ?? { id: key, pinned: false, windows: [] }

    readonly property var entry: Apps.entry(app.id)
    readonly property bool running: app.windows.length > 0
    readonly property bool active: app.windows.some(t => t.wayland ? t.wayland.activated : t.activated)
    readonly property bool allMinimized: running && app.windows.every(t => Windows.isMinimized(t))

    width: dock.iconSize
    height: dock.iconSize

    readonly property string edge: dock.edge
    readonly property bool vertical: dock.vertical

    Image {
        id: icon
        anchors.centerIn: parent
        width: item.dock.iconSize
        height: item.dock.iconSize
        sourceSize: Qt.size(item.dock.iconSize * 2, item.dock.iconSize * 2)
        smooth: true
        mipmap: true
        source: Apps.appIcon(item.app.id, "application-x-executable")
        transformOrigin: item.edge === "left" ? Item.Left : item.edge === "right" ? Item.Right
                       : item.edge === "top" ? Item.Top : Item.Bottom
        scale: item.dock.dragging ? 1 : mouse.pressed ? 0.92 : mouse.containsMouse && Settings.opts.dockMagnify ? 1.15 : 1

        Behavior on scale { NumberAnimation { duration: Theme.ms(160); easing.type: Easing.OutCubic } }
    }

    // one dot per window on the edge side of the icon, then a plus past dock.maxDots: accent when
    // the app has focus, soft white in the background, faint when all its windows are minimized.
    // Centered on the icon by its real size, on whole pixels.
    Grid {
        id: dots
        readonly property int count: item.app.windows.length
        readonly property color tint: item.active ? Theme.accentText : Theme.tint(Theme.text, 0.75)
        readonly property int d: item.dock.dot
        // the dots' line keeps its place when the (taller) plus shows up
        readonly property int lineAt: item.dock.dotGap + Math.round(d / 2)
        x: !item.vertical ? Math.round((item.width - width) / 2)
           : item.edge === "left" ? -lineAt - Math.round(width / 2) : item.width + lineAt - Math.round(width / 2)
        y: item.vertical ? Math.round((item.height - height) / 2)
           : item.edge === "top" ? -lineAt - Math.round(height / 2) : item.height + lineAt - Math.round(height / 2)
        rows: item.vertical ? -1 : 1
        columns: item.vertical ? 1 : -1
        flow: item.vertical ? Grid.TopToBottom : Grid.LeftToRight
        spacing: item.dock.dotGap
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
        opacity: item.allMinimized ? 0.35 : 1

        Behavior on opacity { NumberAnimation { duration: Theme.ms(200) } }
        Behavior on x { NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutCubic } }

        Repeater {
            model: Math.min(dots.count, item.dock.maxDots)

            Rectangle {
                width: dots.d
                height: dots.d
                radius: dots.d / 2
                color: dots.tint

                Behavior on color { ColorAnimation { duration: Theme.ms(200) } }
                NumberAnimation on scale { from: 0.3; to: 1; duration: Theme.ms(220); easing.type: Easing.OutBack }
            }
        }

        // more windows than dots: a small plus, even sizes so it sits centered on the dots' line
        PlusMark {
            visible: dots.count > item.dock.maxDots
            stroke: 2 * Math.max(1, Math.round(dots.d / 6))
            width: 2 * Math.round(dots.d * 0.7)
            height: width
            color: dots.tint
        }
    }

    // app name on the windows' side of the icon
    Rectangle {
        readonly property real away: item.dock.pad + (mouse.containsMouse ? 12 : 6)
        x: item.edge === "left" ? parent.width + away : item.edge === "right" ? -width - away : (parent.width - width) / 2
        y: item.edge === "bottom" ? -height - away : item.edge === "top" ? parent.height + away : (parent.height - height) / 2
        width: label.implicitWidth + 20
        height: label.implicitHeight + 10
        radius: height / 2
        color: Theme.popup
        border.width: 1
        border.color: Theme.border
        opacity: mouse.containsMouse && !mouse.pressed && !item.dock.menuOpen && !item.dock.dragging
                 && item.dock.previewKey !== item.key ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: Theme.ms(150) } }
        Behavior on x { NumberAnimation { duration: Theme.ms(150); easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Theme.ms(150); easing.type: Easing.OutCubic } }

        Text {
            font.family: Theme.fontUi
            id: label
            anchors.centerIn: parent
            text: item.entry ? item.entry.name : item.app.id
            color: Theme.text
            font.pixelSize: Theme.textLabel
            font.weight: Font.Medium
        }
    }

    DragArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        threshold: 8
        onContainsMouseChanged: item.dock.hoverIcon(item.key, item, containsMouse)
        onPressedChanged: if (pressed) item.dock.pressIcon(item.key)
        Component.onDestruction: item.dock.hoverIcon(item.key, item, false)

        // positions along the dock, and how far into the screen the pointer went past it
        function along(at) { const p = mapToItem(item.dock.listItem, at.x, at.y); return item.vertical ? p.y : p.x }
        function inward(at) {
            const l = item.dock.listItem, p = mapToItem(l, at.x, at.y)
            return item.edge === "bottom" ? -p.y : item.edge === "top" ? p.y - l.height
                 : item.edge === "left" ? p.x - l.width : -p.x
        }
        onDragStarted: at => item.dock.startDrag(item.key, icon.source, along(at))
        onDragMoved: at => item.dock.moveDrag(along(at))
        // let go well away from the dock, into the screen: nothing changes
        onDropped: at => item.dock.endDrag(inward(at) > item.dock.iconSize * 1.5)
        onDragCanceled: item.dock.endDrag(true)
        onClicked: event => {
            if (dragged) return
            if (event.button === Qt.MiddleButton) {
                if (item.entry) item.entry.execute()
            } else if (event.button === Qt.RightButton) {
                item.dock.openMenu(item)
            } else {
                item.dock.click(item.app, item.entry)
            }
        }
    }
}
