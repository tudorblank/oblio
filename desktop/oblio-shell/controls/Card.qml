// SPDX-License-Identifier: GPL-3.0-or-later
// A card in a shell part's style (services/Parts.qml, Styles.look): its fill and outline, and
// oblio-glass behind it while the style is blur or glass. namespace: the layer it's on, when the
// part has several (menus); glass false: a card drawn inside another one, on its glass.
import QtQuick
import qs.services

Rectangle {
    id: card

    required property string part
    property string namespace: Parts.namespace(part)
    property bool glass: true
    readonly property var look: Styles.look(part)

    radius: Theme.radius
    color: look.fill
    border.width: look.lineWidth
    border.color: look.line

    GlassShape {
        visible: card.glass
        anchors.fill: parent
        namespace: card.namespace
        part: card.part
        radius: card.radius
    }
}
