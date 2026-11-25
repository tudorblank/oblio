// SPDX-License-Identifier: GPL-3.0-or-later
// The desktop-space engine: one panel along a screen edge (the bar, the dock), per screen.
// It owns:
//   space       it reserves exactly what it covers from the edge (its gap + its thickness),
//               nothing towards the windows: tiled windows keep their own outer gap on every side
//   placement   side panels fit between the top and bottom ones (services/Space.qml)
//   look        shape, roundness and tint (Surface.qml); blur behind it only while it isn't opaque
//   showing     always | autohide (the edge brings it back) | smart (hides while a window
//               reaches into it), sliding off the edge
// Its settings are Settings.opts.<prefix><Name> (Edge, Shape, Roundness, Material, Opacity, Color,
// Length, LengthPercent, Mode, Size). The content goes inside as children, laid out in contentItem,
// and says how long it is along the edge (contentLength) for the "fit" length.
//
// Two layer surfaces: the panel itself, which ignores reserved space so it sits exactly at the
// screen's edge, and an invisible 1x1 one that only reserves the space. Hyprland blurs by layer
// namespace, which can't change on a live surface: turning blur on or off makes a new panel
// surface, and the content moves over to it.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

Scope {
    id: root

    required property var screen
    property string prefix
    property real contentLength: 0
    property real padding: 12          // between the panel's ends and its content
    property real overflow: 0          // room past the inner face, e.g. for labels (no input there)
    property bool empty: false         // nothing to show: no panel, no space
    property bool forceShown: false    // shown whatever the mode, e.g. while a menu is open
    property bool drawSurface: true    // false: the content draws its own islands
    default property alias content: holder.data
    readonly property Item contentItem: holder

    readonly property var o: Settings.opts
    readonly property string edge: o[prefix + "Edge"]
    readonly property string shape: o[prefix + "Shape"]
    readonly property string mode: o[prefix + "Mode"]
    readonly property int thickness: o[prefix + "Size"]
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property bool floating: shape === "floating"
    readonly property string material: o[prefix + "Material"]
    readonly property int tintOpacity: o[prefix + "Opacity"]
    // a custom tint is chosen per mode, so text drawn for the mode stays readable on it
    readonly property string tintColor: o[prefix + (Theme.dark ? "Color" : "ColorLight")]
    readonly property bool blurred: material !== "solid" && tintOpacity < 100

    // a floating island keeps this far from the screen's edges
    readonly property int gap: floating ? 8 : 0
    readonly property int extent: gap + thickness
    readonly property int reserved: mode === "always" && !empty ? extent : 0
    // roundness: 0 square .. 100 fully round ends
    function rounded(thick) { return Theme.rounded(o[prefix + "Roundness"], thick) }
    readonly property real radius: shape === "full" ? 0 : rounded(thickness)
    readonly property real fillet: shape === "attached" ? radius : 0

    // along the edge: side panels fit between the top and bottom ones
    readonly property real startInset: vertical ? Space.occupied(screen.name, "top") : 0
    readonly property real endInset: vertical ? Space.occupied(screen.name, "bottom") : 0
    readonly property real available: (vertical ? screen.height : screen.width) - startInset - endInset
    // fit: just what it holds; fixed: a share of the room between that and the whole edge (0% fits
    // what it holds, 100% spans the edge), so what it holds always fits
    readonly property real fitLength: contentLength + 2 * padding
    readonly property real length: {
        if (shape === "full") return available
        const room = available - 2 * (gap + fillet)
        const fit = Math.min(fitLength, room)
        const wanted = o[prefix + "Length"] === "fixed" ? fit + (room - fit) * o[prefix + "LengthPercent"] / 100 : fit
        return Math.max(thickness, wanted)
    }
    readonly property real start: startInset + (available - length) / 2

    property bool hovering: false
    readonly property var monitor: Hyprland.monitorFor(screen)
    // smart: is a window on this screen's workspace reaching into the panel's band?
    readonly property bool covered: {
        if (mode !== "smart" || !monitor || !monitor.activeWorkspace) return false
        let x0, y0, x1, y1
        if (vertical) {
            y0 = screen.y + start; y1 = y0 + length
            x0 = edge === "left" ? screen.x : screen.x + screen.width - extent; x1 = x0 + extent
        } else {
            x0 = screen.x + start; x1 = x0 + length
            y0 = edge === "top" ? screen.y : screen.y + screen.height - extent; y1 = y0 + extent
        }
        for (const t of Hyprland.toplevels.values) {
            if (t.workspace !== monitor.activeWorkspace) continue
            const w = t.lastIpcObject
            if (!w || !w.at || !w.size) continue
            if (w.at[0] < x1 && w.at[0] + w.size[0] > x0 && w.at[1] < y1 && w.at[1] + w.size[1] > y0) return true
        }
        return false
    }
    readonly property bool shown: !empty && (mode === "always" || hovering || forceShown || (mode === "smart" && !covered))

    readonly property bool watching: mode === "smart" && !empty
    Component.onCompleted: {
        Space.add(root)
        Hyprland.refreshToplevels()
    }
    Component.onDestruction: {
        Space.remove(root)
    }

    // where an item inside the panel is, in the screen's coordinates (for popovers)
    property var window: null
    function screenRect(item) {
        if (!window) return Qt.rect(0, 0, 0, 0)
        const p = item.mapToItem(null, 0, 0)
        const wx = edge === "right" ? screen.width - window.width : 0
        const wy = edge === "bottom" ? screen.height - window.height : 0
        return Qt.rect(wx + p.x, wy + p.y, item.width, item.height)
    }

    // the content, moved into whichever panel surface exists
    Item {
        id: holder
        anchors.fill: parent
    }

    // something placed in the panel's window by its distance along the edge and from the edge
    component Placed: Item {
        property real along
        property real depth
        property real len
        property real thick
        x: !root.vertical ? along : root.edge === "left" ? depth : parent.width - depth - thick
        y: root.vertical ? along : root.edge === "top" ? depth : parent.height - depth - thick
        width: root.vertical ? thick : len
        height: root.vertical ? len : thick
    }

    Variants {
        model: ["oblio-" + root.prefix + (root.blurred ? "-blur" : "")]

        PanelWindow {
            id: win
            required property string modelData
            screen: root.screen
            anchors {
                top: root.edge !== "bottom"
                bottom: root.edge !== "top"
                left: root.edge !== "right"
                right: root.edge !== "left"
            }
            implicitWidth: root.vertical ? root.extent + root.overflow : 1
            implicitHeight: root.vertical ? 1 : root.extent + root.overflow
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.namespace: modelData
            mask: Region { item: root.empty ? nothing : root.shown ? band : strip }

            Component.onCompleted: {
                holder.parent = contentArea
                root.window = win
            }

            HoverHandler {
                onHoveredChanged: {
                    if (hovered) {
                        hideTimer.stop()
                        root.hovering = true
                    } else {
                        hideTimer.restart()
                    }
                }
            }
            Timer {
                id: hideTimer
                interval: 400
                onTriggered: root.hovering = false
            }

            Item { id: nothing }
            // the panel and the gap to the edge, so the pointer resting on the edge keeps it shown
            Placed { id: band; along: root.start; depth: 0; len: root.length; thick: root.extent }
            // a thin strip on the edge that brings a hidden panel back
            Placed { id: strip; along: root.start; depth: 0; len: root.length; thick: 3 }

            Placed {
                id: body
                along: root.startInset + (root.available - len) / 2
                depth: root.shown ? root.gap : -(root.thickness + 4)
                len: root.length
                thick: root.thickness

                Behavior on depth { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                Behavior on len { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Surface {
                    visible: root.drawSurface
                    anchors.fill: parent
                    anchors.leftMargin: root.vertical ? 0 : -root.fillet
                    anchors.rightMargin: root.vertical ? 0 : -root.fillet
                    anchors.topMargin: root.vertical ? -root.fillet : 0
                    anchors.bottomMargin: root.vertical ? -root.fillet : 0
                    edge: root.edge
                    shape: root.shape
                    material: root.material
                    opacityPercent: root.tintOpacity
                    tintColor: root.tintColor
                    radius: root.radius
                    fillet: root.fillet
                }

                Item {
                    id: contentArea
                    anchors.fill: parent
                    anchors.leftMargin: root.vertical ? 0 : root.padding
                    anchors.rightMargin: root.vertical ? 0 : root.padding
                    anchors.topMargin: root.vertical ? root.padding : 0
                    anchors.bottomMargin: root.vertical ? root.padding : 0
                }
            }
        }
    }

    // reserves the space; the panel above ignores reserved space to sit exactly at the edge
    PanelWindow {
        screen: root.screen
        anchors {
            top: root.edge === "top"
            bottom: root.edge === "bottom"
            left: root.edge === "left"
            right: root.edge === "right"
        }
        implicitWidth: 1
        implicitHeight: 1
        exclusiveZone: root.reserved
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "oblio-space"
    }
}
