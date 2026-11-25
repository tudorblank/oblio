-- Everything else: https://wiki.hypr.land/configuring/core/variables/#misc

hl.config({
    misc = {
        -- the shell draws the wallpaper (Settings > Wallpaper)
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        middle_click_paste      = false,
        -- a terminal hides while a window it started is open (an image viewer, mpv, ...)
        enable_swallow = true,
        swallow_regex  = "^(Alacritty|kitty|foot|ghostty|org\\.wezfurlong\\.wezterm)$",
        -- variable refresh rate for fullscreen games and videos
        vrr = 3,
    },
    render = {
        direct_scanout = 2, -- fullscreen games skip compositing
    },
    xwayland = {
        force_zero_scaling = true, -- X11 apps stay sharp on scaled monitors
    },
    layers = {
        allow_new_top_layers_over_existing_fullscreen = true,
    },
    ecosystem = {
        no_update_news  = true,
        no_donation_nag = true,
    },
})

-- virtual machines: the virtual GPU has no hardware cursor
if oblio.vm then
    hl.config({
        cursor = {
            no_hardware_cursors = true,
        },
    })
end
