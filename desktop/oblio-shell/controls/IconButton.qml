// SPDX-License-Identifier: GPL-3.0-or-later
// A round button with a Nerd Font icon.
import QtQuick
import qs.services

Rectangle {
    id: b

    property string icon
    property int size: 34
    property bool primary: false
    signal clicked()

    width: size
    height: size
    radius: size / 2
    opacity: enabled ? 1 : Theme.disabledOpacity
    color: primary ? (area.containsMouse ? Theme.accentHover : Theme.accent)
                   : area.containsMouse ? Theme.hover : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

    Text {
        anchors.centerIn: parent
        text: b.icon
        color: b.primary ? Theme.accentFg : Theme.text
        font.family: Theme.iconFont
        font.pixelSize: Math.round(b.size * 0.5)
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
