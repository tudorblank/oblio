// SPDX-License-Identifier: GPL-3.0-or-later
// The settings every edge panel has (edges/EdgePanel.qml): where it sits, when it shows and its
// shape. Used by the Bar and Dock pages with their prefix; their look is a style (Appearance).
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
                tint: Styles.look(es.prefix).tint
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
}
