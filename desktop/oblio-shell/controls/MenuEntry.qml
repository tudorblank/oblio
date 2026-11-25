// SPDX-License-Identifier: GPL-3.0-or-later
// A menu row: optional icon, text. `inset` is how far the menu's edge is, for the corners.
import QtQuick
import qs.services

Rectangle {
    id: e

    property string icon: ""
    property string text
    property bool danger: false
    property bool dim: false
    property real inset: 8
    signal clicked()

    width: parent ? parent.width : 0
    height: 36
    radius: Theme.inner(inset)
    color: area.containsMouse ? (danger ? Theme.tint(Theme.danger, 0.14) : Theme.hover) : "transparent"

    Text {
        id: glyph
        visible: e.icon !== ""
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        horizontalAlignment: Text.AlignHCenter
        text: e.icon
        color: e.danger ? Theme.danger : Theme.subtext
        font.family: Theme.iconFont
        font.pixelSize: 15
    }
    Text {
        anchors.left: glyph.visible ? glyph.right : parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: e.text
        elide: Text.ElideRight
        color: e.danger ? Theme.danger : Theme.text
        opacity: e.dim ? 0.55 : 1
        font.family: Theme.fontUi
        font.pixelSize: Theme.textBody
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: e.clicked()
    }
}
