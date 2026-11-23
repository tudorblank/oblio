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
    property var screen: Quickshell.screens[0]

    readonly property var pages: [
        { title: "Display", icon: "\u{f0379}", subtitle: "Resolution, refresh rate, scale and arrangement", content: displayPage },
        { title: "Dock", icon: "\u{f10a9}", subtitle: "Size, look and behavior of the dock", content: dockPage },
        { title: "Windows", icon: "", subtitle: "Tiling, gaps, borders and focus", content: windowsPage },
        { title: "Appearance", icon: "", subtitle: "Light or dark, accent color, fonts and effects", content: lookPage },
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
                    font.family: Theme.fontUi
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
                        color: selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16) : area.containsMouse ? Theme.hover : "transparent"

                        Behavior on color { ColorAnimation { duration: 140 } }

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
                        font.family: Theme.fontUi
                        text: root.pages[root.page].title
                        color: Theme.text
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                    }

                    Text {
                        font.family: Theme.fontUi
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
                    color: Theme.tint(Theme.text, 0.25)
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
                color: Theme.popup
                border.width: 1
                border.color: Theme.hairline

                Row {
                    id: applyRow
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        font.family: Theme.fontUi
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
                color: Theme.popup
                border.width: 1
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.55)

                Row {
                    id: confirmRow
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        font.family: Theme.fontUi
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Keep these display settings?"
                        color: Theme.text
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }
                    Text {
                        font.family: Theme.fontUi
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

    Component { id: displayPage; DisplayPage {} }

    Component { id: dockPage; DockPage {} }

    Component { id: windowsPage; WindowsPage {} }

    Component { id: lookPage; AppearancePage {} }

    Component { id: inputPage; InputPage {} }
}
