-- Tiling layouts and gaps: https://wiki.hypr.land/configuring/layouts/dwindle-layout/
-- Oblio's per-workspace floating mode (SUPER+T) is in windows.lua.

hl.config({
    general = {
        layout   = "dwindle",
        gaps_in  = 5,
        gaps_out = 20,
    },
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    scrolling = {
        fullscreen_on_one_column = true,
    },
})
