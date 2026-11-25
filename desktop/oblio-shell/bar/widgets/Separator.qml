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
    length: inScattered ? 0 : 9

    Rectangle {
        anchors.centerIn: parent
        width: w.vertical ? Math.round(w.thickness * 0.5) : 1
        height: w.vertical ? 1 : Math.round(w.thickness * 0.5)
        color: Theme.border
    }
}
