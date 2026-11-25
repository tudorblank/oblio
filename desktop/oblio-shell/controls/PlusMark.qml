// SPDX-License-Identifier: GPL-3.0-or-later
// A plus drawn with two bars, exactly centered (a font glyph isn't): even sizes keep it on whole pixels.
import QtQuick

Item {
    property color color
    property int stroke: 2

    Rectangle { anchors.centerIn: parent; width: parent.width; height: parent.stroke; radius: height / 2; color: parent.color }
    Rectangle { anchors.centerIn: parent; width: parent.stroke; height: parent.height; radius: width / 2; color: parent.color }
}
