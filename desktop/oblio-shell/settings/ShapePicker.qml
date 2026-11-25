// SPDX-License-Identifier: GPL-3.0-or-later
// Picks an edge panel's shape from small previews, drawn with the panel's own Surface in its tint.
import QtQuick
import qs.services
import qs.edges

Row {
    id: picker

    property string edge: "bottom"
    property string value
    property real roundness: 65
    property color tint: Theme.solid
    signal picked(string value)

    spacing: 14

    Repeater {
        model: [
            { value: "floating", label: "Floating" },
            { value: "attached", label: "Attached" },
            { value: "full", label: picker.edge === "left" || picker.edge === "right" ? "Full height" : "Full width" },
        ]

        Item {
            id: tile
            required property var modelData
            readonly property bool selected: modelData.value === picker.value
            readonly property bool vertical: picker.edge === "left" || picker.edge === "right"
            width: 132
            height: 104

            Rectangle {
                id: screen
                width: parent.width
                height: 76
                radius: 10
                color: Theme.dark ? "#101013" : "#e4e4e8"
                border.width: tile.selected ? 2 : 1
                border.color: tile.selected ? Theme.accent : Theme.hairline
                clip: true

                // the panel in miniature: same shapes, scaled down
                Surface {
                    readonly property real thickness: 9
                    readonly property real gap: tile.modelData.value === "floating" ? 5 : 0
                    readonly property real fil: tile.modelData.value === "attached" ? radius : 0
                    readonly property real len: tile.modelData.value === "full"
                        ? (tile.vertical ? screen.height : screen.width)
                        : (tile.vertical ? screen.height * 0.5 : screen.width * 0.42) + 2 * fil
                    edge: picker.edge
                    shape: tile.modelData.value
                    fill: Qt.rgba(picker.tint.r, picker.tint.g, picker.tint.b, 0.85)
                    line: Theme.border
                    radius: Theme.rounded(picker.roundness, thickness)
                    fillet: fil
                    width: tile.vertical ? thickness : len
                    height: tile.vertical ? len : thickness
                    x: !tile.vertical ? (screen.width - width) / 2
                       : picker.edge === "left" ? gap : screen.width - gap - width
                    y: tile.vertical ? (screen.height - height) / 2
                       : picker.edge === "top" ? gap : screen.height - gap - height
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                text: tile.modelData.label
                color: tile.selected ? Theme.text : Theme.subtext
                font.family: Theme.fontUi
                font.pixelSize: Theme.textLabel
                font.weight: tile.selected ? Font.DemiBold : Font.Normal
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: picker.picked(tile.modelData.value)
            }
        }
    }
}
