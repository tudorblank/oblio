// SPDX-License-Identifier: GPL-3.0-or-later
// Settings > Bar > Widgets: the bar's islands, in order along it, as rows of chips. Drag a chip to
// move it (into another island too), × removes it, + adds one; a click on a chip shows its
// options. Each island's header moves it along the bar, removes it, and (bar split into its
// islands) picks continuous or scattered.
import QtQuick
import Quickshell
import qs.services
import qs.controls

Item {
    id: ed

    property string selected: ""
    readonly property var selectedEntry: selected ? BarWidgets.entry(selected) : null
    readonly property var selectedInfo: selectedEntry ? BarWidgets.info(selectedEntry.type) : null

    // dragging a chip
    property string dragging: ""
    property point dragPos
    property string dropIsland: ""
    property int dropIndex: -1
    property var flows: ({})
    function endDrag() { dragging = ""; dropIsland = ""; dropIndex = -1 }
    readonly property bool split: Settings.opts.barShape === "floating" && Settings.opts.barIslands === "sections"
    readonly property bool side: Settings.opts.barEdge === "left" || Settings.opts.barEdge === "right"

    width: parent ? parent.width : 0
    height: content.implicitHeight

    // where a point (in ed's coordinates) drops: the island under it, the place between chips
    function dropAt(p) {
        dropIsland = ""
        dropIndex = -1
        for (const island of BarWidgets.islandUids) {
            const row = flows[island]
            if (!row || !row.parent) continue
            const box = row.parent.mapToItem(ed, 0, 0)
            if (p.y < box.y || p.y > box.y + row.parent.height) continue
            const q = row.mapFromItem(ed, p.x, p.y)
            const chips = row.children.filter(c => c.uid !== undefined)
            let i = chips.findIndex(c => q.y < c.y || (q.y <= c.y + c.height && q.x < c.x + c.width / 2))
            dropIsland = island
            dropIndex = i < 0 ? chips.length : i
            return
        }
    }

    // a chip's face: the widget's icon and name
    component ChipLabel: Row {
        property var info
        property bool lit: false
        spacing: 7
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.info ? parent.info.icon : ""
            color: parent.lit ? Theme.accentText : Theme.subtext
            font.family: Theme.iconFont
            font.pixelSize: 13
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.info ? parent.info.name : ""
            color: Theme.text
            font.family: Theme.fontUi
            font.pixelSize: Theme.textLabel
            font.weight: Font.Medium
        }
    }
    // where a dragged chip would go: a bar just before the item it's on
    component DropMark: Rectangle {
        property bool on: false
        visible: on
        x: -5
        y: 3
        width: 2
        height: parent.height - 6
        radius: 1
        color: Theme.accent
    }

    Column {
        id: content
        width: parent.width
        spacing: 8

        SettingGroup {
            title: "WIDGETS"

            Repeater {
                model: ScriptModel { values: BarWidgets.islandUids }

                Item {
                    id: laneRow
                    required property string modelData
                    required property int index
                    readonly property var island: BarWidgets.island(modelData)
                    readonly property bool dropHere: ed.dragging !== "" && ed.dropIsland === modelData
                    // the chips in order (the Flow also holds the Repeater and the + chip)
                    function chips() { return flow.children.filter(c => c.uid !== undefined) }
                    width: parent.width
                    height: spacingRow.y + spacingRow.height + 12

                    Divider { visible: laneRow.index > 0; inset: 16; space: 1 }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: Theme.groupRadius - 4
                        color: laneRow.dropHere ? Theme.tint(Theme.accent, 0.08) : "transparent"
                    }

                    // Island N, then its style and its moves along the bar
                    Item {
                        id: head
                        x: 16
                        y: 10
                        width: parent.width - 32
                        height: Theme.controlHeight

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Island " + (laneRow.index + 1)
                            color: Theme.text
                            font.family: Theme.fontUi
                            font.pixelSize: Theme.textTitle
                        }
                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Segmented {
                                visible: ed.split
                                anchors.verticalCenter: parent.verticalCenter
                                options: [{ value: "continuous", label: "Continuous" }, { value: "scattered", label: "Scattered" }]
                                value: laneRow.island?.style ?? "continuous"
                                onPicked: v => BarWidgets.setStyle(laneRow.modelData, v)
                            }
                            Item { visible: ed.split; width: 6; height: 1 }
                            IconButton {
                                size: 28
                                icon: ed.side ? Icons.chevronDown : Icons.chevronLeft
                                rotation: ed.side ? 180 : 0
                                enabled: laneRow.index > 0
                                onClicked: BarWidgets.moveIsland(laneRow.modelData, -1)
                            }
                            IconButton {
                                size: 28
                                icon: ed.side ? Icons.chevronDown : Icons.chevronRight
                                enabled: laneRow.index < BarWidgets.islandUids.length - 1
                                onClicked: BarWidgets.moveIsland(laneRow.modelData, 1)
                            }
                            IconButton {
                                size: 28
                                icon: Icons.trash
                                enabled: BarWidgets.islandUids.length > 1
                                onClicked: BarWidgets.removeIsland(laneRow.modelData)
                            }
                        }
                    }

                    Flow {
                        id: flow
                        x: 16
                        y: head.y + head.height + 8
                        width: parent.width - 32
                        spacing: 6
                        Component.onCompleted: ed.flows[laneRow.modelData] = flow
                        Component.onDestruction: if (ed.flows[laneRow.modelData] === flow) delete ed.flows[laneRow.modelData]

                        Repeater {
                            model: ScriptModel { values: BarWidgets.uids(laneRow.modelData) }

                            Rectangle {
                                id: chip
                                required property string modelData
                                readonly property string uid: modelData
                                readonly property var info: BarWidgets.info(BarWidgets.entry(modelData)?.type ?? "")
                                readonly property bool isSelected: ed.selected === uid
                                width: label.x + label.implicitWidth + 6 + removeButton.width + removeButton.anchors.rightMargin
                                height: Theme.controlHeight
                                radius: height / 2
                                opacity: ed.dragging === uid ? 0.35 : 1
                                color: isSelected ? Theme.tint(Theme.accent, 0.16) : drag.containsMouse ? Theme.hover : Theme.card
                                border.width: 1
                                border.color: isSelected ? Theme.tint(Theme.accent, 0.6) : Theme.hairline

                                DropMark { on: laneRow.dropHere && ed.dropIndex === laneRow.chips().indexOf(chip) }
                                ChipLabel {
                                    id: label
                                    x: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    info: chip.info
                                    lit: chip.isSelected
                                }

                                DragArea {
                                    id: drag
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: carrying ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                    function follow(at) {
                                        ed.dragPos = mapToItem(ed, at.x, at.y)
                                        ed.dropAt(ed.dragPos)
                                    }
                                    onDragStarted: at => { ed.dragging = chip.uid; follow(at) }
                                    onDragMoved: at => follow(at)
                                    onDropped: {
                                        // moving it can destroy this chip: finish the drag first
                                        const uid = chip.uid, island = ed.dropIsland, index = ed.dropIndex
                                        ed.endDrag()
                                        if (island) BarWidgets.move(uid, island, index)
                                    }
                                    onDragCanceled: ed.endDrag()
                                    onClicked: if (!dragged) ed.selected = ed.selected === chip.uid ? "" : chip.uid
                                }

                                // remove, above the chip's own click area
                                Rectangle {
                                    id: removeButton
                                    anchors.right: parent.right
                                    anchors.rightMargin: 5
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.height - 10
                                    height: width
                                    radius: width / 2
                                    color: removeArea.containsMouse ? Theme.tint(Theme.danger, 0.18) : "transparent"
                                    Behavior on color { ColorAnimation { duration: Theme.ms(120) } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: Icons.close
                                        color: removeArea.containsMouse ? Theme.danger : Theme.subtext
                                        font.family: Theme.iconFont
                                        font.pixelSize: 12
                                    }
                                    MouseArea {
                                        id: removeArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            const uid = chip.uid
                                            if (ed.selected === uid) ed.selected = ""
                                            BarWidgets.remove(uid)
                                        }
                                    }
                                }
                            }
                        }

                        // add a widget to this island
                        Rectangle {
                            id: addChip
                            width: Theme.controlHeight
                            height: width
                            radius: width / 2
                            color: addArea.containsMouse || picker.opened ? Theme.hover : "transparent"
                            border.width: 1
                            border.color: Theme.hairline

                            DropMark { on: laneRow.dropHere && ed.dropIndex === laneRow.chips().length }
                            PlusMark { anchors.centerIn: parent; width: 12; height: 12; color: Theme.subtext }
                            MouseArea {
                                id: addArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: picker.opened ? picker.close() : picker.open()
                            }

                            PopupList {
                                id: picker
                                y: addChip.height + 6
                                width: 300
                                maxHeight: 320
                                model: BarWidgets.catalog

                                delegate: Rectangle {
                                    id: option
                                    required property var modelData
                                    width: ListView.view.width
                                    height: 46
                                    radius: Theme.inner(picker.padding)
                                    color: optionArea.containsMouse ? Theme.hover : "transparent"

                                    Text {
                                        id: optionIcon
                                        x: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 22
                                        horizontalAlignment: Text.AlignHCenter
                                        text: option.modelData.icon
                                        color: Theme.subtext
                                        font.family: Theme.iconFont
                                        font.pixelSize: 16
                                    }
                                    Column {
                                        anchors.left: optionIcon.right
                                        anchors.leftMargin: 10
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1
                                        Text {
                                            text: option.modelData.name
                                            color: Theme.text
                                            font.family: Theme.fontUi
                                            font.pixelSize: Theme.textBody
                                            font.weight: Font.Medium
                                        }
                                        Text {
                                            width: parent.width
                                            text: option.modelData.about
                                            elide: Text.ElideRight
                                            color: Theme.subtext
                                            font.family: Theme.fontUi
                                            font.pixelSize: Theme.textCaption
                                        }
                                    }
                                    MouseArea {
                                        id: optionArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            picker.close()
                                            ed.selected = BarWidgets.add(laneRow.modelData, option.modelData.type)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // room between the island's widgets (not at its ends)
                    Item {
                        id: spacingRow
                        x: 16
                        y: flow.y + Math.max(flow.implicitHeight, Theme.controlHeight) + 10
                        width: parent.width - 32
                        height: 24
                        Text {
                            id: spacingLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Spacing"
                            color: Theme.subtext
                            font.family: Theme.fontUi
                            font.pixelSize: Theme.textLabel
                        }
                        ValueSlider {
                            anchors.left: spacingLabel.right
                            anchors.leftMargin: 14
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            from: 0
                            to: 32
                            unit: " px"
                            value: laneRow.island?.spacing ?? 0
                            onMoved: v => BarWidgets.setSpacing(laneRow.modelData, Math.round(v))
                        }
                    }
                }
            }
            // a new, empty island at the end of the bar
            Item {
                width: parent.width
                height: Theme.controlHeight + 16

                Divider { inset: 16; space: 1 }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: Theme.groupRadius - 4
                    color: addIslandArea.containsMouse ? Theme.hover : "transparent"
                }
                Row {
                    x: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    PlusMark { anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; color: Theme.subtext }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Add island"
                        color: Theme.text
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.textTitle
                    }
                }
                MouseArea {
                    id: addIslandArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BarWidgets.addIsland()
                }
            }
        }

        Text {
            leftPadding: 4
            width: parent.width
            text: "Drag to rearrange, + to add, × to remove, click one for its options. Islands spread out along the bar in this order: the first at its start, the last at its end."
            wrapMode: Text.WordWrap
            color: Theme.subtext
            font.family: Theme.fontUi
            font.pixelSize: Theme.textLabel
        }

        // the selected widget's options, one card per section
        Repeater {
            model: {
                const opts = ed.selectedInfo ? ed.selectedInfo.options : []
                const sections = []
                for (const o of opts) if (!sections.includes(o.section ?? "")) sections.push(o.section ?? "")
                return sections
            }

            Column {
                id: section
                required property string modelData
                width: parent.width
                topPadding: 14
                SettingGroup {
                    title: ed.selectedInfo.name.toUpperCase() + (section.modelData ? "  ·  " + section.modelData.toUpperCase() : "")

                    Repeater {
                        model: ed.selectedInfo.options.filter(o => (o.section ?? "") === section.modelData)

                        SettingRow {
                            id: optionRow
                            required property var modelData
                            readonly property var value: BarWidgets.option(ed.selectedEntry, modelData.key)
                            // the last one on in its keepOne set can't be turned off
                            readonly property bool locked: modelData.keepOne !== undefined && value === true
                                && !ed.selectedInfo.options.some(o => o.key !== modelData.key && o.keepOne === modelData.keepOne
                                                                     && BarWidgets.option(ed.selectedEntry, o.key) === true)
                            title: modelData.label
                            description: modelData.about ?? ""

                            Loader {
                                sourceComponent: ({ toggle: toggleControl, choice: choiceControl, list: listControl,
                                                    text: textControl })[optionRow.modelData.kind] ?? numberControl
                            }
                            Component {
                                id: toggleControl
                                Toggle {
                                    checked: optionRow.value
                                    enabled: !optionRow.locked
                                    onToggled: v => BarWidgets.setOption(ed.selected, optionRow.modelData.key, v)
                                }
                            }
                            Component {
                                id: choiceControl
                                Segmented {
                                    options: optionRow.modelData.choices
                                    value: optionRow.value
                                    onPicked: v => BarWidgets.setOption(ed.selected, optionRow.modelData.key, v)
                                }
                            }
                            Component {
                                id: listControl
                                Dropdown {
                                    width: 220
                                    options: optionRow.modelData.choices
                                    value: optionRow.value
                                    onPicked: v => BarWidgets.setOption(ed.selected, optionRow.modelData.key, v)
                                }
                            }
                            Component {
                                id: textControl
                                TextBox {
                                    width: 220
                                    mono: true
                                    value: optionRow.value
                                    onEdited: v => BarWidgets.setOption(ed.selected, optionRow.modelData.key, v)
                                }
                            }
                            Component {
                                id: numberControl
                                ValueSlider {
                                    from: optionRow.modelData.from
                                    to: optionRow.modelData.to
                                    step: optionRow.modelData.step ?? 1
                                    unit: optionRow.modelData.unit ?? ""
                                    value: optionRow.value
                                    onMoved: v => BarWidgets.setOption(ed.selected, optionRow.modelData.key, v)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // the chip being dragged
    Rectangle {
        visible: ed.dragging !== ""
        x: ed.dragPos.x - width / 2
        y: ed.dragPos.y - height / 2
        z: 100
        width: ghost.implicitWidth + 20
        height: Theme.controlHeight
        radius: height / 2
        color: Theme.popup
        border.width: 1
        border.color: Theme.tint(Theme.accent, 0.6)
        ChipLabel {
            id: ghost
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            info: ed.dragging ? BarWidgets.info(BarWidgets.entry(ed.dragging)?.type ?? "") : null
            lit: true
        }
    }
}
