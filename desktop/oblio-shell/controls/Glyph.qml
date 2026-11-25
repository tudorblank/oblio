// SPDX-License-Identifier: GPL-3.0-or-later
// An icon glyph (Icons, Theme.iconFont) filling a size x size square by its ink, centered in it.
// Nerd Font glyphs sit in their font box at different sizes and heights (a battery is a narrow
// shape high in it, a Wi-Fi fan a wide one), so the same font size looks unequal and off center;
// measured by their ink, every glyph is as big as the square allows and in its middle.
import QtQuick
import qs.services

Item {
    id: g

    property string text
    property color color: Theme.text
    property real size: 16

    implicitWidth: size
    implicitHeight: size

    // the ink at a large reference size, scaled down to fit the square
    readonly property int reference: 200
    TextMetrics {
        id: ink
        font.family: Theme.iconFont
        font.pixelSize: g.reference
        text: g.text
    }
    readonly property rect box: ink.tightBoundingRect
    readonly property int pixelSize: box.width > 0 ? Math.round(reference * size / Math.max(box.width, box.height)) : 0
    readonly property real scale: pixelSize / reference

    Text {
        text: g.text
        color: g.color
        font.family: Theme.iconFont
        font.pixelSize: Math.max(1, g.pixelSize)
        // the box is measured from the baseline (y up is negative)
        x: (g.size - g.box.width * g.scale) / 2 - g.box.x * g.scale
        y: (g.size - g.box.height * g.scale) / 2 - g.box.y * g.scale - baselineOffset
    }
}
