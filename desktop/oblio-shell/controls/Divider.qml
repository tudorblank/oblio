// SPDX-License-Identifier: GPL-3.0-or-later
// A hairline across its parent, `inset` from both sides, centered in `space`.
import QtQuick
import qs.services

Item {
    property real inset: 8
    property real space: 9

    width: parent ? parent.width : 0
    height: space

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: parent.inset
        width: parent.width - 2 * parent.inset
        height: 1
        color: Theme.hairline
    }
}
