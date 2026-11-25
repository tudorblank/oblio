// SPDX-License-Identifier: GPL-3.0-or-later
// One setting: title and description on the left, its control on the right.
import QtQuick
import qs.services
import qs.controls

Item {
    id: row

    property string title
    property string description
    default property alias control: slot.data

    width: parent ? parent.width : 0
    implicitHeight: Math.max(texts.implicitHeight, slot.height) + 26

    Divider { visible: row.Positioner.index > 0; inset: 16; space: 1 }

    Column {
        id: texts
        anchors.left: parent.left
        anchors.right: slot.left
        anchors.leftMargin: 16
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Text {
            font.family: Theme.fontUi
            width: parent.width
            text: row.title
            color: Theme.text
            font.pixelSize: Theme.textTitle
            elide: Text.ElideRight
        }

        Text {
            font.family: Theme.fontUi
            visible: text !== ""
            width: parent.width
            text: row.description
            color: Theme.subtext
            font.pixelSize: Theme.textLabel
            wrapMode: Text.WordWrap
        }
    }

    Item {
        id: slot
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
