// SPDX-License-Identifier: GPL-3.0-or-later
// A titled card of SettingRows.
import QtQuick
import qs.services

Column {
    id: group

    property string title
    default property alias rows: list.data

    width: parent ? parent.width : 0
    spacing: 8

    Text {
        font.family: Theme.fontUi
        leftPadding: 4
        text: group.title
        color: Theme.subtext
        font.pixelSize: 12
        font.weight: Font.DemiBold
        font.letterSpacing: 0.4
    }

    Rectangle {
        width: parent.width
        height: list.implicitHeight
        radius: 14
        color: Theme.card
        border.width: 1
        border.color: Theme.hairline

        Column {
            id: list
            width: parent.width
        }
    }
}
