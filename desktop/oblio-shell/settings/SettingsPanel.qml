// SPDX-License-Identifier: GPL-3.0-or-later
// Oblio's settings (SUPER+I, or `qs -p ~/.config/oblio-shell ipc call settings toggle`).

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.controls
import qs.settings.pages

Scope {
    id: root

    property bool shown: false
    property int page: 0
    // a page opens at its top
    onPageChanged: flick.contentY = 0
    property var screen: Quickshell.screens[0]

    readonly property var pages: [
        { title: "Display", icon: Icons.display, subtitle: "Resolution, refresh rate, scale and arrangement", content: displayPage },
        { title: "Bar", icon: Icons.bar, subtitle: "Its widgets, where it sits and its shape", content: barPage },
        { title: "Dock", icon: Icons.dock, subtitle: "Where it sits, its shape and its icons", content: dockPage },
        { title: "Windows", icon: Icons.windows, subtitle: "Tiling, gaps, borders and focus", content: windowsPage },
        { title: "Appearance", icon: Icons.appearance, subtitle: "Light or dark, accent color, styles, fonts and animations", content: lookPage },
        { title: "Wallpaper", icon: Icons.wallpaper, subtitle: "Pictures for the desktop and the lock screen", content: wallpaperPage },
        { title: "Input", icon: Icons.input, subtitle: "Mouse, touchpad and keyboard", content: inputPage },
        { title: "Battery", icon: Icons.battery[8], subtitle: "Its state and the low and charged alerts", content: batteryPage },
    ]

    function open() {
        const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        screen = Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0]
        Displays.refresh()
        shown = true
    }
    function close() { shown = false }
    function openPage(title) {
        const i = pages.findIndex(p => p.title.toLowerCase() === title.toLowerCase())
        if (i >= 0) page = i
        open()
    }
    Connections {
        target: Menus
        function onSettingsRequested(page) { root.openPage(page) }
    }

    onShownChanged: {
        if (shown) {
            Menus.add(root)
        } else {
            Menus.remove(root)
            // closing the panel doesn't keep a display change nobody confirmed
            Displays.revert()
            Displays.discard()
            Wallpaper.discard()
        }
    }

    // edges and corners resize: hx/hy say which side moves (-1 left/top, 1 right/bottom)
    component Grip: MouseArea {
        property int hx
        property int hy
        property point start
        property rect from
        readonly property int t: 8
        x: hx < 0 ? -t / 2 : hx > 0 ? card.width - t / 2 : t
        y: hy < 0 ? -t / 2 : hy > 0 ? card.height - t / 2 : t
        width: hx === 0 ? card.width - 2 * t : t
        height: hy === 0 ? card.height - 2 * t : t
        z: 10
        preventStealing: true
        cursorShape: hx === 0 ? Qt.SizeVerCursor : hy === 0 ? Qt.SizeHorCursor
                   : hx === hy ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
        onPressed: m => {
            start = mapToItem(win.contentItem, m.x, m.y)
            from = Qt.rect(card.x, card.y, card.width, card.height)
        }
        onPositionChanged: m => {
            const p = mapToItem(win.contentItem, m.x, m.y)
            const dx = p.x - start.x, dy = p.y - start.y
            if (hx > 0) card.width = Math.max(card.minWidth, Math.min(from.width + dx, win.width - from.x - 8))
            if (hy > 0) card.height = Math.max(card.minHeight, Math.min(from.height + dy, win.height - from.y - 8))
            if (hx < 0) {
                const w = Math.max(card.minWidth, Math.min(from.width - dx, from.x + from.width - 8))
                card.x = from.x + from.width - w
                card.width = w
            }
            if (hy < 0) {
                const h = Math.max(card.minHeight, Math.min(from.height - dy, from.y + from.height - 8))
                card.y = from.y + from.height - h
                card.height = h
            }
        }
    }

    // a floating pill at the bottom of the panel: a message, a note, its buttons
    component Banner: Rectangle {
        property string text
        property string note: ""
        property bool accent: false
        default property alias buttons: row.data
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        width: row.implicitWidth + 32
        height: 50
        radius: height / 2
        color: Theme.popup
        border.width: 1
        border.color: accent ? Theme.tint(Theme.accent, 0.55) : Theme.hairline

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 12
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: parent.parent.text
                color: Theme.text
                font.family: Theme.fontUi
                font.pixelSize: Theme.textBody
                font.weight: Font.Medium
            }
            Text {
                visible: text !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: parent.parent.note
                color: Theme.subtext
                font.family: Theme.fontUi
                font.pixelSize: Theme.textLabel
                font.features: { "tnum": 1 }
            }
        }
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { if (root.shown) root.shown = false; else root.open() }
        function open(): void { root.open() }
        // qs -p ~/.config/oblio-shell ipc call settings page Bar
        function page(title: string): void { root.openPage(title) }
        function close(): void { root.shown = false }
        // qs -p ~/.config/oblio-shell ipc call settings set gapsOut 10   (value is JSON: 10, true, '"#5b9cf5"')
        function set(key: string, value: string): void { Settings.set(key, JSON.parse(value)) }
    }

    PanelWindow {
        id: win
        // steps aside while a file picker (a normal window) is open
        visible: (root.shown || dim.opacity > 0) && !Wallpaper.picking && !User.picking
        screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "oblio-settings"

        Rectangle {
            id: dim
            anchors.fill: parent
            color: Theme.scrim
            opacity: root.shown ? 0.3 : 0

            Behavior on opacity { NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutCubic } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.shown = false
            }
        }

        Rectangle {
            id: card
            // dragged by its top strip, resized from any edge; keeps its place while the shell runs
            readonly property int minWidth: 640
            readonly property int minHeight: 480
            property bool placed: false
            function fit() {
                // a hidden window's size is meaningless
                if (!win.visible || win.width < minWidth || win.height < minHeight) return
                width = Math.max(Math.min(width, win.width - 16), Math.min(minWidth, win.width - 16))
                height = Math.max(Math.min(height, win.height - 16), Math.min(minHeight, win.height - 16))
                if (!placed) { x = (win.width - width) / 2; y = (win.height - height) / 2; placed = true }
                x = Math.max(8, Math.min(x, win.width - width - 8))
                y = Math.max(8, Math.min(y, win.height - height - 8))
            }
            width: 880
            height: 600
            readonly property var look: Styles.look("settings")
            radius: Theme.radius
            color: look.fill
            border.width: 1
            border.color: look.line
            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.97
            focus: true

            Behavior on opacity { NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: Theme.ms(220); easing.type: Easing.OutCubic } }

            Keys.onEscapePressed: root.shown = false
            onVisibleChanged: if (visible) { fit(); forceActiveFocus() }
            Connections {
                target: win
                function onWidthChanged() { card.fit() }
                function onHeightChanged() { card.fit() }
            }

            // clicks on the card don't fall through to the dim layer
            MouseArea { anchors.fill: parent }

            // the top strip moves the panel
            Item {
                width: parent.width
                height: 64
                DragHandler {
                    target: card
                    cursorShape: active ? Qt.ClosedHandCursor : Qt.ArrowCursor
                    xAxis.minimum: 8
                    xAxis.maximum: win.width - card.width - 8
                    yAxis.minimum: 8
                    yAxis.maximum: win.height - card.height - 8
                }
            }

            // sidebar
            Column {
                id: sidebar
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 14
                width: 200
                spacing: 4

                // who's logged in; hovering the picture offers to change it
                Column {
                    width: parent.width
                    topPadding: 10
                    bottomPadding: 14
                    spacing: 10

                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 68
                        height: 68

                        Avatar { size: 68 }

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "#8c000000"
                            opacity: faceArea.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.ms(140) } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 1
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Icons.edit
                                    color: "white"
                                    font.family: Theme.iconFont
                                    font.pixelSize: 18
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Edit"
                                    color: "white"
                                    font.family: Theme.fontUi
                                    font.pixelSize: Theme.textCaption
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        // a soft ring
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -3
                            radius: width / 2
                            color: "transparent"
                            border.width: 2
                            border.color: faceArea.containsMouse ? Theme.accent : Theme.hairline
                            Behavior on border.color { ColorAnimation { duration: Theme.ms(140) } }
                        }

                        MouseArea {
                            id: faceArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: User.pick()
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 1
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: User.display
                            color: Theme.text
                            font.family: Theme.fontUi
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            visible: User.display !== User.name
                            text: User.name
                            color: Theme.subtext
                            font.family: Theme.fontUi
                            font.pixelSize: Theme.textLabel
                        }
                    }
                }

                Repeater {
                    model: root.pages

                    Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool selected: root.page === index
                        width: sidebar.width
                        height: 40
                        radius: 12
                        color: selected ? Theme.tint(Theme.accent, 0.16) : area.containsMouse ? Theme.hover : "transparent"

                        Behavior on color { ColorAnimation { duration: Theme.ms(140) } }

                        Text {
                            id: icon
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            horizontalAlignment: Text.AlignHCenter
                            text: parent.modelData.icon
                            color: parent.selected ? Theme.accent : Theme.subtext
                            font.family: Theme.iconFont
                            font.pixelSize: 15
                        }

                        Text {
                            font.family: Theme.fontUi
                            anchors.left: icon.right
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.modelData.title
                            color: parent.selected ? Theme.accent : Theme.text
                            font.pixelSize: Theme.textTitle
                            font.weight: parent.selected ? Font.DemiBold : Font.Normal
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.page = parent.index
                        }
                    }
                }
            }

            Rectangle {
                id: divider
                anchors.left: sidebar.right
                anchors.leftMargin: 14
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: 20
                anchors.bottomMargin: 20
                width: 1
                color: Theme.hairline
            }

            // page
            Item {
                anchors.left: divider.right
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                Column {
                    id: header
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 28
                    anchors.topMargin: 24
                    spacing: 4

                    Text {
                        font.family: Theme.fontUi
                        text: root.pages[root.page].title
                        color: Theme.text
                        font.pixelSize: Theme.textHeading
                        font.weight: Font.DemiBold
                    }

                    Text {
                        font.family: Theme.fontUi
                        text: root.pages[root.page].subtitle
                        color: Theme.subtext
                        font.pixelSize: Theme.textBody
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 22
                    text: Icons.close
                    color: closeArea.containsMouse ? Theme.text : Theme.subtext
                    font.family: Theme.iconFont
                    font.pixelSize: 16

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shown = false
                    }
                }

                Flickable {
                    id: flick
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: header.bottom
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 20
                    clip: true
                    contentHeight: loader.height + 28
                    boundsBehavior: Flickable.StopAtBounds

                    Loader {
                        id: loader
                        x: 28
                        width: parent.width - 56
                        sourceComponent: root.pages[root.page].content
                    }
                }

                // scroll bar, when the page is taller than the panel
                Rectangle {
                    visible: flick.contentHeight > flick.height
                    anchors.right: flick.right
                    anchors.rightMargin: 8
                    y: flick.y + flick.visibleArea.yPosition * flick.height
                    width: 4
                    height: flick.visibleArea.heightRatio * flick.height
                    radius: 2
                    color: Theme.tint(Theme.text, 0.25)
                }
            }

            Grip { hx: -1; hy: 0 }
            Grip { hx: 1; hy: 0 }
            Grip { hx: 0; hy: -1 }
            Grip { hx: 0; hy: 1 }
            Grip { hx: -1; hy: -1 }
            Grip { hx: 1; hy: -1 }
            Grip { hx: -1; hy: 1 }
            Grip { hx: 1; hy: 1 }

            // display choices not applied yet (the page may be scrolled away from them), and after a
            // change: keep it, or it goes back by itself
            Banner {
                visible: Displays.dirty && Displays.pending === null && root.pages[root.page].content === displayPage
                text: "Display changes not applied yet"
                Button { text: "Cancel"; onClicked: Displays.discard() }
                Button { text: "Apply"; primary: true; onClicked: Displays.apply(Displays.current, Displays.edited) }
            }
            Banner {
                visible: Displays.pending !== null
                text: "Keep these display settings?"
                note: Displays.pending ? `Going back in ${Displays.pending.left} s` : ""
                accent: true
                Button { text: "Go back"; onClicked: Displays.revert() }
                Button { text: "Keep"; primary: true; onClicked: Displays.keep() }
            }
            Banner {
                visible: Wallpaper.dirty && root.pages[root.page].content === wallpaperPage
                text: "Apply the wallpaper changes?"
                accent: true
                Button { text: "Cancel"; onClicked: Wallpaper.discard() }
                Button { text: "Apply"; primary: true; onClicked: Wallpaper.apply() }
            }
        }
    }

    Component { id: displayPage; DisplayPage {} }

    Component { id: barPage; BarPage {} }

    Component { id: dockPage; DockPage {} }

    Component { id: windowsPage; WindowsPage {} }

    Component { id: lookPage; AppearancePage {} }

    Component { id: inputPage; InputPage {} }
    Component { id: batteryPage; BatteryPage {} }

    Component { id: wallpaperPage; WallpaperPage {} }
}
