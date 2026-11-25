// SPDX-License-Identifier: GPL-3.0-or-later
// A bar widget's icon and its value ("55%", a name), side by side, or stacked on a side bar. One gap for
// every widget, so volume, brightness and battery look alike.
import QtQuick
import qs.services

Grid {
    id: iv

    required property var widget        // the BarWidget it's in
    property string icon
    property string value
    property bool showValue: true
    property color color: Theme.text

    anchors.centerIn: parent
    rows: widget.vertical ? -1 : 1
    columns: widget.vertical ? 1 : -1
    flow: widget.vertical ? Grid.TopToBottom : Grid.LeftToRight
    spacing: widget.vertical ? 1 : widget.gap
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter
    readonly property real length: widget.vertical ? implicitHeight : implicitWidth

    Text {
        text: iv.icon
        color: iv.color
        font.family: Theme.iconFont
        font.pixelSize: iv.widget.iconSize
    }
    Text {
        visible: iv.showValue && iv.value !== ""
        text: iv.value
        color: iv.color
        font.family: Theme.fontUi
        font.pixelSize: iv.widget.vertical ? iv.widget.smallText : iv.widget.textSize
        font.weight: Font.Medium
        font.features: { "tnum": 1 }
    }
}
