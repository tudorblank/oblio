// SPDX-License-Identifier: GPL-3.0-or-later
// Oblio's settings (SUPER+I, or `qs -p ~/.config/oblio-shell ipc call settings toggle`).

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property bool shown: false
    property int page: 0
    property var screen: Quickshell.screens[0]

    readonly property var pages: [
        { title: "Display", icon: "\u{f0379}", subtitle: "Resolution, refresh rate, scale and arrangement", content: displayPage },
        { title: "Dock", icon: "\u{f10a9}", subtitle: "Size, look and behavior of the dock", content: dockPage },
        { title: "Windows", icon: "", subtitle: "Tiling, gaps, borders and focus", content: windowsPage },
        { title: "Appearance", icon: "", subtitle: "Accent color, blur and animations", content: lookPage },
        { title: "Input", icon: "", subtitle: "Mouse, touchpad and keyboard", content: inputPage },
    ]

    function open() {
        const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        screen = Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0]
        Displays.refresh()
        shown = true
    }

    // closing the panel doesn't keep a display change nobody confirmed
    onShownChanged: if (!shown) { Displays.revert(); Displays.discard() }

    IpcHandler {
        target: "settings"
        function toggle(): void { if (root.shown) root.shown = false; else root.open() }
        function open(): void { root.open() }
        function close(): void { root.shown = false }
        // qs -p ~/.config/oblio-shell ipc call settings set gapsOut 10   (value is JSON: 10, true, '"#5b9cf5"')
        function set(key: string, value: string): void { Settings.set(key, JSON.parse(value)) }
    }

    PanelWindow {
        id: win
        visible: root.shown || dim.opacity > 0
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
            color: "black"
            opacity: root.shown ? 0.3 : 0

            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.shown = false
            }
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.min(880, win.width - 40)
            height: Math.min(600, win.height - 40)
            radius: 22
            color: Theme.panel
            border.width: 1
            border.color: Theme.hairline
            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.97
            focus: true

            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            Keys.onEscapePressed: root.shown = false
            onVisibleChanged: if (visible) forceActiveFocus()

            // clicks on the card don't fall through to the dim layer
            MouseArea { anchors.fill: parent }

            // sidebar
            Column {
                id: sidebar
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 14
                width: 200
                spacing: 4

                Text {
                    leftPadding: 12
                    topPadding: 10
                    bottomPadding: 16
                    text: "Settings"
                    color: Theme.text
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
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
                        color: selected ? Qt.rgba(Settings.accent.r, Settings.accent.g, Settings.accent.b, 0.16) : area.containsMouse ? Theme.hover : "transparent"

                        Behavior on color { ColorAnimation { duration: 140 } }

                        Text {
                            id: icon
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            horizontalAlignment: Text.AlignHCenter
                            text: parent.modelData.icon
                            color: parent.selected ? Settings.accent : Theme.subtext
                            font.family: Theme.iconFont
                            font.pixelSize: 15
                        }

                        Text {
                            anchors.left: icon.right
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.modelData.title
                            color: parent.selected ? Settings.accent : Theme.text
                            font.pixelSize: 14
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
                        text: root.pages[root.page].title
                        color: Theme.text
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: root.pages[root.page].subtitle
                        color: Theme.subtext
                        font.pixelSize: 13
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 22
                    text: ""
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
                    color: "#40ffffff"
                }
            }

            // display choices not applied yet; the page may be scrolled away from them
            Rectangle {
                visible: Displays.dirty && Displays.pending === null && root.pages[root.page].content === displayPage
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 18
                width: applyRow.implicitWidth + 32
                height: 50
                radius: 25
                color: "#f81c1c21"
                border.width: 1
                border.color: Theme.hairline

                Row {
                    id: applyRow
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Display changes not applied yet"
                        color: Theme.text
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }
                    Button { text: "Cancel"; onClicked: Displays.discard() }
                    Button { text: "Apply"; primary: true; onClicked: Displays.apply(Displays.current, Displays.edited) }
                }
            }

            // after a display change: keep it, or it goes back by itself
            Rectangle {
                visible: Displays.pending !== null
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 18
                width: confirmRow.implicitWidth + 32
                height: 50
                radius: 25
                color: "#f81c1c21"
                border.width: 1
                border.color: Qt.rgba(Settings.accent.r, Settings.accent.g, Settings.accent.b, 0.55)

                Row {
                    id: confirmRow
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Keep these display settings?"
                        color: Theme.text
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Displays.pending ? `Going back in ${Displays.pending.left} s` : ""
                        color: Theme.subtext
                        font.pixelSize: 12
                        font.features: { "tnum": 1 }
                    }
                    Button { text: "Go back"; onClicked: Displays.revert() }
                    Button { text: "Keep"; primary: true; onClicked: Displays.keep() }
                }
            }
        }
    }

    Component {
        id: displayPage

        Column {
            id: dp
            spacing: 22

            readonly property var monitors: Displays.monitors
            readonly property var mon: Displays.current
            readonly property var cfg: Displays.edited
            readonly property bool multi: monitors.length > 1
            readonly property int enabledCount: monitors.filter(m => !m.disabled).length
            readonly property real recommended: mon && cfg ? Displays.recommended(mon, cfg.resolution) : 1

            function edit(changes) { Displays.edit(changes) }
            function percent(s) { return Math.round(s * 100) + "%" }
            function looks(res, s) {
                const [w, h] = res.split("x").map(Number)
                return `${Math.round(w / s)} × ${Math.round(h / s)}`
            }

            Text {
                visible: !dp.mon
                text: "No displays found"
                color: Theme.subtext
                font.pixelSize: 13
            }

            Segmented {
                visible: dp.multi
                options: dp.monitors.map((m, i) => ({ value: i, label: Displays.label(m) }))
                value: Displays.selected
                onPicked: v => Displays.selected = v
            }

            SettingGroup {
                visible: dp.mon !== null
                title: dp.mon ? [Displays.label(dp.mon).toUpperCase(), Displays.label(dp.mon) === dp.mon.name ? "" : dp.mon.name,
                    Displays.inches(dp.mon) ? Displays.inches(dp.mon).toFixed(1) + "″" : ""].filter(t => t).join("  ·  ") : ""

                SettingRow {
                    title: "Resolution"
                    Dropdown {
                        enabled: dp.cfg && !dp.cfg.disabled && !dp.cfg.mirror
                        options: dp.mon ? Displays.resolutions(dp.mon).map(r => ({
                            value: r.value, label: r.value.replace("x", " × "), tag: r.native ? "Native" : "",
                        })) : []
                        value: dp.cfg ? dp.cfg.resolution : ""
                        onPicked: v => dp.edit({
                            resolution: v,
                            rate: Displays.closestRate(dp.mon, v, dp.cfg.rate),
                            scale: Displays.scales(v).includes(dp.cfg.scale) ? dp.cfg.scale : Displays.recommended(dp.mon, v),
                        })
                    }
                }
                SettingRow {
                    title: "Refresh rate"
                    Dropdown {
                        enabled: dp.cfg && !dp.cfg.disabled && !dp.cfg.mirror
                        options: dp.cfg ? Displays.rates(dp.mon, dp.cfg.resolution).map(r => ({
                            value: r, label: (Math.round(r * 100) / 100) + " Hz",
                        })) : []
                        value: dp.cfg ? dp.cfg.rate : 0
                        onPicked: v => dp.edit({ rate: v })
                    }
                }
                SettingRow {
                    title: "Scale"
                    description: dp.cfg ? `How big everything is. At ${dp.percent(dp.cfg.scale)} the screen fits as much as a ${dp.looks(dp.cfg.resolution, dp.cfg.scale)} one` : ""
                    Dropdown {
                        enabled: dp.cfg && !dp.cfg.disabled && !dp.cfg.mirror
                        options: dp.cfg ? Displays.scales(dp.cfg.resolution).map(s => ({
                            value: s,
                            label: dp.percent(s),
                            tag: s === dp.recommended ? "Recommended" : "",
                            note: dp.looks(dp.cfg.resolution, s),
                        })) : []
                        value: dp.cfg ? dp.cfg.scale : 1
                        onPicked: v => dp.edit({ scale: v })
                    }
                }
                SettingRow {
                    title: "Rotation"
                    Segmented {
                        enabled: dp.cfg && !dp.cfg.disabled && !dp.cfg.mirror
                        opacity: enabled ? 1 : 0.4
                        options: [{ value: 0, label: "Normal" }, { value: 1, label: "90°" }, { value: 2, label: "180°" }, { value: 3, label: "270°" }]
                        value: dp.cfg ? dp.cfg.transform : 0
                        onPicked: v => dp.edit({ transform: v })
                    }
                }
            }

            SettingGroup {
                visible: dp.multi && dp.mon !== null
                title: "ARRANGEMENT"

                SettingRow {
                    title: "Use this display"
                    description: dp.cfg && !dp.cfg.disabled && dp.enabledCount <= 1 ? "The only display that's on can't be turned off" : ""
                    Toggle {
                        enabled: dp.cfg && (dp.cfg.disabled || dp.enabledCount > 1)
                        checked: dp.cfg ? !dp.cfg.disabled : true
                        onToggled: v => dp.edit({ disabled: !v })
                    }
                }
                SettingRow {
                    title: "Position"
                    description: "Where it sits next to the other displays"
                    Segmented {
                        enabled: dp.cfg && !dp.cfg.disabled && !dp.cfg.mirror
                        opacity: enabled ? 1 : 0.4
                        options: [{ value: "auto", label: "Auto" }, { value: "auto-left", label: "Left" }, { value: "auto-right", label: "Right" },
                                  { value: "auto-up", label: "Above" }, { value: "auto-down", label: "Below" }]
                        value: dp.cfg ? dp.cfg.position : "auto"
                        onPicked: v => dp.edit({ position: v })
                    }
                }
                SettingRow {
                    title: "Mirror"
                    description: "Show the same picture as another display"
                    Dropdown {
                        enabled: dp.cfg && !dp.cfg.disabled
                        options: [{ value: "", label: "Off" }].concat(dp.monitors
                            .filter(m => dp.mon && m.name !== dp.mon.name && !m.disabled)
                            .map(m => ({ value: m.name, label: Displays.label(m), note: m.name })))
                        value: dp.cfg ? dp.cfg.mirror : ""
                        onPicked: v => dp.edit({ mirror: v })
                    }
                }
            }

            // room for the floating apply bar under the last row
            Item {
                visible: dp.mon !== null
                width: parent.width
                height: 30 + 56

                Button {
                    text: "Use defaults"
                    enabled: Displays.pending === null
                    onClicked: { Displays.discard(); Displays.reset(dp.mon) }
                }
            }
        }
    }

    Component {
        id: dockPage

        Column {
            spacing: 22

            SettingGroup {
                title: "SIZE AND LOOK"

                SettingRow {
                    title: "Size"
                    description: "Height of the dock, icons scale with it"
                    ValueSlider {
                        from: 40; to: 96; unit: " px"
                        value: Settings.opts.dockSize
                        onMoved: v => Settings.set("dockSize", v)
                    }
                }
                SettingRow {
                    title: "Glass tint"
                    description: "How dark the dock's glass is"
                    ValueSlider {
                        from: 10; to: 90; unit: "%"
                        value: Settings.opts.dockOpacity
                        onMoved: v => Settings.set("dockOpacity", v)
                    }
                }
            }

            SettingGroup {
                title: "BEHAVIOR"

                SettingRow {
                    title: "Magnify on hover"
                    Toggle {
                        checked: Settings.opts.dockMagnify
                        onToggled: v => Settings.set("dockMagnify", v)
                    }
                }
                SettingRow {
                    title: "Show"
                    description: Settings.opts.dockMode === "autohide" ? "Hidden until the pointer touches the bottom edge"
                        : Settings.opts.dockMode === "smart" ? "Hides while a window reaches into it; the bottom edge brings it back"
                        : "Always on screen; windows stay clear of it"
                    Segmented {
                        options: [{ value: "always", label: "Always" }, { value: "autohide", label: "Auto-hide" }, { value: "smart", label: "Smart" }]
                        value: Settings.opts.dockMode
                        onPicked: v => Settings.set("dockMode", v)
                    }
                }
                SettingRow {
                    title: "Divider"
                    description: "A line between pinned apps and other open apps"
                    Toggle {
                        checked: Settings.opts.dockDivider
                        onToggled: v => Settings.set("dockDivider", v)
                    }
                }
            }
        }
    }

    Component {
        id: windowsPage

        Column {
            spacing: 22

            SettingGroup {
                title: "FOCUS"

                SettingRow {
                    title: "Typing follows the mouse"
                    description: "Hovering a window focuses it for the keyboard. Off: click a window to type in it"
                    Toggle {
                        checked: Settings.opts.focusKeyboard
                        onToggled: v => Settings.set("focusKeyboard", v)
                    }
                }
                SettingRow {
                    title: "Scrolling follows the mouse"
                    description: "Scroll the window under the pointer without clicking it first"
                    Toggle {
                        enabled: !Settings.opts.focusKeyboard
                        checked: Settings.opts.focusKeyboard || Settings.opts.focusScroll
                        onToggled: v => Settings.set("focusScroll", v)
                    }
                }
            }

            SettingGroup {
                title: "TILING"

                SettingRow {
                    title: "Layout"
                    description: "How tiled windows share the screen"
                    Segmented {
                        options: [{ value: "dwindle", label: "Dwindle" }, { value: "master", label: "Master" }, { value: "scrolling", label: "Scrolling" }]
                        value: Settings.opts.layout
                        onPicked: v => Settings.set("layout", v)
                    }
                }
                SettingRow {
                    title: "Gaps between windows"
                    ValueSlider {
                        from: 0; to: 30; unit: " px"
                        value: Settings.opts.gapsIn
                        onMoved: v => Settings.set("gapsIn", v)
                    }
                }
                SettingRow {
                    title: "Gaps at screen edges"
                    ValueSlider {
                        from: 0; to: 60; unit: " px"
                        value: Settings.opts.gapsOut
                        onMoved: v => Settings.set("gapsOut", v)
                    }
                }
            }

            SettingGroup {
                title: "WINDOWS"

                SettingRow {
                    title: "Border width"
                    ValueSlider {
                        from: 0; to: 6; unit: " px"
                        value: Settings.opts.borderSize
                        onMoved: v => Settings.set("borderSize", v)
                    }
                }
                SettingRow {
                    title: "Corner rounding"
                    ValueSlider {
                        from: 0; to: 24; unit: " px"
                        value: Settings.opts.rounding
                        onMoved: v => Settings.set("rounding", v)
                    }
                }
                SettingRow {
                    title: "Inactive window opacity"
                    ValueSlider {
                        from: 50; to: 100; unit: "%"
                        value: Settings.opts.inactiveOpacity
                        onMoved: v => Settings.set("inactiveOpacity", v)
                    }
                }
            }
        }
    }

    Component {
        id: lookPage

        Column {
            spacing: 22

            SettingGroup {
                title: "COLOR"

                SettingRow {
                    title: "Accent"
                    description: "The focused window's border and Oblio's controls"
                    Swatches {
                        value: Settings.opts.accent
                        onPicked: v => Settings.set("accent", v)
                    }
                }
            }

            SettingGroup {
                title: "EFFECTS"

                SettingRow {
                    title: "Blur"
                    description: "Frosted glass behind the dock, panels and see-through windows"
                    Toggle {
                        checked: Settings.opts.blur
                        onToggled: v => Settings.set("blur", v)
                    }
                }
                SettingRow {
                    title: "Blur strength"
                    ValueSlider {
                        from: 1; to: 16
                        value: Settings.opts.blurSize
                        onMoved: v => Settings.set("blurSize", v)
                    }
                }
                SettingRow {
                    title: "Animations"
                    Toggle {
                        checked: Settings.opts.animations
                        onToggled: v => Settings.set("animations", v)
                    }
                }
            }
        }
    }

    Component {
        id: inputPage

        Column {
            spacing: 22

            SettingGroup {
                title: "MOUSE AND TOUCHPAD"

                SettingRow {
                    title: "Pointer speed"
                    ValueSlider {
                        from: -1; to: 1; step: 0.05; decimals: 2
                        value: Settings.opts.sensitivity
                        onMoved: v => Settings.set("sensitivity", v)
                    }
                }
                SettingRow {
                    title: "Natural scrolling (mouse)"
                    description: "Content follows your fingers, like a phone"
                    Toggle {
                        checked: Settings.opts.naturalScroll
                        onToggled: v => Settings.set("naturalScroll", v)
                    }
                }
                SettingRow {
                    title: "Natural scrolling (touchpad)"
                    Toggle {
                        checked: Settings.opts.touchpadNaturalScroll
                        onToggled: v => Settings.set("touchpadNaturalScroll", v)
                    }
                }
            }

            SettingGroup {
                title: "KEYBOARD"

                SettingRow {
                    title: "Repeat rate"
                    description: "Characters per second while a key is held"
                    ValueSlider {
                        from: 10; to: 60; unit: "/s"
                        value: Settings.opts.repeatRate
                        onMoved: v => Settings.set("repeatRate", v)
                    }
                }
                SettingRow {
                    title: "Repeat delay"
                    description: "How long to hold a key before it repeats"
                    ValueSlider {
                        from: 150; to: 1000; step: 25; unit: " ms"
                        value: Settings.opts.repeatDelay
                        onMoved: v => Settings.set("repeatDelay", v)
                    }
                }
            }
        }
    }
}
