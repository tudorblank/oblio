// SPDX-License-Identifier: GPL-3.0-or-later
// Oblio's settings (SUPER+I, or `qs -c oblio ipc call settings toggle`).

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
        { title: "Dock", icon: "", subtitle: "Size, look and behavior of the dock", content: dockPage },
        { title: "Windows", icon: "", subtitle: "Tiling, gaps, borders and focus", content: windowsPage },
        { title: "Appearance", icon: "", subtitle: "Accent color, blur and animations", content: lookPage },
        { title: "Input", icon: "", subtitle: "Mouse, touchpad and keyboard", content: inputPage },
    ]

    function open() {
        const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        screen = Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0]
        shown = true
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { if (root.shown) root.shown = false; else root.open() }
        function open(): void { root.open() }
        function close(): void { root.shown = false }
        // qs -c oblio ipc call settings set gapsOut 10   (value is JSON: 10, true, '"#5b9cf5"')
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
            width: 880
            height: 600
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
                    title: "Auto-hide"
                    description: "Slides away until the pointer touches the bottom edge"
                    Toggle {
                        checked: Settings.opts.dockAutoHide
                        onToggled: v => Settings.set("dockAutoHide", v)
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
                SettingRow {
                    title: "Focus follows mouse"
                    description: "Hovering a window focuses it, no click needed"
                    Toggle {
                        checked: Settings.opts.focusFollowsMouse
                        onToggled: v => Settings.set("focusFollowsMouse", v)
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
