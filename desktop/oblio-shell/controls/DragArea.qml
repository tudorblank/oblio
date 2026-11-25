// SPDX-License-Identifier: GPL-3.0-or-later
// A MouseArea whose left press becomes a drag once it moves past `threshold`: dragStarted,
// dragMoved, dropped (or dragCanceled when the press is taken away). A press that doesn't move is a click
// (clicked still fires after a drag that ends over it: check dragged).
// Positions are in this item's coordinates.
import QtQuick

MouseArea {
    id: d

    property real threshold: 6
    property bool carrying: false
    property bool dragged: false        // since the last press
    property point pressedAt
    signal dragStarted(point at)
    signal dragMoved(point at)
    signal dropped(point at)
    signal dragCanceled()

    preventStealing: true

    onPressed: m => { pressedAt = Qt.point(m.x, m.y); carrying = false; dragged = false }
    onPositionChanged: m => {
        if (!(pressedButtons & Qt.LeftButton)) return
        const at = Qt.point(m.x, m.y)
        if (!carrying && Math.hypot(m.x - pressedAt.x, m.y - pressedAt.y) > threshold) {
            carrying = true
            dragged = true
            dragStarted(at)
        } else if (carrying) {
            dragMoved(at)
        }
    }
    onReleased: m => { if (carrying) { carrying = false; dropped(Qt.point(m.x, m.y)) } }
    onCanceled: if (carrying) { carrying = false; dragCanceled() }
}
