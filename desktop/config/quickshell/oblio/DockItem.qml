// SPDX-License-Identifier: GPL-3.0-or-later
// One app in the dock: icon, name on hover, and a running indicator
// (dot = running, pill = focused, faint dot = all windows minimized).

import QtQuick
import Quickshell

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
        scale: mouse.pressed ? 0.92 : mouse.containsMouse && Settings.opts.dockMagnify ? 1.15 : 1

        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 2
        height: 3
        radius: 1.5
        width: item.active ? 12 : 3
        color: "white"
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
        color: "#d9141417"
        border.width: 1
        border.color: "#24ffffff"
        opacity: mouse.containsMouse && !mouse.pressed && !item.dock.menuOpen ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Text {
            id: label
            anchors.centerIn: parent
            text: item.entry ? item.entry.name : item.app.id
            color: "#f2ffffff"
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: event => {
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
