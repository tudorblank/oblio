// SPDX-License-Identifier: GPL-3.0-or-later
// What an edge panel (or one island of it) looks like: its shape and its tint. Drawn as if it sat
// on the bottom edge, then turned to its real edge. The blur behind it is Hyprland's, switched per
// panel by its layer namespace (EdgePanel); Oblio's own glass replaces it here later.
//   shape     floating: an island away from the edge | attached: an island grown out of the
//             edge, curving into it | full: the whole length of the edge
//   tint      color (the theme's or a chosen one) at an opacity; 100 % is opaque
import QtQuick
import QtQuick.Shapes
import qs.services

Item {
    id: s

    property string edge: "bottom"
    property string shape: "floating"
    property string material: "blur"    // solid | blur | glass
    property real opacityPercent: 35
    property string tintColor: "theme"  // or #rrggbb
    property real radius: 10
    // attached: how far the curves into the edge reach past each end (s is that much longer)
    property real fillet: 0

    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property real along: vertical ? height : width
    readonly property real thick: vertical ? width : height
    readonly property real r: Math.max(0, Math.min(radius, thick / 2, along / 2))
    readonly property real f: Math.max(0, Math.min(fillet, thick - r))

    readonly property color fill: {
        const c = Qt.color(tintColor === "theme" ? Theme.solid : tintColor)
        // Hyprland only blurs under pixels it can see (ignore_alpha in windowrules.lua)
        const a = Math.max(opacityPercent / 100, material === "solid" ? 0 : 0.02)
        return Qt.rgba(c.r, c.g, c.b, a)
    }
    readonly property color line: opacityPercent >= 100 ? Theme.hairline : Theme.border

    Item {
        id: canon
        anchors.centerIn: parent
        width: s.along
        height: s.thick
        rotation: s.edge === "top" ? 180 : s.edge === "left" ? 90 : s.edge === "right" ? -90 : 0

        // floating: rounded all round, hairline all round
        Shape {
            visible: s.shape === "floating"
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: s.fill
                strokeColor: s.line
                strokeWidth: 1
                PathRectangle { x: 0.5; y: 0.5; width: canon.width - 1; height: canon.height - 1; radius: s.r }
            }
        }

        // full: a plain strip, hairline on the side facing the windows
        Rectangle {
            visible: s.shape === "full"
            anchors.fill: parent
            color: s.fill
            Rectangle { width: parent.width; height: 1; color: s.line }
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
            visible: s.shape === "attached"
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            opacity: s.line.a
            layer.enabled: visible
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.rgba(s.line.r, s.line.g, s.line.b, 1)
                strokeWidth: 1
                startX: 0; startY: att.h - 0.5
                PathArc { x: s.f + 0.5; y: att.h - s.f; radiusX: s.f + 0.5; radiusY: s.f + 0.5; direction: PathArc.Counterclockwise }
                PathLine { x: s.f + 0.5; y: s.r }
                PathArc { x: s.f + s.r; y: 0.5; radiusX: Math.max(0, s.r - 0.5); radiusY: Math.max(0, s.r - 0.5) }
                PathLine { x: att.w - s.f - s.r; y: 0.5 }
                PathArc { x: att.w - s.f - 0.5; y: s.r; radiusX: Math.max(0, s.r - 0.5); radiusY: Math.max(0, s.r - 0.5) }
                PathLine { x: att.w - s.f - 0.5; y: att.h - s.f }
                PathArc { x: att.w; y: att.h - 0.5; radiusX: s.f + 0.5; radiusY: s.f + 0.5; direction: PathArc.Counterclockwise }
            }
        }
    }
}
