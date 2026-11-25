// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.services

Rectangle {
    id: b

    property string text
    property bool primary: false
    signal clicked()

    implicitWidth: label.implicitWidth + 32
    implicitHeight: Theme.controlHeight
    radius: height / 2
    opacity: enabled ? 1 : Theme.disabledOpacity
    color: primary ? (area.containsMouse ? Theme.accentHover : Theme.accent)
                   : (area.containsMouse ? Theme.hover : Theme.card)
    border.width: primary ? 0 : 1
    border.color: Theme.hairline

    Behavior on color { ColorAnimation { duration: Theme.ms(140) } }

    Text {
        font.family: Theme.fontUi
        id: label
        anchors.centerIn: parent
        text: b.text
        color: b.primary ? Theme.accentFg : Theme.text
        font.pixelSize: Theme.textLabel
        font.weight: Font.Medium
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
