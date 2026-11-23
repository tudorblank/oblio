-- SPDX-License-Identifier: GPL-3.0-or-later
--
-- Hyprland for Oblio's login screen, run by greetd as the "greeter" user.
-- desktop/setup installs this as /etc/greetd/oblio-hyprland.lua, adding the
-- keyboard layout and hardware bits it detects.

hl.config({
    misc = {
        disable_hyprland_logo = true,
        force_default_wallpaper = 0,
        disable_splash_rendering = true,
    },
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
    animations = {
        enabled = true,
    },
})

hl.on("hyprland.start", function()
    -- the greeter exits once you log in; then this Hyprland exits and greetd starts your session
    hl.exec_cmd("qs -p /usr/share/oblio/greeter; hyprctl dispatch 'hl.dsp.exit()'")
end)
