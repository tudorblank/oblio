// SPDX-License-Identifier: GPL-3.0-or-later
// A thin line between widgets.
import QtQuick
import qs.services
import qs.bar

BarWidget {
    id: w
    island: false
    interactive: false
    // nothing to separate between islands
    length: inScattered ? 0 : m.gap + 1

    Rectangle {
        anchors.centerIn: parent
        width: w.vertical ? w.m.icon : 1
        height: w.vertical ? 1 : w.m.icon
        color: Theme.border
    }
}
