// SPDX-License-Identifier: GPL-3.0-or-later
// Right-click menu of a dock icon: the app's windows, new window, pin to dock, quit.
// Clicking anywhere else closes it.

import QtQuick
import qs.services
import qs.controls

Popover {
    id: menu

    property var dock
    property var item: null                      // the DockItem it opened from
    readonly property var app: item ? item.app : null
    readonly property var entry: item ? item.entry : null

    cardWidth: 260
    padding: 6

    function show(item) {
        menu.item = item
        open(dock.screen, dock.screenRect(item), dock.edge, item)
    }

    // a menu row that closes the menu first
    component Entry: MenuEntry {
        signal activated()
        inset: menu.padding
        onClicked: {
            menu.close()
            activated()
        }
    }

    Column {
        id: list
        width: parent.width

        Text {
            font.family: Theme.fontUi
            width: parent.width
            leftPadding: 12
            topPadding: 6
            bottomPadding: 6
            text: menu.entry ? menu.entry.name : (menu.app ? menu.app.id : "")
            elide: Text.ElideRight
            color: Theme.subtext
            font.pixelSize: Theme.textLabel
            font.weight: Font.DemiBold
        }

        // one row per window; minimized ones are dimmed
        Repeater {
            model: menu.app ? menu.app.windows : []

            Entry {
                required property var modelData
                text: modelData.title || menu.app.id
                dim: Windows.isMinimized(modelData)
                onActivated: Windows.focus(modelData)
            }
        }

        Divider { visible: menu.app && menu.app.windows.length > 0 }

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
            onActivated: Windows.close(menu.app.windows)
        }
    }
}
