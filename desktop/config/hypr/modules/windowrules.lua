-- Window and layer rules: https://wiki.hypr.land/configuring/core/rules/

-- apps can't maximize themselves; SUPER+D does that
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- XWayland drag and drop
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- floating windows remember their size
hl.window_rule({ match = { float = true }, persistent_size = true })

-- picture-in-picture: small, floating, on top
hl.window_rule({
    match             = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    float             = true,
    keep_aspect_ratio = true,
    size              = { "max(monitor_w, monitor_h)*0.25", "min(monitor_w, monitor_h)*0.25" },
    pin               = true,
})

-- dialogs and small tools float
local floating = {
    { title = "^(Open|Open File|Open Folder|Save As|Choose Files|Authentication Required|File Upload|Confirm to replace files|File Operation Progress)$" },
    { initial_title = "^(Open File)$" },
    { class = "^([Xx]dg-desktop-portal-gtk|hyprland-share-picker)$" },
    { class = "^(.*dialog.*)$" },
    { class = "^(org\\.pulseaudio\\.pavucontrol|blueman-manager|nwg-look)$" },
    { class = "^(.*[Cc]alc.*)$" },
}
for _, m in ipairs(floating) do hl.window_rule({ match = m, float = true }) end

-- the shell's file pickers (Settings > Wallpaper)
hl.window_rule({
    match  = { class = "^(qs)$" },
    float  = true,
    center = true,
    size   = { "max(monitor_w, monitor_h)*0.42", "min(monitor_w, monitor_h)*0.6" },
})

-- size and place a few apps
hl.window_rule({ match = { class = "^(.*[Cc]alc.*)$" }, size = { "max(monitor_w, monitor_h)*0.17", "min(monitor_w, monitor_h)*0.43" } })
hl.window_rule({ match = { class = "^(.*satty.*)$", title = "^(Satty)$" }, float = true, min_size = { "max(monitor_w, monitor_h)*0.35", "min(monitor_w, monitor_h)*0.35" } })
hl.window_rule({ match = { class = "^(.*\\.exe)$", float = true }, center = true, fullscreen_state = 0 }) -- Windows programs (Wine)

-- Thunar opens floating, under the pointer (its dialogs keep their own size)
hl.window_rule({
    match = {
        class = "^([Tt]hunar)$",
        title = "negative:^(File Operation Progress|Rename .*|Create New .*|.* - Properties|Bulk Rename.*|Preferences.*|Open With|Confirm .*|Attention)$",
    },
    float = true,
    size  = { "max(monitor_w, monitor_h)*0.50", "min(monitor_w, monitor_h)*0.55" },
    move  = {
        "max(20, min(cursor_x - (window_w*0.50), monitor_w - window_w + 20))",
        "max(20, min(cursor_y - 50, monitor_h - window_h + 20))",
    },
})

-- games: fullscreen, marked as games (variable refresh rate, no compositing)
local games = "^(steam_app.*|gamescope)$"
hl.window_rule({ match = { xdg_tag = "^(.*game.*)$" }, fullscreen_state = 2, content = "game", sync_fullscreen = true })
hl.window_rule({
    match = {
        class         = games,
        title         = "^(.+)$",
        initial_title = "negative:^(.*\\\\home\\\\.*)$",
    },
    content          = "game",
    decorate         = false,
    fullscreen_state = 2,
    size             = { "monitor_w", "monitor_h" },
    sync_fullscreen  = true,
})
-- game launchers and Steam's small windows float
hl.window_rule({ match = { class = "^(steam_app.*)$", initial_title = "^$" }, float = true, center = true, fullscreen = false, fullscreen_state = 0 })
hl.window_rule({ match = { class = "^(steam)$", title = "^(Friends List)$" }, float = true })
hl.window_rule({ match = { class = "^(steam)$", title = "^(Launching\\.{3})$" }, float = true, center = true })

-- these stay fully opaque if you lower window opacity in the settings
hl.window_rule({ match = { class = "^(firefox|zen)$" }, opacity = "1.0 override" })
hl.window_rule({ match = { class = "^(kitty|ghostty|Alacritty|foot)$" }, opacity = "1.0 override" })
hl.window_rule({ match = { class = "^(mpv|.*vlc.*)$" }, opacity = "1.0 override" })

-- Hyprland's run dialog
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

-- Oblio's shell. Edge panels animate themselves; one that isn't opaque and wants blur uses the
-- "-blur" namespace (edges/EdgePanel.qml), blurred only where it's drawn
for _, name in ipairs({ "oblio-bar", "oblio-dock" }) do
    hl.layer_rule({ match = { namespace = name }, no_anim = true })
    hl.layer_rule({ match = { namespace = name .. "-blur" }, blur = true, ignore_alpha = 0.01, no_anim = true })
end
-- the wallpaper fades by itself
hl.layer_rule({ match = { namespace = "oblio-wallpaper" }, no_anim = true })
-- app launcher and notification cards: blurred behind
hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = 0.02 })
hl.layer_rule({ match = { namespace = "oblio-notifications" }, blur = true, ignore_alpha = 0.5, no_anim = true })
-- settings and popovers: blur behind the card, not the dimmed or clear screen around it
hl.layer_rule({ match = { namespace = "oblio-settings" }, blur = true, ignore_alpha = 0.5, no_anim = true })
hl.layer_rule({ match = { namespace = "oblio-popup" }, blur = true, ignore_alpha = 0.5, no_anim = true })
hl.layer_rule({ match = { namespace = "oblio-previews" }, blur = true, ignore_alpha = 0.5, no_anim = true })
