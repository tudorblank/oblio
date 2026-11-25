// SPDX-License-Identifier: GPL-3.0-or-later
// A list that drops down from a control (dropdowns, the widget catalog). A press on the control
// itself doesn't close it, so a click there toggles it; a press anywhere else closes it and still
// reaches what's there (another dropdown opens). A header (a search field) sits above the list,
// out of it: a new model resets the list, never the header.
import QtQuick
import QtQuick.Controls as C
import qs.services

C.Popup {
    id: pop

    property alias model: list.model
    property alias delegate: list.delegate
    property alias view: list
    property Component header: null
    readonly property Item headerItem: top.item
    property real maxHeight: 280

    height: top.height + list.height + topPadding + bottomPadding
    padding: 5
    margins: 12
    focus: true
    closePolicy: C.Popup.CloseOnEscape | C.Popup.CloseOnPressOutsideParent

    background: Rectangle {
        radius: Theme.radius
        color: Theme.popup
        border.width: 1
        border.color: Theme.border
    }

    contentItem: Column {
        Loader {
            id: top
            width: parent.width
            active: pop.header !== null
            sourceComponent: pop.header
        }
        ListView {
            id: list
            width: parent.width
            height: Math.min(contentHeight, pop.maxHeight - top.height)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
        }
    }
}
