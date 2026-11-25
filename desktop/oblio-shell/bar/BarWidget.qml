// SPDX-License-Identifier: GPL-3.0-or-later
// What every bar widget (bar/widgets/) is: content as long as `length` along the bar (0 hides
// it), as thick as the bar. On a side bar (vertical) the widget lays itself out in a column.
// The bar adds the padding, the hover highlight and, when scattered, its island.
// A widget with a popup opens it on a left click; a right click opens the bar's menu unless the
// widget handles it (handlesRightClick).
import QtQuick
import qs.services

Item {
    id: w

    property var bar: null              // the Bar it sits on
    property var entry: null            // its settings: { uid, type, ...options }
    property real length: 0             // along the bar
    property bool island: true          // its own island when the bar is scattered
    property bool interactive: true     // hover highlight and clicks (scrolling works either way)
    property bool expand: false         // spacers: take the lane's free space
    property real reveal: 1             // 0..1: how much of it is out (with its padding), for widgets that come and go
    property bool handlesRightClick: false
    property bool inScattered: false    // its section is one island per widget (set by the bar)
    property Component popup: null      // opened by a left click, next to the widget
    property real popupWidth: 300

    signal activated(int button)
    signal scrolled(int steps)          // +1 up, -1 down

    readonly property bool vertical: bar ? bar.vertical : false
    readonly property real thickness: bar ? bar.thickness : 32
    readonly property int textSize: Math.max(11, Math.round(thickness * 0.4))
    // text on a side bar: smaller, so a value fits across it
    readonly property int smallText: Math.max(9, Math.round(thickness * 0.3))
    readonly property int iconSize: Math.max(12, Math.round(thickness * 0.5))
    // between an icon and its value: the same for every widget
    readonly property int gap: Math.round(thickness * 0.18)
    readonly property bool hovered: hover.hovered
    readonly property bool popupOpen: bar !== null && bar.popupOwner === w
    function opt(key) { return BarWidgets.option(entry, key) }
    function openPopup() { if (bar && popup) bar.openPopup(w, popup, popupWidth) }

    implicitWidth: vertical ? thickness : length
    implicitHeight: vertical ? length : thickness

    HoverHandler { id: hover; enabled: w.interactive }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: w.interactive ? Qt.LeftButton | Qt.MiddleButton | Qt.RightButton : Qt.NoButton
        cursorShape: w.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        property real wheel: 0
        onClicked: m => {
            if (m.button === Qt.LeftButton && w.popup) w.openPopup()
            else if (m.button === Qt.RightButton && !w.handlesRightClick && w.bar) w.bar.openMenu(this, m.x, m.y)
            else w.activated(m.button)
        }
        onWheel: e => {
            wheel += e.angleDelta.y
            while (Math.abs(wheel) >= 120) {
                w.scrolled(wheel > 0 ? 1 : -1)
                wheel -= wheel > 0 ? 120 : -120
            }
        }
    }
}
