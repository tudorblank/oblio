-- Borders, rounding, shadows, blur: https://wiki.hypr.land/configuring/core/variables/#decoration

hl.config({
    general = {
        border_size = 2,
        col = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        -- drag a window's border or the gap next to it to resize
        resize_on_border        = true,
        extend_border_grab_area = 30,
        allow_tearing = false,
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        dim_special      = 0.3, -- dims what's behind the scratchpad

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee000000, -- black: it only darkens what's under it
        },

        -- Hyprland's blur until the shell starts: then it takes the Default style's look (services/Styles.qml)
        blur = {
            enabled  = true,
            size     = 8,
            passes   = 3,
            vibrancy = 0.25,
            noise    = 0.015,
            special  = true,
        },
    },
})
