// SPDX-License-Identifier: GPL-3.0-or-later
// Empty space: a fixed length, or all the free room of its section (fixed or full-width bar).
import QtQuick
import qs.bar

BarWidget {
    island: false
    interactive: false
    expand: opt("expand")
    length: opt("length")
}
