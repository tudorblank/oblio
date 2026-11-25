// SPDX-License-Identifier: GPL-3.0-or-later
// Settings > Wallpaper: the desktop's and the lock screen's pictures, picked from a folder (click,
// or drag onto either), from a file picker, or dropped from a file manager. Nothing changes until
// Apply (the banner in SettingsPanel).
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell.Widgets
import qs.services
import qs.controls
import qs.settings

Column {
    id: page
    spacing: 22

    readonly property var edited: Wallpaper.edited
    readonly property string dragKey: "oblio/wallpaper"

    // the picture a drop carries: one from the folder below, or a file from a file manager
    function dropped(drop) {
        if (drop.source && drop.source.path) return drop.source.path
        const file = (drop.urls ?? []).map(u => Wallpaper.path(u)).find(p => Wallpaper.isImage(p))
        return file ?? ""
    }

    // a picture, cropped to the frame's shape, with rounded corners
    component Thumb: ClippingRectangle {
        id: thumb
        property string path
        property int decode: 2 * width
        color: Theme.card
        Image {
            anchors.fill: parent
            source: Wallpaper.url(thumb.path)
            fillMode: Image.PreserveAspectCrop
            // decoded small; 0 would mean full size, so never below 64
            sourceSize: Qt.size(Math.max(64, thumb.decode), Math.max(36, Math.round(thumb.decode * 9 / 16)))
            asynchronous: true
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.ms(160) } }
        }
    }

    // the desktop's or the lock screen's picture: empty shows a plus; hovering a filled one
    // shows the delete button; click picks a file, a drop replaces it
    component Slot: Column {
        id: slot
        property string target
        property string label
        property string path
        readonly property bool pending: path !== (target === "lock" && Wallpaper.applied.same ? Wallpaper.applied.desktop : Wallpaper.applied[target])
        spacing: 10
        opacity: enabled ? 1 : Theme.disabledOpacity

        Behavior on opacity { NumberAnimation { duration: Theme.ms(160) } }

        Item {
            id: frame
            width: slot.width
            height: Math.round(width * 9 / 16)
            readonly property bool over: drop.containsDrag && slot.enabled

            Rectangle {
                anchors.fill: parent
                radius: Theme.groupRadius
                color: frame.over ? Theme.tint(Theme.accent, 0.12) : hover.hovered && slot.enabled ? Theme.hover : Theme.card
                Behavior on color { ColorAnimation { duration: Theme.ms(140) } }
            }

            Thumb {
                anchors.fill: parent
                visible: slot.path !== ""
                radius: Theme.groupRadius
                path: slot.path
            }

            // empty: a plus in a soft circle
            Column {
                anchors.centerIn: parent
                visible: slot.path === ""
                spacing: 10

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 44
                    height: 44
                    radius: 22
                    color: Theme.tint(Theme.accent, frame.over || hover.hovered ? 0.22 : 0.14)
                    scale: frame.over ? 1.1 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.ms(160); easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Theme.ms(140) } }
                    PlusMark { anchors.centerIn: parent; width: 18; height: 18; color: Theme.accentText }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Choose or drop a picture"
                    color: Theme.subtext
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.textLabel
                }
            }

            // outline, the accent one while something is dragged over it
            Rectangle {
                anchors.fill: parent
                radius: Theme.groupRadius
                color: "transparent"
                border.width: frame.over ? 2 : 1
                border.color: frame.over ? Theme.accent : Theme.border
            }

            // not applied yet
            Rectangle {
                visible: slot.pending
                x: 10
                y: 10
                width: pendingText.implicitWidth + 16
                height: 22
                radius: 11
                color: Theme.accent
                Text {
                    id: pendingText
                    anchors.centerIn: parent
                    text: "Not applied"
                    color: Theme.accentFg
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.textCaption
                    font.weight: Font.DemiBold
                }
            }

            HoverHandler { id: hover; enabled: slot.enabled }

            MouseArea {
                anchors.fill: parent
                enabled: slot.enabled
                cursorShape: Qt.PointingHandCursor
                onClicked: Wallpaper.pick(slot.target)
            }

            // delete: a red circle in the corner, on hover
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                width: 32
                height: 32
                radius: 16
                color: trashArea.containsMouse ? Qt.lighter("#e5484d", 1.12) : "#e5484d"
                visible: opacity > 0
                opacity: slot.path !== "" && slot.enabled && hover.hovered && !frame.over ? 1 : 0
                scale: opacity * 0.15 + 0.85
                Behavior on opacity { NumberAnimation { duration: Theme.ms(140) } }
                Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

                Text {
                    anchors.centerIn: parent
                    text: Icons.trash
                    color: "white"
                    font.family: Theme.iconFont
                    font.pixelSize: 16
                }
                MouseArea {
                    id: trashArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Wallpaper.edit({ [slot.target]: "" })
                }
            }

            DropArea {
                id: drop
                anchors.fill: parent
                enabled: slot.enabled
                keys: [page.dragKey, "text/uri-list"]
                onDropped: d => {
                    const p = page.dropped(d)
                    if (!p) return
                    Wallpaper.edit({ [slot.target]: p })
                    d.accept()
                }
            }
        }

        Column {
            width: parent.width
            spacing: 2
            Text {
                text: slot.label
                color: Theme.text
                font.family: Theme.fontUi
                font.pixelSize: Theme.textTitle
                font.weight: Font.Medium
            }
            Text {
                width: parent.width
                text: slot.path ? Wallpaper.name(slot.path) : "None"
                color: Theme.subtext
                font.family: Theme.fontUi
                font.pixelSize: Theme.textLabel
                elide: Text.ElideMiddle
            }
        }
    }

    SettingGroup {
        title: "WALLPAPER"

        Item {
            id: slots
            width: parent.width
            height: row.height + 40
            readonly property real slotWidth: Math.min(300, (width - 32 - row.spacing) / 2)

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 24

                Slot {
                    width: slots.slotWidth
                    target: "desktop"
                    label: "Desktop"
                    path: page.edited.desktop
                }
                Slot {
                    width: slots.slotWidth
                    target: "lock"
                    label: "Lock screen"
                    path: page.edited.same ? page.edited.desktop : page.edited.lock
                    enabled: !page.edited.same
                }
            }
        }

        SettingRow {
            title: "Use the desktop's wallpaper on the lock screen"
            description: "Also the login screen's"
            Toggle {
                checked: page.edited.same
                onToggled: v => Wallpaper.edit({ same: v })
            }
        }
    }

    SettingGroup {
        title: "PICTURES"

        SettingRow {
            title: "Folder"
            description: Wallpaper.pretty(Wallpaper.folder)
            Button { text: "Choose…"; onClicked: Wallpaper.pick("folder") }
        }

        Item {
            id: gallery
            width: parent.width
            height: (pictures.count ? grid.height : empty.implicitHeight) + 32
            readonly property real gap: 12
            readonly property int columns: Math.max(2, Math.floor((width - 32 + gap) / (150 + gap)))
            readonly property real tile: (width - 32 - (columns - 1) * gap) / columns

            Divider { inset: 16; space: 1 }

            FolderListModel {
                id: pictures
                folder: Wallpaper.url(Wallpaper.folder)
                nameFilters: Wallpaper.extensions.map(e => "*." + e)
                caseSensitive: false
                showDirs: false
                showHidden: false
            }

            Text {
                id: empty
                visible: !pictures.count
                anchors.centerIn: parent
                width: parent.width - 32
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: `No pictures in ${Wallpaper.pretty(Wallpaper.folder)} yet. Put some there or choose another folder.`
                color: Theme.subtext
                font.family: Theme.fontUi
                font.pixelSize: Theme.textBody
                lineHeight: 1.2
            }

            Flow {
                id: grid
                x: 16
                y: 16
                width: parent.width - 32
                spacing: gallery.gap

                Repeater {
                    model: pictures

                    Item {
                        id: tile
                        required property string filePath
                        required property string fileName
                        readonly property bool used: filePath === page.edited.desktop
                            || filePath === (page.edited.same ? "" : page.edited.lock)
                        width: gallery.tile
                        height: Math.round(width * 9 / 16)

                        Thumb {
                            anchors.fill: parent
                            radius: Theme.inner(10)
                            path: tile.filePath
                            opacity: tileArea.carrying ? 0.4 : 1
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.inner(10)
                            color: tileArea.containsMouse && !tileArea.carrying ? Theme.tint("#ffffff", 0.08) : "transparent"
                            border.width: tile.used ? 2 : 1
                            border.color: tile.used ? Theme.accent : Theme.hairline
                        }

                        DragArea {
                            id: tileArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: carrying ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                            onClicked: if (!dragged) Wallpaper.edit({ desktop: tile.filePath })
                            onDragStarted: at => {
                                const p = mapToItem(page, at.x, at.y)
                                ghost.path = tile.filePath
                                ghost.width = tile.width
                                ghost.grab = Qt.point(at.x, at.y)
                                ghost.x = p.x - at.x
                                ghost.y = p.y - at.y
                                ghost.Drag.active = true
                            }
                            onDragMoved: at => {
                                const p = mapToItem(page, at.x, at.y)
                                ghost.x = p.x - ghost.grab.x
                                ghost.y = p.y - ghost.grab.y
                            }
                            onDropped: { ghost.Drag.drop(); ghost.Drag.active = false }
                            onDragCanceled: ghost.Drag.active = false
                        }
                    }
                }
            }
        }
    }

    // room for the Apply banner under the last row
    Item { width: 1; height: 48 }

    // the picture being dragged, following the pointer
    Thumb {
        id: ghost
        property point grab
        // stays out of the Column's layout
        parent: page.parent
        z: 100
        height: Math.round(width * 9 / 16)
        radius: Theme.inner(10)
        decode: 360
        visible: Drag.active
        opacity: 0.9
        scale: 0.85
        Drag.keys: [page.dragKey]
        Drag.hotSpot: grab
    }
}
