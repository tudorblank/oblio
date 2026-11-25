// SPDX-License-Identifier: GPL-3.0-or-later
// A bar widget's icon and its value ("55%", a name), side by side, or stacked on a side bar, in the
// bar's one scale, so every widget's icon and value look alike.
import QtQuick
import qs.services
import qs.controls

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
    spacing: widget.vertical ? 0 : widget.m.gap
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter
    readonly property real length: widget.vertical ? implicitHeight : implicitWidth

    Glyph {
        text: iv.icon
        color: iv.color
        size: iv.widget.m.icon
    }
    Text {
        visible: iv.showValue && iv.value !== ""
        text: iv.value
        color: iv.color
        font.family: Theme.fontUi
        font.pixelSize: iv.widget.vertical ? iv.widget.m.smallText : iv.widget.m.text
        font.weight: Font.Medium
        font.features: { "tnum": 1 }
    }
}
