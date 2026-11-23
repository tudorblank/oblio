// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

Rectangle {
    id: b

    property string text
    property bool primary: false
    signal clicked()

    implicitWidth: label.implicitWidth + 32
    implicitHeight: 30
    radius: height / 2
    opacity: enabled ? 1 : 0.4
    color: primary ? (area.containsMouse ? Qt.lighter(Settings.accent, 1.12) : Settings.accent)
                   : (area.containsMouse ? Theme.hover : Theme.card)
    border.width: primary ? 0 : 1
    border.color: Theme.hairline

    Behavior on color { ColorAnimation { duration: 140 } }

    Text {
        id: label
        anchors.centerIn: parent
        text: b.text
        color: b.primary ? Theme.onAccent : Theme.text
        font.pixelSize: 12
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
