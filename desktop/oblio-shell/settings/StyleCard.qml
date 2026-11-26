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
    readonly property bool glassOn: style.material === "glass" && Glass.available
    readonly property bool blurOn: style.material !== "solid"

    // a group's heading inside the card
    component Heading: SectionLabel {
        leftPadding: 16
        topPadding: 14
        bottomPadding: 2
    }
    // a slider row for one of the style's numbers
    component Slider: SettingRow {
        id: row
        property string key
        property real from: 0
        property real to: 100
        property real step: 1
        property int decimals: 0
        property string unit: ""
        ValueSlider {
            from: row.from; to: row.to; step: row.step; decimals: row.decimals; unit: row.unit
            value: card.style[row.key]
            onMoved: v => card.set({ [row.key]: row.decimals ? Number(v.toFixed(row.decimals)) : Math.round(v) })
        }
    }
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
                    border.width: card.paint.lineWidth
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
                : !Glass.available ? `Hyprland's blur for now, in Default's look: ${Glass.status}`
                : card.style.material === "blur" ? "What's behind it, blurred"
                : "Bends the light at its edges, frosted inside"
            Segmented {
                options: [{ value: "solid", label: "Solid" }, { value: "blur", label: "Blur" }, { value: "glass", label: "Glass" }]
                value: card.style.material
                // opaque hides the blur: make it see-through so the choice shows
                onPicked: v => card.set(v !== "solid" && card.style.opacity >= 100 ? { material: v, opacity: 70 } : { material: v })
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

        // the outline around a shell part, whatever its material
        Heading { text: "OUTLINE" }
        Slider { title: "Width"; description: card.style.outlineWidth > 0 ? "Around the shell's parts; apps keep their window border" : "No outline"; key: "outlineWidth"; from: 0; to: 4; step: 0.5; decimals: 1; unit: " px" }
        Slider { visible: card.style.outlineWidth > 0; title: "Opacity"; key: "outlineOpacity"; from: 0; to: 100; unit: "%" }
        SettingRow {
            visible: card.style.outlineWidth > 0
            title: "Color"
            description: card.style.outlineColor === "theme" ? "White in dark mode, black in light" : "A color of your own"
            Segmented {
                options: [{ value: "theme", label: "Theme" }, { value: "custom", label: "Custom" }]
                value: card.style.outlineColor === "theme" ? "theme" : "custom"
                onPicked: v => card.set({ outlineColor: v === "theme" ? "theme" : outlineColors.colors[0] })
            }
        }
        SettingRow {
            visible: card.style.outlineWidth > 0 && card.style.outlineColor !== "theme"
            title: "Outline color"
            Swatches {
                id: outlineColors
                pickerTitle: "Outline color"
                colors: [Theme.accentHex, "#ffffff", "#000000", "#9ca3af", "#5b9cf5"]
                value: card.style.outlineColor
                onPicked: v => card.set({ outlineColor: v })
            }
        }

        // blur and glass: how blurred and what color what's behind is
        Column {
            visible: card.blurOn
            width: parent.width

            Heading { text: "BLUR" }
            Slider { title: "Strength"; description: "How blurred what's behind it is"; key: "blur"; from: 0; to: 12; step: 0.1; decimals: 1 }
            Slider { title: "Brightness"; key: "brightness"; from: 50; to: 150; unit: "%" }
            Slider { title: "Saturation"; key: "saturation"; from: 0; to: 200; unit: "%" }
            Slider { title: "Contrast"; key: "contrast"; from: 50; to: 150; unit: "%" }
            Slider { title: "Noise"; description: "A fine grain, like frosted glass"; key: "noise"; from: 0; to: 100; unit: "%" }
        }

        // glass: refraction and highlight
        Column {
            visible: card.glassOn
            width: parent.width

            Heading { text: "REFRACTION" }
            SettingRow {
                title: "Mode"
                description: card.style.refractionMode === "concave" ? "Pulled toward the middle, like a magnifier's rim"
                    : "Bent in along each edge, like a thick glass slab"
                Segmented {
                    options: [{ value: "bulge", label: "Bulge" }, { value: "concave", label: "Concave" }]
                    value: card.style.refractionMode
                    onPicked: v => card.set({ refractionMode: v })
                }
            }
            Slider { title: "Strength"; description: "How strongly the edges bend what's behind"; key: "refraction"; from: 0; to: 100; step: 5; unit: "%" }
            Slider { title: "Edge size"; description: "How far in from the edge the bending reaches"; key: "edge"; from: 2; to: 80; unit: " px" }
            Slider { title: "Falloff"; description: "Low: a soft curve deep inside. High: it hugs the rim"; key: "falloff"; from: 0.2; to: 5; step: 0.1; decimals: 1 }
            SettingRow {
                title: "Own corner radius"
                description: card.style.cornerRadius >= 0 ? "The bending follows its own corners" : "The bending follows the shape's corners"
                Toggle {
                    checked: card.style.cornerRadius >= 0
                    onToggled: v => card.set({ cornerRadius: v ? 24 : -1 })
                }
            }
            Slider { visible: card.style.cornerRadius >= 0; title: "Corner radius"; key: "cornerRadius"; from: 0; to: 100; unit: " px" }
            Slider { title: "RGB fringing"; description: "Colors split apart where the edge bends light"; key: "fringing"; from: 0; to: 100; unit: "%" }

            Heading { text: "HIGHLIGHT" }
            Slider { title: "Size"; description: "The lit line along the rim"; key: "highlightSize"; from: 0; to: 12; step: 0.5; decimals: 1; unit: " px" }
            Slider { title: "Direction"; description: "Where the light comes from (0° is above)"; key: "highlightAngle"; from: 0; to: 360; step: 5; unit: "°" }
            Slider { title: "Opacity"; description: "How bright the line is"; key: "highlightOpacity"; from: 0; to: 100; unit: "%" }
            SettingRow {
                title: "Follows the pointer"
                description: "The rim lights up where the pointer is"
                Toggle {
                    checked: card.style.highlightFollow
                    onToggled: v => card.set({ highlightFollow: v })
                }
            }
            Slider { visible: card.style.highlightFollow; title: "Strength"; description: "How much the rim lights up around the pointer"; key: "highlightStrength"; from: 0; to: 100; unit: "%" }
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
