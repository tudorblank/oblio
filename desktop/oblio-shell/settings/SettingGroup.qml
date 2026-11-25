// SPDX-License-Identifier: GPL-3.0-or-later
// A titled card of SettingRows.
import QtQuick
import qs.services
import qs.controls

Column {
    id: group

    property string title
    default property alias rows: list.data

    width: parent ? parent.width : 0
    spacing: 8

    SectionLabel { text: group.title }

    Rectangle {
        width: parent.width
        height: list.implicitHeight
        radius: Theme.groupRadius
        color: Theme.card
        border.width: 1
        border.color: Theme.hairline

        Column {
            id: list
            width: parent.width
        }
    }
}
