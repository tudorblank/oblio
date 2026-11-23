// SPDX-License-Identifier: GPL-3.0-or-later
// One app in the dock: icon, a dot per window (hollow = minimized, red = focused app).

import QtQuick
import Quickshell

Item {
    id: item

    property var app
    property var dock

    // desktop entries load in the background after startup; touching the list
    // re-runs the lookup once they arrive (byId alone never updates)
    readonly property var entry: {
        DesktopEntries.applications.values
        return DesktopEntries.byId(app.id) ?? DesktopEntries.heuristicLookup(app.id)
    }
    readonly property bool active: app.windows.some(t => t.activated)
    readonly property bool allMinimized: app.windows.length > 0 && app.windows.every(t => dock.isMinimized(t))

    width: 50
    height: 56

    Image {
        id: icon
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 2
        width: 42
        height: 42
        sourceSize: Qt.size(84, 84)
        smooth: true
        source: Quickshell.iconPath(item.entry ? item.entry.icon : item.app.id, "application-x-executable")
        opacity: item.allMinimized ? 0.55 : 1
        transformOrigin: Item.Bottom
        scale: mouse.pressed ? 1.08 : mouse.containsMouse ? 1.22 : 1

        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        spacing: 3

        Repeater {
            model: item.app.windows.slice(0, 4)

            Rectangle {
                required property var modelData
                readonly property bool minimized: item.dock.isMinimized(modelData)
                width: 5
                height: 5
                radius: 2.5
                color: minimized ? "transparent" : item.active ? "#dc2b2f" : "#e6e6e6"
                border.width: minimized ? 1 : 0
                border.color: "#b0b0b0"
            }
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
                item.dock.toggleAll(item.app)
            } else {
                item.dock.activate(item.app, item.entry)
            }
        }
    }
}
