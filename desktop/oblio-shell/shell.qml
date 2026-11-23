// SPDX-License-Identifier: GPL-3.0-or-later
//@ pragma IconTheme WhiteSur
// a fixed id keeps the state folder (settings.json) the same wherever this folder lives
//@ pragma ShellId oblio
// Oblio's shell: desktop/setup copies this folder to ~/.config/oblio-shell, Hyprland runs
// `qs -p ~/.config/oblio-shell`

import Quickshell
import qs.services
import qs.dock
import qs.settings

ShellRoot {
    // starting it applies the theme to GTK, icons, fonts and the terminal
    readonly property var systemTheme: SystemTheme

    Variants {
        model: Quickshell.screens

        Dock {
            required property var modelData
            screen: modelData
        }
    }

    SettingsPanel {}
}
