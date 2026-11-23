// SPDX-License-Identifier: GPL-3.0-or-later
// One app in the dock: icon, name on hover, and a running indicator
// (dot = running, pill = focused, faint dot = all windows minimized).

import QtQuick
import Quickshell
import qs.services

Item {
    id: item

    property string key
    property var dock
    // looked up by key, so this icon lives on while the dock's app list is recomputed
    readonly property var app: dock.apps[key] ?? { id: key, pinned: false, windows: [] }

    // desktop entries load in the background after startup; touching the list
    // re-runs the lookup once they arrive (byId alone never updates)
    readonly property var entry: {
        DesktopEntries.applications.values
        return DesktopEntries.byId(app.id) ?? DesktopEntries.heuristicLookup(app.id)
    }
    readonly property bool running: app.windows.length > 0
    readonly property bool active: app.windows.some(t => t.activated)
    readonly property bool allMinimized: running && app.windows.every(t => dock.isMinimized(t))

    width: dock.iconSize
    height: dock.iconSize

    Image {
        id: icon
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: item.dock.iconSize
        height: item.dock.iconSize
        sourceSize: Qt.size(item.dock.iconSize * 2, item.dock.iconSize * 2)
        smooth: true
        mipmap: true
        source: Quickshell.iconPath(item.entry ? item.entry.icon : item.app.id, "application-x-executable")
        transformOrigin: Item.Bottom
        scale: item.dock.dragging ? 1 : mouse.pressed ? 0.92 : mouse.containsMouse && Settings.opts.dockMagnify ? 1.15 : 1

        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        // how many windows it has, from two up: a small accent pill on the corner, ringed in the
        // dock's own color so it reads as cut out of the icon
        Rectangle {
            readonly property int n: item.app.windows.length
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: -Math.round(height * 0.3)
            anchors.topMargin: -Math.round(height * 0.3)
            height: Math.max(14, Math.round(item.dock.iconSize * 0.4))
            width: Math.max(height, count.implicitWidth + Math.round(height * 0.6))
            radius: height / 2
            color: Theme.accent
            border.width: Math.max(1.5, height * 0.12)
            border.color: Theme.glass
            antialiasing: true
            opacity: n > 1 ? 1 : 0
            scale: n > 1 ? 1 : 0.5
            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: 160 } }
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

            Text {
                id: count
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 0.5
                text: parent.n > 9 ? "9+" : parent.n
                color: Theme.onAccent
                font.family: Theme.fontUi
                font.pixelSize: Math.round(parent.height * 0.6)
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 2
        height: 3
        radius: 1.5
        width: item.active ? 12 : 3
        color: Theme.text
        opacity: !item.running ? 0 : item.allMinimized ? 0.35 : item.active ? 0.95 : 0.7

        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // app name above the icon
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: -height - item.dock.pad - (mouse.containsMouse ? 12 : 6)
        width: label.implicitWidth + 20
        height: label.implicitHeight + 10
        radius: height / 2
        color: Theme.popup
        border.width: 1
        border.color: Theme.border
        opacity: mouse.containsMouse && !mouse.pressed && !item.dock.menuOpen && !item.dock.dragging ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Text {
            font.family: Theme.fontUi
            id: label
            anchors.centerIn: parent
            text: item.entry ? item.entry.name : item.app.id
            color: Theme.text
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        preventStealing: true

        // a left press that moves more than a few pixels becomes a drag, not a click
        property point pressPos
        property bool carrying: false
        function rowX(m) { return mapToItem(item.dock.rowItem, m.x, m.y).x }
        onPressed: m => { pressPos = Qt.point(m.x, m.y); carrying = false }
        onPositionChanged: m => {
            if (!(pressedButtons & Qt.LeftButton)) return
            if (!carrying && Math.hypot(m.x - pressPos.x, m.y - pressPos.y) > 8) {
                carrying = true
                item.dock.startDrag(item.key, icon.source, rowX(m))
            } else if (carrying) {
                item.dock.moveDrag(rowX(m))
            }
        }
        // let go well above the dock: nothing changes
        onReleased: m => { if (carrying) item.dock.endDrag(mapToItem(item.dock.rowItem, m.x, m.y).y < -item.dock.iconSize * 1.5) }
        onCanceled: if (carrying) { carrying = false; item.dock.endDrag(true) }
        onClicked: event => {
            if (carrying) { carrying = false; return }
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
