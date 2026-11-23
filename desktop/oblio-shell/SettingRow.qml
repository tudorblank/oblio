// SPDX-License-Identifier: GPL-3.0-or-later
// One setting: title and description on the left, its control on the right.
import QtQuick

Item {
    id: row

    property string title
    property string description
    default property alias control: slot.data

    width: parent ? parent.width : 0
    implicitHeight: Math.max(texts.implicitHeight, slot.height) + 26

    Rectangle {
        visible: row.Positioner.index > 0
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 1
        color: Theme.hairline
    }

    Column {
        id: texts
        anchors.left: parent.left
        anchors.right: slot.left
        anchors.leftMargin: 16
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Text {
            width: parent.width
            text: row.title
            color: Theme.text
            font.pixelSize: 14
            elide: Text.ElideRight
        }

        Text {
            visible: text !== ""
            width: parent.width
            text: row.description
            color: Theme.subtext
            font.pixelSize: 12
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
