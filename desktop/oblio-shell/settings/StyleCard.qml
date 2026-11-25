// SPDX-License-Identifier: GPL-3.0-or-later
// One style in Settings > Appearance: its name, material, tint and opacity, and what it applies to
// (chips: × gives one back, + picks more). Default covers the shell's parts no other style has.
import QtQuick
import qs.services
import qs.controls

Rectangle {
    id: card

    required property string uid
    readonly property var style: Styles.style(uid) ?? Styles.list[0]
    readonly property bool isDefault: uid === "default"
    // the tint is per mode: this one's
    readonly property string tintKey: Theme.dark ? "tint" : "tintLight"
    readonly property string tintValue: style[tintKey]
    readonly property bool hasApps: style.targets.some(t => Styles.isApp(t))
    readonly property var paint: Styles.paint(style, 0.01)
    property bool renaming: false
    function set(changes) { Styles.set(uid, changes) }

    width: parent ? parent.width : 0
    height: rows.implicitHeight
    radius: Theme.groupRadius
    color: Theme.card
    border.width: 1
    border.color: Theme.hairline

    // a chip for one target: its icon and name, × to give it back
    component Chip: Rectangle {
        id: chip
        required property string modelData
        property bool removable: true
        readonly property var info: Styles.describe(modelData)
        width: chipRow.implicitWidth + (removable ? removeButton.width + 11 : 12) + 10
        height: Theme.controlHeight
        radius: height / 2
        color: Theme.card
        border.width: 1
        border.color: Theme.hairline

        Row {
            id: chipRow
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7
            Text {
                visible: chip.info.glyph !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: chip.info.glyph
                color: Theme.subtext
                font.family: Theme.iconFont
                font.pixelSize: 13
            }
            Image {
                visible: chip.info.image !== ""
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 16
                source: chip.info.image
                sourceSize: Qt.size(32, 32)
                asynchronous: true
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.info.name
                color: Theme.text
                font.family: Theme.fontUi
                font.pixelSize: Theme.textLabel
                font.weight: Font.Medium
            }
        }
        Rectangle {
            id: removeButton
            visible: chip.removable
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
                onClicked: Styles.unassign(chip.modelData)
            }
        }
    }

    Column {
        id: rows
        width: parent.width

        // a sample of the style over the accent, its name, rename and remove
        Item {
            width: parent.width
            height: 60

            Rectangle {
                id: sample
                x: 16
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                height: 30
                radius: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.accent }
                    GradientStop { position: 1; color: Qt.darker(Theme.accent, 2.4) }
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 5
                    radius: 6
                    color: card.paint.fill
                    border.width: 1
                    border.color: card.paint.line
                }
            }

            Column {
                anchors.left: sample.right
                anchors.leftMargin: 14
                anchors.right: tools.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    visible: !card.renaming
                    width: parent.width
                    text: card.style.name
                    elide: Text.ElideRight
                    color: Theme.text
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.textTitle
                    font.weight: Font.DemiBold
                }
                TextBox {
                    id: nameBox
                    visible: card.renaming
                    width: Math.min(parent.width, 260)
                    value: card.style.name
                    onEdited: v => Styles.rename(card.uid, v)
                    onEditingChanged: if (!editing) card.renaming = false
                }
                Text {
                    visible: card.isDefault
                    width: parent.width
                    text: "Every part of the shell no other style has"
                    elide: Text.ElideRight
                    color: Theme.subtext
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.textLabel
                }
            }

            Row {
                id: tools
                visible: !card.isDefault
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                IconButton {
                    size: 28
                    icon: Icons.edit
                    onClicked: { card.renaming = true; nameBox.focusInput() }
                }
                IconButton {
                    size: 28
                    icon: Icons.trash
                    onClicked: Styles.remove(card.uid)
                }
            }
        }

        SettingRow {
            title: "Material"
            description: card.style.material === "solid" ? "Nothing blurred behind it"
                : "What's behind it, blurred. Glass, Oblio's own, comes next"
            Segmented {
                options: [{ value: "solid", label: "Solid" }, { value: "blur", label: "Blur" }, { value: "glass", label: "Glass", disabled: true }]
                value: card.style.material
                // opaque hides the blur: make it see-through so the choice shows
                onPicked: v => card.set(v !== "solid" && card.style.opacity >= 100 ? { material: v, opacity: 70 } : { material: v })
            }
        }
        SettingRow {
            visible: card.style.material === "blur"
            title: "Blur strength"
            description: "Shared by every blur style for now: Hyprland's blur has one strength"
            ValueSlider {
                from: 1; to: 16
                value: Settings.opts.blurSize
                onMoved: v => Settings.set("blurSize", Math.round(v))
            }
        }
        SettingRow {
            title: "Tint"
            description: (card.tintValue === "theme" ? "Follows light and dark mode"
                : `A color of your own, in ${Theme.dark ? "dark" : "light"} mode`)
                + (card.hasApps ? ". Apps keep their own colors" : "")
            Segmented {
                options: [{ value: "theme", label: "Theme" }, { value: "custom", label: "Custom" }]
                value: card.tintValue === "theme" ? "theme" : "custom"
                onPicked: v => card.set({ [card.tintKey]: v === "theme" ? "theme" : tints.colors[0] })
            }
        }
        SettingRow {
            visible: card.tintValue !== "theme"
            title: "Tint color"
            Swatches {
                id: tints
                pickerTitle: "Tint color"
                colors: Theme.dark ? ["#26262c", "#1e2a3a", "#2a1e33", "#1e3328", "#3a2a1e"]
                                   : ["#e8e8ec", "#dde6f2", "#eadff0", "#dcebe0", "#f0e6da"]
                value: card.tintValue
                onPicked: v => card.set({ [card.tintKey]: v })
            }
        }
        SettingRow {
            title: "Opacity"
            description: card.style.opacity >= 100 ? "Opaque: nothing shows through"
                : card.hasApps ? "How much the tint covers what's behind; for apps, the whole window"
                : "How much the tint covers what's behind"
            ValueSlider {
                from: 0; to: 100; unit: "%"
                value: card.style.opacity
                onMoved: v => card.set({ opacity: Math.round(v) })
            }
        }

        // what it applies to
        Item {
            width: parent.width
            height: targets.y + targets.height + 14

            Divider { inset: 16; space: 1 }
            Text {
                id: appliesLabel
                x: 16
                y: 14
                text: "Applies to"
                color: Theme.text
                font.family: Theme.fontUi
                font.pixelSize: Theme.textTitle
            }
            Flow {
                id: targets
                x: 16
                y: appliesLabel.y + appliesLabel.height + 10
                width: parent.width - 32
                spacing: 6

                Repeater {
                    model: card.isDefault ? Styles.defaultParts.map(p => p.id) : card.style.targets
                    Chip { removable: !card.isDefault }
                }
                Text {
                    visible: card.isDefault && Styles.defaultParts.length === 0
                    height: Theme.controlHeight
                    verticalAlignment: Text.AlignVCenter
                    text: "Nothing: every part has a style of its own"
                    color: Theme.subtext
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.textLabel
                }

                // add parts or apps
                Rectangle {
                    id: addChip
                    visible: !card.isDefault
                    width: Theme.controlHeight
                    height: width
                    radius: width / 2
                    color: addArea.containsMouse || picker.opened ? Theme.hover : "transparent"
                    border.width: 1
                    border.color: Theme.hairline

                    PlusMark { anchors.centerIn: parent; width: 12; height: 12; color: Theme.subtext }
                    MouseArea {
                        id: addArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: picker.opened ? picker.close() : picker.open()
                    }
                    TargetPicker {
                        id: picker
                        uid: card.uid
                        y: addChip.height + 6
                    }
                }
            }
        }
    }
}
