// SPDX-License-Identifier: GPL-3.0-or-later
// Status icons of apps running in the background (StatusNotifierItem). Left click: the app's
// action (or its menu), right click: its menu, middle click: its second action.
import QtQuick
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.services
import qs.bar

BarWidget {
    id: w

    interactive: false
    length: SystemTray.items.values.length > 0 ? (vertical ? row.implicitHeight : row.implicitWidth) : 0

    Grid {
        id: row
        anchors.centerIn: parent
        rows: w.vertical ? -1 : 1
        columns: w.vertical ? 1 : -1
        flow: w.vertical ? Grid.TopToBottom : Grid.LeftToRight
        spacing: w.opt("spacing")

        Repeater {
            model: SystemTray.items

            Item {
                id: slot
                required property var modelData
                width: w.m.cell
                height: width

                function menu() {
                    // next to the icon, on the screen's side of the bar
                    const e = w.bar ? w.bar.edge : "top"
                    const p = slot.mapToItem(null, e === "left" ? slot.width + 6 : 0,
                                             e === "top" ? slot.height + 6 : 0)
                    modelData.display(w.bar.window, p.x, p.y)
                }

                Rectangle {
                    anchors.fill: parent
                    radius: w.bar ? w.bar.rounded(height) : height / 2
                    color: area.containsMouse ? Theme.hover : "transparent"
                }
                IconImage {
                    anchors.centerIn: parent
                    implicitSize: w.m.icon
                    source: slot.modelData.icon
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: m => {
                        const item = slot.modelData
                        if (m.button === Qt.MiddleButton) item.secondaryActivate()
                        else if (m.button === Qt.RightButton || item.onlyMenu) { if (item.hasMenu) slot.menu() }
                        else item.activate()
                    }
                    onWheel: e => slot.modelData.scroll(e.angleDelta.y / 120, false)
                }
            }
        }
    }
}
