// SPDX-License-Identifier: GPL-3.0-or-later
// The top of a popup: a title, a line under it, and a control on the right (a Toggle, a Button).
import QtQuick
import qs.services

Item {
    id: h

    property string title
    property string subtitle: ""
    default property alias trailing: slot.data

    width: parent ? parent.width : 0
    height: 44

    Column {
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 20 - slot.width - (slot.width > 0 ? 10 : 0)
        Text {
            text: h.title
            color: Theme.text
            font.family: Theme.fontUi
            font.pixelSize: Theme.textTitle
            font.weight: Font.DemiBold
        }
        Text {
            visible: text !== ""
            width: parent.width
            text: h.subtitle
            elide: Text.ElideRight
            color: Theme.subtext
            font.family: Theme.fontUi
            font.pixelSize: Theme.textCaption
        }
    }
    Item {
        id: slot
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
