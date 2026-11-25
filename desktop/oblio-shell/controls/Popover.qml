// SPDX-License-Identifier: GPL-3.0-or-later
// A shell menu: a card next to what opened it. While it's open, a click anywhere else only closes
// it (nothing underneath gets it) and keybinds don't reach the windows (services/Menus.qml).
// The content goes inside, with width: parent.width; the card follows its height.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

Scope {
    id: pop

    property var screen: Quickshell.screens[0]
    property bool shown: false
    property real cardWidth: 280
    property real padding: 8
    // what it opens from, in the screen's coordinates, and the screen edge that thing sits on:
    // the card opens away from it
    property rect target: Qt.rect(0, 0, 0, 0)
    property string edge: "top"
    property var owner: null          // whoever opened it (the bar marks that widget as open)
    default property alias content: inner.data

    function open(screen, target, edge, owner) {
        pop.screen = screen
        pop.target = target
        pop.edge = edge
        pop.owner = owner ?? null
        shown = true
    }
    function close() { shown = false }
    // on screen, fading out included: content can stay loaded until then
    readonly property bool showing: win.visible

    onShownChanged: {
        if (shown) Menus.add(pop)
        else { Menus.remove(pop); owner = null }
    }
    Component.onDestruction: Menus.remove(pop)

    PanelWindow {
        id: win
        visible: pop.shown || card.opacity > 0
        screen: pop.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: pop.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "oblio-popup"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: pop.close()
            onWheel: {}
        }

        Rectangle {
            id: card
            readonly property real gap: 8
            readonly property real cx: pop.target.x + pop.target.width / 2
            readonly property real cy: pop.target.y + pop.target.height / 2
            width: pop.cardWidth
            height: inner.childrenRect.height + 2 * pop.padding
            x: {
                const want = pop.edge === "left" ? pop.target.x + pop.target.width + gap
                    : pop.edge === "right" ? pop.target.x - width - gap : cx - width / 2
                return Math.max(gap, Math.min(want, win.width - width - gap))
            }
            y: {
                const want = pop.edge === "top" ? pop.target.y + pop.target.height + gap
                    : pop.edge === "bottom" ? pop.target.y - height - gap : cy - height / 2
                return Math.max(gap, Math.min(want, win.height - height - gap))
            }
            readonly property var look: Styles.look("menus")
            radius: Theme.radius
            color: look.fill
            border.width: 1
            border.color: look.line
            opacity: pop.shown ? 1 : 0
            focus: pop.shown

            // slides out of the edge it opened from
            transform: Translate {
                readonly property real d: pop.shown ? 0 : 6
                x: pop.edge === "left" ? -d : pop.edge === "right" ? d : 0
                y: pop.edge === "top" ? -d : pop.edge === "bottom" ? d : 0
                Behavior on x { NumberAnimation { duration: Theme.ms(160); easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: Theme.ms(160); easing.type: Easing.OutCubic } }
            }
            Behavior on opacity { NumberAnimation { duration: Theme.ms(140); easing.type: Easing.OutCubic } }

            Keys.onEscapePressed: pop.close()

            // clicks on the card stay on the card
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: {} }

            Item {
                id: inner
                x: pop.padding
                y: pop.padding
                width: parent.width - 2 * pop.padding
            }
        }
    }
}
