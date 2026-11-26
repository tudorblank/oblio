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

    property alias shown: overlay.shown
    property int page: 0
    // a page opens at its top
    onPageChanged: flick.contentY = 0

    readonly property var pages: [
        { title: "Display", icon: Icons.display, subtitle: "Resolution, refresh rate, scale and arrangement", content: displayPage },
        { title: "Bar", icon: Icons.bar, subtitle: "Its widgets, where it sits and its shape", content: barPage },
        { title: "Dock", icon: Icons.dock, subtitle: "Where it sits, its shape and its icons", content: dockPage },
        { title: "Windows", icon: Icons.windows, subtitle: "Tiling, gaps, borders and focus", content: windowsPage },
        { title: "Appearance", icon: Icons.appearance, subtitle: "Light or dark, accent color, styles, fonts and animations", content: lookPage },
        { title: "Wallpaper", icon: Icons.wallpaper, subtitle: "Pictures for the desktop and the lock screen", content: wallpaperPage },
        { title: "Input", icon: Icons.input, subtitle: "Mouse, touchpad and keyboard", content: inputPage },
        { title: "Battery", icon: Icons.battery[8], subtitle: "Its state and the low and charged alerts", content: batteryPage },
    ].concat(Parts.list.filter(p => p.options).map(p => ({ title: p.name, icon: p.icon, subtitle: p.subtitle ?? "", content: partPage, part: p.id })))

    function open() {
        Displays.refresh()
        overlay.open()
    }
    function close() { shown = false }
    function openPage(title) {
        const i = pages.findIndex(p => p.title.toLowerCase() === title.toLowerCase())
        if (i >= 0) page = i
        open()
    }
    Connections {
        target: Menus
        function onRequested(part, action, arg) {
            if (part !== "settings") return
            if (action === "toggle") root.shown ? root.close() : root.open()
            else root.openPage(arg)
        }
    }

    // closing the panel doesn't keep a display change nobody confirmed
    onShownChanged: if (!shown) {
        Displays.revert()
        Displays.discard()
        Wallpaper.discard()
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
            start = mapToItem(overlay.window.contentItem, m.x, m.y)
            from = Qt.rect(card.x, card.y, card.width, card.height)
        }
        onPositionChanged: m => {
            const p = mapToItem(overlay.window.contentItem, m.x, m.y)
            const dx = p.x - start.x, dy = p.y - start.y
            if (hx > 0) card.width = Math.max(card.minWidth, Math.min(from.width + dx, overlay.window.width - from.x - 8))
            if (hy > 0) card.height = Math.max(card.minHeight, Math.min(from.height + dy, overlay.window.height - from.y - 8))
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

    Overlay {
        id: overlay
        part: "settings"
        dim: 0.3
        fading: card
        // steps aside while a file picker (a normal window) is open
        hidden: Wallpaper.picking || User.picking

        Card {
            id: card
            part: "settings"
            // dragged by its top strip, resized from any edge; keeps its place while the shell runs
            readonly property int minWidth: 640
            readonly property int minHeight: 480
            property bool placed: false
            function fit() {
                // a hidden window's size is meaningless
                if (!overlay.window.visible || overlay.window.width < minWidth || overlay.window.height < minHeight) return
                width = Math.max(Math.min(width, overlay.window.width - 16), Math.min(minWidth, overlay.window.width - 16))
                height = Math.max(Math.min(height, overlay.window.height - 16), Math.min(minHeight, overlay.window.height - 16))
                if (!placed) { x = (overlay.window.width - width) / 2; y = (overlay.window.height - height) / 2; placed = true }
                x = Math.max(8, Math.min(x, overlay.window.width - width - 8))
                y = Math.max(8, Math.min(y, overlay.window.height - height - 8))
            }
            width: 880
            height: 600
            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.97
            focus: true

            Behavior on opacity { NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: Theme.ms(220); easing.type: Easing.OutCubic } }

            Keys.onEscapePressed: root.shown = false
            onVisibleChanged: if (visible) { fit(); forceActiveFocus() }
            Connections {
                target: overlay.window
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
                    xAxis.maximum: overlay.window.width - card.width - 8
                    yAxis.minimum: 8
                    yAxis.maximum: overlay.window.height - card.height - 8
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

                // scroll bar, when the page is taller than the panel: drag its handle (or click the
                // track) like in a browser. The handle fades in while the page moves or the pointer is
                // on the bar's strip, out a second after; the strip itself always takes the pointer
                Item {
                    id: scrollBar
                    readonly property real range: flick.contentHeight - flick.height
                    readonly property bool busy: barArea.containsMouse || barArea.pressed || flick.moving
                    property bool shown: false
                    visible: range > 0
                    anchors.right: flick.right
                    anchors.rightMargin: 4
                    y: flick.y + 4
                    width: 14
                    height: flick.height - 8
                    function show() { shown = true; hideTimer.restart() }
                    onBusyChanged: show()
                    Connections {
                        target: flick
                        function onContentYChanged() { scrollBar.show() }
                    }
                    Timer {
                        id: hideTimer
                        interval: 1000
                        onTriggered: if (scrollBar.busy) restart(); else scrollBar.shown = false
                    }

                    Rectangle {
                        id: handle
                        readonly property real travel: scrollBar.height - height
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        width: barArea.containsMouse || barArea.pressed ? 6 : 4
                        height: Math.max(28, flick.height / Math.max(flick.contentHeight, 1) * scrollBar.height)
                        y: scrollBar.range > 0 ? flick.contentY / scrollBar.range * travel : 0
                        radius: width / 2
                        color: Theme.tint(Theme.text, barArea.pressed ? 0.5 : barArea.containsMouse ? 0.38 : 0.25)
                        opacity: scrollBar.shown ? 1 : 0
                        Behavior on opacity { Anim {} }
                        Behavior on width { Anim { duration: Theme.motionQuick } }
                    }
                    MouseArea {
                        id: barArea
                        anchors.fill: parent
                        hoverEnabled: true
                        preventStealing: true
                        property real grab: 0
                        function scrollTo(y) {
                            const f = Math.max(0, Math.min(1, (y - grab) / Math.max(1, handle.travel)))
                            flick.contentY = f * scrollBar.range
                        }
                        onPressed: m => {
                            // on the handle: keep where it was grabbed; on the track: centre it there
                            grab = m.y >= handle.y && m.y <= handle.y + handle.height ? m.y - handle.y : handle.height / 2
                            scrollTo(m.y)
                        }
                        onPositionChanged: m => { if (pressed) scrollTo(m.y) }
                    }
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
    // a part's page, built from its options (services/Parts.qml)
    Component { id: partPage; PartPage { part: root.pages[root.page].part } }
}
