// SPDX-License-Identifier: GPL-3.0-or-later
// One app in Search's results: its icon, its name and what it is.
import QtQuick
import qs.services

Item {
    id: row

    required property var modelData        // a desktop entry
    required property int index
    property bool details: true
    signal hovered(point at)            // where the pointer is, on the screen
    signal picked()

    height: 56

    Image {
        id: icon
        x: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        height: 40
        sourceSize: Qt.size(80, 80)
        source: Apps.icon(row.modelData.icon, "application-x-executable")
        asynchronous: true
    }
    Column {
        anchors.left: icon.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text {
            width: parent.width
            text: row.modelData.name
            elide: Text.ElideRight
            color: Theme.text
            font.family: Theme.fontUi
            font.pixelSize: Theme.textTitle
            font.weight: Font.Medium
        }
        Text {
            visible: row.details && text !== ""
            width: parent.width
            text: row.modelData.comment || row.modelData.genericName || ""
            elide: Text.ElideRight
            color: Theme.subtext
            font.family: Theme.fontUi
            font.pixelSize: Theme.textLabel
        }
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: m => row.hovered(mapToGlobal(m.x, m.y))
        onClicked: row.picked()
    }
}
