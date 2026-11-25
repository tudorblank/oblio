// SPDX-License-Identifier: GPL-3.0-or-later
// The built-in screen's brightness (services/Brightness.qml); scroll to change. Hidden without a
// backlight.
import QtQuick
import qs.services
import qs.bar

BarWidget {
    id: w

    function glyph(p) { return Icons.brightness[p < 34 ? 0 : p < 67 ? 1 : 2] }

    Component.onCompleted: Brightness.users++
    Component.onDestruction: Brightness.users--

    length: Brightness.present ? row.length : 0
    popup: panel
    onScrolled: s => Brightness.set(s > 0 ? "5%+" : "5%-")

    IconValue {
        id: row
        widget: w
        icon: w.glyph(Brightness.percent)
        value: Brightness.percent + "%"
        showValue: w.opt("value")
    }

    Component {
        id: panel
        PopupSlider {
            icon: w.glyph(Brightness.percent)
            title: "Brightness"
            detail: "Built-in screen"
            value: Brightness.percent
            onMoved: v => Brightness.set(Math.max(1, Math.round(v)) + "%")
        }
    }
}
