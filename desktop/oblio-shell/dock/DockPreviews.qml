// SPDX-License-Identifier: GPL-3.0-or-later
// Live previews of a running app's windows, over its dock icon (Dock.previewKey): one tile per
// window with its title, what it's showing when the title says (a browser's tab, a folder) and a
// close button. A strip along the dock's edge that takes input only on the card.
//
// How it moves: layout() is the one place that says where the card belongs (its size from the
// window count, its middle from the icon). Only three values animate towards it: the card's
// length, depth and middle; its corner is plain arithmetic on those, never animated by itself.
// Tiles live in a ListView, which fades a closed one out while the rest slide over. Everything
// uses controls/Anim, so it all arrives together. A fresh card appears in place; a closing one
// freezes and only fades and sinks back into the dock.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.controls

Scope {
    id: root

    required property var dock
    readonly property string edge: dock.edge
    readonly property bool vertical: dock.vertical
    readonly property var app: dock.previewKey ? dock.apps[dock.previewKey] ?? null : null
    readonly property bool open: app !== null
    // what the card shows: follows the app while open, frozen while it fades out
    property var shownApp: null
    property rect shownIcon
    onAppChanged: if (app) shownApp = app

    readonly property int tileWidth: 232
    readonly property int pictureHeight: 140
    readonly property int headHeight: 44
    readonly property int tileHeight: headHeight + pictureHeight + 8
    readonly property int pad: 8
    readonly property int spacing: 6
    readonly property int away: dock.extent + 10

    // where the card belongs: its length and depth (along and away from the dock's edge) and the
    // middle of the icon it belongs to, along the edge
    function layout(count, icon) {
        const n = Math.max(1, count)
        const tilesAlong = vertical ? n * tileHeight + (n - 1) * spacing : n * tileWidth + (n - 1) * spacing
        return {
            length: tilesAlong + 2 * pad,
            depth: (vertical ? tileWidth : tileHeight) + 2 * pad,
            middle: vertical ? icon.y + icon.height / 2 : icon.x + icon.width / 2,
        }
    }

    // "Page — Zen Browser" says the app last and what it shows first: the app becomes the title
    // and the rest the note under it. Titles without the app's name stay whole.
    function describe(title, name, id) {
        const t = (title ?? "").trim()
        const m = t.match(/^(.*\S)\s+[—–-]\s+([^—–-]+)$/)
        const same = s => {
            const a = s.toLowerCase().replace(/[^a-z0-9]/g, ""), b = name.toLowerCase().replace(/[^a-z0-9]/g, "")
            const c = id.toLowerCase().replace(/[^a-z0-9]/g, "")
            return a && (a === b || a === c || b.includes(a) || a.includes(c))
        }
        if (m && same(m[2])) return { title: m[2], note: m[1] }
        return { title: t || name, note: "" }
    }

    // pictures refresh 30 times a second while the card is open: every capture costs the same
    // whether the window changed or not, and a live capture runs at the screen's rate (165 Hz
    // here, about 15 % of a core for a still window)
    Timer {
        id: frames
        interval: 33
        repeat: true
        running: win.visible
    }

    PanelWindow {
        id: win
        screen: root.dock.screen
        visible: root.open || card.opacity > 0
        anchors {
            top: root.edge !== "bottom"
            bottom: root.edge !== "top"
            left: root.edge !== "right"
            right: root.edge !== "left"
        }
        implicitWidth: root.vertical ? root.away + root.tileWidth + 2 * root.pad + 24 : 1
        implicitHeight: root.vertical ? 1 : root.away + root.tileHeight + 2 * root.pad + 24
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "oblio-previews"
        mask: Region { item: root.open ? card : nothing }

        Item { id: nothing }

        Card {
            id: card
            part: "menus"
            namespace: "oblio-previews"

            readonly property rect icon: root.dock.previewItem ? root.dock.screenRect(root.dock.previewItem) : Qt.rect(0, 0, 0, 0)
            onIconChanged: if (root.open && root.dock.previewItem) root.shownIcon = icon
            // the target, from the one source
            readonly property var target: root.layout(tiles.count, root.shownIcon)

            // the only animated values, animating once the card is on screen and open: a fresh
            // card appears in place, a closing one stays put
            property bool settled: false
            property real length: target.length
            property real depth: target.depth
            property real middle: target.middle
            Behavior on length { enabled: card.settled && root.open; Anim {} }
            Behavior on depth { enabled: card.settled && root.open; Anim {} }
            Behavior on middle { enabled: card.settled && root.open; Anim {} }

            readonly property real room: root.vertical ? win.height : win.width
            readonly property real start: Math.max(8, Math.min(middle - length / 2, room - length - 8))

            x: root.vertical ? (root.edge === "left" ? root.away : win.width - root.away - depth) : start
            y: root.vertical ? start : (root.edge === "top" ? root.away : win.height - root.away - depth)
            width: root.vertical ? depth : length
            height: root.vertical ? length : depth
            opacity: root.open ? 1 : 0

            Behavior on opacity { Anim { duration: Theme.motionQuick } }
            onOpacityChanged: if (opacity === 0) settled = false
            Connections {
                target: root
                function onOpenChanged() { if (root.open) Qt.callLater(() => card.settled = true) }
            }

            // rises out of the dock when it opens, sinks back into it when it closes
            transform: Translate {
                readonly property real d: root.open ? 0 : 8
                x: root.edge === "left" ? -d : root.edge === "right" ? d : 0
                y: root.edge === "top" ? -d : root.edge === "bottom" ? d : 0
                Behavior on x { Anim {} }
                Behavior on y { Anim {} }
            }

            HoverHandler { onHoveredChanged: root.dock.previewHovered = hovered }

            ListView {
                id: tiles
                x: root.pad
                y: root.pad
                width: card.width - 2 * root.pad
                height: card.height - 2 * root.pad
                orientation: root.vertical ? ListView.Vertical : ListView.Horizontal
                spacing: root.spacing
                interactive: false
                // a closed window's tile fades inside the shrinking card, never past its edge
                clip: true
                // the same toplevels keep their tiles (and their live pictures) as windows come and go
                model: ScriptModel { values: win.visible && root.shownApp ? root.shownApp.windows : [] }

                add: Transition {
                    enabled: card.settled
                    Anim { property: "opacity"; from: 0; to: 1 }
                    Anim { property: "scale"; from: 0.92; to: 1 }
                }
                remove: Transition {
                    Anim { property: "opacity"; to: 0 }
                    Anim { property: "scale"; to: 0.92 }
                }
                displaced: Transition { Anim { properties: "x,y" } }

                delegate: Rectangle {
                    id: tile
                    required property var modelData
                    readonly property string appId: root.shownApp?.id ?? ""
                    readonly property var entry: Apps.entry(appId)
                    // kept while a closed window's tile fades out (its window is gone by then)
                    readonly property var current: modelData ? root.describe(modelData.title, entry ? entry.name : appId, appId) : null
                    property var info: current ?? { title: "", note: "" }
                    onCurrentChanged: if (current) info = current
                    readonly property bool minimized: modelData ? Windows.isMinimized(modelData) : false
                    width: root.tileWidth
                    height: root.tileHeight
                    radius: Theme.inner(root.pad)
                    color: hover.hovered ? Theme.hover : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.motionQuick } }

                    HoverHandler { id: hover }

                    // a click brings a minimized window back (others: nothing yet); a middle click
                    // closes it, like its X
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        cursorShape: tile.minimized ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: m => {
                            if (m.button === Qt.MiddleButton) root.dock.closeWindow(tile.modelData)
                            else if (tile.minimized) root.dock.restoreWindow(tile.modelData)
                        }
                    }

                    Item {
                        id: head
                        x: 6
                        width: parent.width - 12
                        height: root.headHeight

                        Image {
                            id: appIcon
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            sourceSize: Qt.size(36, 36)
                            source: Apps.appIcon(tile.appId, "application-x-executable")
                        }

                        Column {
                            anchors.left: appIcon.right
                            anchors.leftMargin: 8
                            anchors.right: closeButton.left
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                width: parent.width
                                text: tile.info.title
                                color: Theme.text
                                font.family: Theme.fontUi
                                font.pixelSize: Theme.textLabel
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                visible: text !== ""
                                width: parent.width
                                text: tile.info.note
                                color: Theme.subtext
                                font.family: Theme.fontUi
                                font.pixelSize: Theme.textCaption
                                elide: Text.ElideRight
                            }
                        }

                        // closes this one window
                        Rectangle {
                            id: closeButton
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            height: 24
                            radius: 12
                            color: closeArea.containsMouse ? "#e5484d" : hover.hovered ? Theme.hover : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.motionQuick } }

                            Text {
                                anchors.centerIn: parent
                                text: Icons.close
                                color: closeArea.containsMouse ? "white" : Theme.subtext
                                font.family: Theme.iconFont
                                font.pixelSize: 14
                            }
                            MouseArea {
                                id: closeArea
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.dock.closeWindow(tile.modelData)
                            }
                        }
                    }

                    // the window, live, fitted into the frame
                    ClippingRectangle {
                        id: frame
                        x: 6
                        y: head.height
                        width: parent.width - 12
                        height: root.pictureHeight
                        radius: Theme.inner(root.pad + 6)
                        color: Theme.card

                        Image {
                            anchors.centerIn: parent
                            visible: !shot.hasContent
                            width: 40
                            height: 40
                            sourceSize: Qt.size(80, 80)
                            source: appIcon.source
                            opacity: 0.6
                        }

                        ScreencopyView {
                            id: shot
                            readonly property real ratio: sourceSize.width > 0 ? sourceSize.height / sourceSize.width : 0.625
                            anchors.centerIn: parent
                            width: Math.min(frame.width, frame.height / ratio)
                            height: Math.min(frame.height, frame.width * ratio)
                            captureSource: tile.modelData?.wayland ?? null
                            live: false
                            // a minimized window's picture in muted colors (Settings > Dock)
                            layer.enabled: tile.minimized && Settings.opts.dockMutedMinimized
                            layer.effect: MultiEffect { saturation: -0.7 }
                            Connections {
                                target: frames
                                function onTriggered() {
                                    // a window that changes size loses its capture for good: start it again
                                    if (!shot.hasContent && tile.modelData) {
                                        shot.captureSource = null
                                        shot.captureSource = Qt.binding(() => tile.modelData?.wayland ?? null)
                                    }
                                    if (shot.captureSource) shot.captureFrame()
                                }
                            }
                        }

                    }
                }
            }
        }
    }
}
