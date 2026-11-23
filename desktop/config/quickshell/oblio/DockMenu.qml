// SPDX-License-Identifier: GPL-3.0-or-later
// Right-click menu of a dock icon: the app's windows, new window, pin to dock, quit.
// Clicking anywhere else closes it.

import QtQuick
import Quickshell

PopupWindow {
    id: menu

    property var dock
    property var item: null                      // the DockItem it opened from
    readonly property var app: item ? item.app : null
    readonly property var entry: item ? item.entry : null

    anchor.item: item
    anchor.edges: Edges.Top
    anchor.gravity: Edges.Top
    anchor.margins.top: -10
    grabFocus: true
    visible: false
    color: "transparent"
    implicitWidth: 260
    implicitHeight: list.implicitHeight + 12

    component Entry: Rectangle {
        id: e
        property string text
        property bool dim: false
        property bool danger: false
        signal activated()
        width: list.width
        height: 34
        radius: 9
        color: area.containsMouse ? Theme.hover : "transparent"

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: e.text
            elide: Text.ElideRight
            color: e.danger ? "#ff8a8d" : Theme.text
            opacity: e.dim ? 0.55 : 1
            font.pixelSize: 13
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                menu.visible = false
                e.activated()
            }
        }
    }

    component Line: Rectangle {
        width: list.width
        height: 9
        color: "transparent"
        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 16
            height: 1
            color: Theme.hairline
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "#f0141418"
        border.width: 1
        border.color: "#24ffffff"

        Column {
            id: list
            anchors.centerIn: parent
            width: parent.width - 12

            Text {
                width: parent.width
                leftPadding: 12
                topPadding: 6
                bottomPadding: 6
                text: menu.entry ? menu.entry.name : (menu.app ? menu.app.id : "")
                elide: Text.ElideRight
                color: Theme.subtext
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            // one row per window; minimized ones are dimmed
            Repeater {
                model: menu.app ? menu.app.windows : []

                Entry {
                    required property var modelData
                    text: modelData.title || menu.app.id
                    dim: menu.dock.isMinimized(modelData)
                    onActivated: menu.dock.focusWindow(modelData)
                }
            }

            Line { visible: menu.app && menu.app.windows.length > 0 }

            Entry {
                visible: menu.entry !== null
                text: "New window"
                onActivated: menu.entry.execute()
            }

            Entry {
                text: menu.app && menu.app.pinned ? "Unpin from dock" : "Pin to dock"
                onActivated: menu.dock.togglePin(menu.app)
            }

            Entry {
                visible: menu.app && menu.app.windows.length > 0
                text: menu.app && menu.app.windows.length > 1 ? "Quit (close " + menu.app.windows.length + " windows)" : "Quit"
                danger: true
                onActivated: menu.dock.quit(menu.app)
            }
        }
    }
}
