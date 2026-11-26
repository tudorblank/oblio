// SPDX-License-Identifier: GPL-3.0-or-later
// The shape of an edge panel (or one island of it), filled and outlined in its style's colors
// (Styles.look). Drawn as if it sat on the bottom edge, then turned to its real edge. The blur
// behind it is Hyprland's, by the style's rule for the panel's layer; Oblio's own glass goes here.
//   shape     floating: an island away from the edge | attached: an island grown out of the
//             edge, curving into it | full: the whole length of the edge
import QtQuick
import QtQuick.Shapes

Item {
    id: s

    property string edge: "bottom"
    property string shape: "floating"
    property color fill
    property color line
    property real lineWidth: 1
    property real radius: 10
    // attached: how far the curves into the edge reach past each end (s is that much longer)
    property real fillet: 0

    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property real along: vertical ? height : width
    readonly property real thick: vertical ? width : height
    readonly property real r: Math.max(0, Math.min(radius, thick / 2, along / 2))
    readonly property real f: Math.max(0, Math.min(fillet, thick - r))
    // the outline sits inside the shape: its middle is half its width in
    readonly property real w: Math.min(lineWidth, thick / 2)
    readonly property real h: w / 2

    Item {
        id: canon
        anchors.centerIn: parent
        width: s.along
        height: s.thick
        rotation: s.edge === "top" ? 180 : s.edge === "left" ? 90 : s.edge === "right" ? -90 : 0

        // floating: rounded all round, outlined all round
        Shape {
            visible: s.shape === "floating"
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: s.fill
                strokeColor: s.w > 0 ? s.line : "transparent"
                strokeWidth: s.w
                PathRectangle { x: s.h; y: s.h; width: canon.width - s.w; height: canon.height - s.w; radius: Math.max(0, s.r - s.h) }
            }
        }

        // full: a plain strip, outlined on the side facing the windows
        Rectangle {
            visible: s.shape === "full"
            anchors.fill: parent
            color: s.fill
            Rectangle { width: parent.width; height: s.w; color: s.line }
        }

        // attached: rounded outer corners, the sides curving out into the edge (_/‾‾\_)
        Shape {
            id: att
            visible: s.shape === "attached"
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            readonly property real w: canon.width
            readonly property real h: canon.height
            ShapePath {
                fillColor: s.fill
                strokeColor: "transparent"
                startX: 0; startY: att.h + 1
                PathLine { x: 0; y: att.h }
                PathArc { x: s.f; y: att.h - s.f; radiusX: s.f; radiusY: s.f; direction: PathArc.Counterclockwise }
                PathLine { x: s.f; y: s.r }
                PathArc { x: s.f + s.r; y: 0; radiusX: s.r; radiusY: s.r }
                PathLine { x: att.w - s.f - s.r; y: 0 }
                PathArc { x: att.w - s.f; y: s.r; radiusX: s.r; radiusY: s.r }
                PathLine { x: att.w - s.f; y: att.h - s.f }
                PathArc { x: att.w; y: att.h; radiusX: s.f; radiusY: s.f; direction: PathArc.Counterclockwise }
                PathLine { x: att.w; y: att.h + 1 }
            }
        }
        // the outline is drawn opaque and faded as a whole: a see-through stroke drawn in pieces
        // doubles up where they meet, which shows as bright dots at small roundness
        Shape {
            visible: s.shape === "attached" && s.w > 0
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            opacity: s.line.a
            layer.enabled: visible
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.rgba(s.line.r, s.line.g, s.line.b, 1)
                strokeWidth: s.w
                startX: 0; startY: att.h - s.h
                PathArc { x: s.f + s.h; y: att.h - s.f; radiusX: s.f + s.h; radiusY: s.f + s.h; direction: PathArc.Counterclockwise }
                PathLine { x: s.f + s.h; y: s.r }
                PathArc { x: s.f + s.r; y: s.h; radiusX: Math.max(0, s.r - s.h); radiusY: Math.max(0, s.r - s.h) }
                PathLine { x: att.w - s.f - s.r; y: s.h }
                PathArc { x: att.w - s.f - s.h; y: s.r; radiusX: Math.max(0, s.r - s.h); radiusY: Math.max(0, s.r - s.h) }
                PathLine { x: att.w - s.f - s.h; y: att.h - s.f }
                PathArc { x: att.w; y: att.h - s.h; radiusX: s.f + s.h; radiusY: s.f + s.h; direction: PathArc.Counterclockwise }
            }
        }
    }
}
