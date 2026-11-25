// SPDX-License-Identifier: GPL-3.0-or-later
// The settings every edge panel has (edges/EdgePanel.qml): where it sits, when it shows, its
// shape and its look. Used by the Bar and Dock pages with their prefix.
import QtQuick
import qs.services
import qs.controls

Column {
    id: es

    property string prefix
    property string noun                // "bar", "dock"
    property var edges: []              // [{ value, label }] it may sit on
    property string takenEdge: ""       // the edge the other panel uses: greyed out
    property int sizeFrom: 24
    property int sizeTo: 64
    property bool islands: false        // floating: one surface or its islands apart (the bar)

    readonly property var o: Settings.opts
    function get(name) { return o[prefix + name] }
    function set(name, v) { Settings.set(prefix + name, v) }

    readonly property string edge: get("Edge")
    // the tint is per mode: this one's
    readonly property string colorKey: Theme.dark ? "Color" : "ColorLight"

    spacing: 22

    SettingGroup {
        title: "PLACE"

        SettingRow {
            visible: es.edges.length > 1
            title: "Position"
            description: "The screen edge it sits on"
            Segmented {
                options: es.edges.map(e => Object.assign({}, e, { disabled: e.value === es.takenEdge }))
                value: es.edge
                onPicked: v => es.set("Edge", v)
            }
        }
        SettingRow {
            title: "Show"
            description: es.get("Mode") === "autohide" ? `Hidden until the pointer touches the ${es.edge} edge`
                : es.get("Mode") === "smart" ? `Hides while a window reaches into it; the ${es.edge} edge brings it back`
                : "Always on screen; windows keep their gap from it"
            Segmented {
                options: [{ value: "always", label: "Always" }, { value: "autohide", label: "Auto-hide" }, { value: "smart", label: "Smart" }]
                value: es.get("Mode")
                onPicked: v => es.set("Mode", v)
            }
        }
    }

    SettingGroup {
        title: "SHAPE"

        Item {
            width: parent.width
            height: 104 + 28

            ShapePicker {
                anchors.centerIn: parent
                edge: es.edge
                value: es.get("Shape")
                roundness: es.get("Roundness")
                tintColor: es.get(es.colorKey)
                onPicked: v => es.set("Shape", v)
            }
        }
        // a floating bar: one surface, or its islands apart (each continuous or scattered: BarLayout)
        SettingRow {
            visible: es.islands && es.get("Shape") === "floating"
            title: "Islands"
            description: es.get("Islands") === "sections" ? "Each island stands on its own" : "One bar holding every island"
            Segmented {
                options: [{ value: "bar", label: "One bar" }, { value: "sections", label: "Sections" }]
                value: es.get("Islands")
                onPicked: v => es.set("Islands", v)
            }
        }
        SettingRow {
            visible: es.get("Shape") !== "full"
            title: "Roundness"
            description: "From square corners to fully round ends"
            ValueSlider {
                from: 0; to: 100; step: 5; unit: "%"
                value: es.get("Roundness")
                onMoved: v => es.set("Roundness", v)
            }
        }
        SettingRow {
            visible: es.get("Shape") !== "full"
            title: "Length"
            description: es.get("Length") === "fixed" ? `A share of the ${es.edge} edge` : "Grows and shrinks with what it holds"
            Segmented {
                options: [{ value: "fit", label: "Fit" }, { value: "fixed", label: "Fixed" }]
                value: es.get("Length")
                onPicked: v => es.set("Length", v)
            }
        }
        SettingRow {
            visible: es.get("Shape") !== "full" && es.get("Length") === "fixed"
            title: "Share of the edge"
            description: "0% just fits what it holds, 100% spans the whole edge"
            ValueSlider {
                from: 0; to: 100; step: 5; unit: "%"
                value: es.get("LengthPercent")
                onMoved: v => es.set("LengthPercent", v)
            }
        }
        SettingRow {
            title: "Size"
            description: `Thickness of the ${es.noun}`
            ValueSlider {
                from: es.sizeFrom; to: es.sizeTo; unit: " px"
                value: es.get("Size")
                onMoved: v => es.set("Size", v)
            }
        }
    }

    // opaque means solid: nothing to blur behind it
    SettingGroup {
        title: "LOOK"

        SettingRow {
            title: "Material"
            description: es.get("Material") === "solid" ? (es.get("Opacity") >= 100 ? "Opaque" : "See-through, without blur")
                : "The desktop behind it, blurred. Glass, Oblio's own, comes next"
            Segmented {
                options: [{ value: "solid", label: "Solid" }, { value: "blur", label: "Blur" }, { value: "glass", label: "Glass", disabled: true }]
                value: es.get("Material")
                onPicked: v => {
                    if (v !== "solid" && es.get("Opacity") >= 100) es.set("Opacity", 70)
                    es.set("Material", v)
                }
            }
        }
        SettingRow {
            title: "Tint"
            description: es.get(es.colorKey) === "theme" ? "Follows light and dark mode"
                : `A color of your own, in ${Theme.dark ? "dark" : "light"} mode`
            Segmented {
                options: [{ value: "theme", label: "Theme" }, { value: "custom", label: "Custom" }]
                value: es.get(es.colorKey) === "theme" ? "theme" : "custom"
                onPicked: v => es.set(es.colorKey, v === "theme" ? "theme" : tints.colors[0])
            }
        }
        SettingRow {
            visible: es.get(es.colorKey) !== "theme"
            title: "Tint color"
            Swatches {
                id: tints
                pickerTitle: "Tint color"
                colors: Theme.dark ? ["#26262c", "#1e2a3a", "#2a1e33", "#1e3328", "#3a2a1e"]
                                   : ["#e8e8ec", "#dde6f2", "#eadff0", "#dcebe0", "#f0e6da"]
                value: es.get(es.colorKey)
                onPicked: v => es.set(es.colorKey, v)
            }
        }
        SettingRow {
            title: "Opacity"
            description: es.get("Opacity") >= 100 ? "Opaque: solid, nothing blurred behind it" : "How much of the tint covers what's behind"
            ValueSlider {
                from: 0; to: 100; unit: "%"
                value: es.get("Opacity")
                onMoved: v => {
                    es.set("Opacity", v)
                    if (v >= 100) es.set("Material", "solid")
                }
            }
        }
    }
}
