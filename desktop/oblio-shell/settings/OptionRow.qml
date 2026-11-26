// SPDX-License-Identifier: GPL-3.0-or-later
// One option, drawn from its definition (key, label, kind, about, choices or from/to/step/unit: the
// bar's widgets, services/BarWidgets.qml, and the shell's parts, services/Parts.qml): a toggle,
// segments, a dropdown, a text box or a slider. value in, picked(value) out.
import QtQuick
import qs.services
import qs.controls

SettingRow {
    id: row

    required property var option
    property var value
    property bool locked: false
    signal picked(var value)

    title: option.label
    description: option.about ?? ""

    Loader {
        sourceComponent: ({ toggle: toggleControl, choice: choiceControl, list: listControl,
                            text: textControl })[row.option.kind] ?? numberControl
    }
    Component {
        id: toggleControl
        Toggle {
            checked: row.value
            enabled: !row.locked
            onToggled: v => row.picked(v)
        }
    }
    Component {
        id: choiceControl
        Segmented {
            options: row.option.choices
            value: row.value
            onPicked: v => row.picked(v)
        }
    }
    Component {
        id: listControl
        Dropdown {
            width: 220
            options: row.option.choices
            value: row.value
            onPicked: v => row.picked(v)
        }
    }
    Component {
        id: textControl
        TextBox {
            width: 220
            mono: true
            value: row.value
            onEdited: v => row.picked(v)
        }
    }
    Component {
        id: numberControl
        ValueSlider {
            from: row.option.from
            to: row.option.to
            step: row.option.step ?? 1
            unit: row.option.unit ?? ""
            value: row.value
            onMoved: v => row.picked(v)
        }
    }
}
