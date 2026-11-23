// SPDX-License-Identifier: GPL-3.0-or-later
//@ pragma IconTheme breeze
// a fixed id keeps the state folder (settings.json) the same wherever this folder lives
//@ pragma ShellId oblio
// Oblio's shell: desktop/setup copies this folder to ~/.config/oblio-shell, Hyprland runs
// `qs -p ~/.config/oblio-shell`

import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens

        Dock {
            required property var modelData
            screen: modelData
        }
    }

    SettingsPanel {}
}
