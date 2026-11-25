// SPDX-License-Identifier: GPL-3.0-or-later
// The shell's one way to move things: Theme's duration, one easing. Use it in Behaviors and
// transitions so everything that moves together arrives together.
import QtQuick
import qs.services

NumberAnimation {
    duration: Theme.motionNormal
    easing.type: Easing.OutCubic
}
