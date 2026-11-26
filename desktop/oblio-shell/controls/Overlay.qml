// SPDX-License-Identifier: GPL-3.0-or-later
// A shell part's window over everything (settings, search, popovers, the color picker): the one
// way the shell opens something on top. While it's shown it has the keyboard, a click outside its
// content closes it, keybinds don't reach the windows (services/Menus.qml), and it opens on the
// focused screen unless told one. Content goes inside, placed in the full-screen window.
//   exclusive  opening it closes the other menus
//   dim        how much it darkens the screen behind (0..1)
//   fading     the item that fades out on close: the window stays until it has
//   hidden     steps aside for a moment (a file picker is open), shown or not
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

Scope {
    id: ov

    required property string part
    property string namespace: Parts.namespace(part)
    property var screen: Quickshell.screens[0]
    property bool shown: false
    property bool exclusive: false
    property real dim: 0
    property Item fading: null
    property bool hidden: false
    readonly property bool showing: win.visible
    readonly property alias window: win
    default property alias content: body.data

    function focusedScreen() {
        const name = Hyprland.focusedMonitor?.name ?? ""
        return Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0]
    }
    function open(screen) {
        if (exclusive) Menus.closeAll()
        ov.screen = screen ?? focusedScreen()
        shown = true
    }
    function close() { shown = false }
    function toggle() { shown ? close() : open() }

    onShownChanged: shown ? Menus.add(ov) : Menus.remove(ov)
    Component.onDestruction: Menus.remove(ov)

    PanelWindow {
        id: win
        visible: (ov.shown || (ov.fading?.opacity ?? 0) > 0) && !ov.hidden
        screen: ov.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: ov.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: ov.namespace

        Rectangle {
            anchors.fill: parent
            visible: ov.dim > 0
            color: Theme.scrim
            opacity: ov.shown ? ov.dim : 0
            Behavior on opacity { NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutCubic } }
        }
        // a click outside closes it and reaches nothing underneath
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: ov.close()
            onWheel: {}
        }
        Item {
            id: body
            anchors.fill: parent
        }
    }
}
