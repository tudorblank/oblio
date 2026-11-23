-- SPDX-License-Identifier: GPL-3.0-or-later
--
-- Oblio's desktop: window management, the shell (dock), polkit agent,
-- and the settings that go with them. Loaded from hyprland.lua.

require("oblio")

-- Dolphin's "Open with" menus outside Plasma
hl.env("XDG_MENU_PREFIX", "arch-")

hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")
    hl.exec_cmd("qs -c oblio")
end)

-- frosted glass for the dock: blur only where it's drawn (not the clear space around it)
hl.layer_rule({ match = { namespace = "oblio-dock" }, blur = true, ignore_alpha = 0.1 })
-- settings panel: blur behind the card, not the dimmed screen around it
hl.layer_rule({ match = { namespace = "oblio-settings" }, blur = true, ignore_alpha = 0.5 })

hl.config({
    decoration = {
        blur = {
            size = 8,
            passes = 3,
            vibrancy = 0.25,
            noise = 0.015,
        },
    },
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
})

-- choices from Oblio's settings panel (SUPER+I), written by the shell
local settings = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/oblio/hyprland.lua"
local f = io.open(settings)
if f then
    f:close()
    pcall(dofile, settings)
end
