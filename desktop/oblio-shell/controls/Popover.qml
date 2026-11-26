// SPDX-License-Identifier: GPL-3.0-or-later
// A shell menu: a card next to what opened it. While it's open, a click anywhere else only closes
// it (nothing underneath gets it) and keybinds don't reach the windows (services/Menus.qml).
// The content goes inside, with width: parent.width; the card follows its height.
import QtQuick
import Quickshell
import qs.services

Scope {
    id: pop

    property alias shown: overlay.shown
    property real cardWidth: 280
    property real padding: 8
    // what it opens from, in the screen's coordinates, and the screen edge that thing sits on:
    // the card opens away from it
    property rect target: Qt.rect(0, 0, 0, 0)
    property string edge: "top"
    property var owner: null          // whoever opened it (the bar marks that widget as open)
    default property alias content: inner.data

    function open(screen, target, edge, owner) {
        pop.target = target
        pop.edge = edge
        pop.owner = owner ?? null
        overlay.open(screen)
    }
    function close() { overlay.close() }
    // on screen, fading out included: content can stay loaded until then
    readonly property bool showing: overlay.showing

    onShownChanged: if (!shown) owner = null

    Overlay {
        id: overlay
        part: "menus"
        fading: card

        Card {
            id: card
            part: "menus"
            readonly property real gap: 8
            readonly property real cx: pop.target.x + pop.target.width / 2
            readonly property real cy: pop.target.y + pop.target.height / 2
            width: pop.cardWidth
            height: inner.childrenRect.height + 2 * pop.padding
            x: {
                const want = pop.edge === "left" ? pop.target.x + pop.target.width + gap
                    : pop.edge === "right" ? pop.target.x - width - gap : cx - width / 2
                return Math.max(gap, Math.min(want, overlay.window.width - width - gap))
            }
            y: {
                const want = pop.edge === "top" ? pop.target.y + pop.target.height + gap
                    : pop.edge === "bottom" ? pop.target.y - height - gap : cy - height / 2
                return Math.max(gap, Math.min(want, overlay.window.height - height - gap))
            }
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
