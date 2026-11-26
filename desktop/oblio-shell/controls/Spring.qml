// SPDX-License-Identifier: GPL-3.0-or-later
// A springy move for what changes while it moves (a size that follows typing): it keeps its speed
// when the target changes again instead of starting over. Follows the animation speed in Settings
// like Theme.ms (a spring has no duration: its stiffness goes with the speed squared); with
// animations off it's there at once.
import QtQuick
import qs.services

SpringAnimation {
    spring: 7 / Math.pow(Math.max(Theme.motion, 0.02), 2)
    damping: 0.45
    epsilon: 0.25
}
