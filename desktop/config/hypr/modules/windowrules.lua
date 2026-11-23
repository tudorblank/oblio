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
    { title = "^(.*dialog.*)$" },
    { class = "^(org\\.pulseaudio\\.pavucontrol|blueman-manager|nm-connection-editor|qt[56]ct|kvantummanager|nwg-look)$" },
    { class = "^(org\\.kde\\.keditfiletype|.*[Cc]alc.*)$" },
}
for _, m in ipairs(floating) do hl.window_rule({ match = m, float = true }) end

-- size and place a few apps
hl.window_rule({ match = { class = "^(.*[Cc]alc.*)$" }, size = { "max(monitor_w, monitor_h)*0.17", "min(monitor_w, monitor_h)*0.43" } })
hl.window_rule({ match = { class = "^(org\\.kde\\.ark)$" }, size = { "max(monitor_w, monitor_h)*0.40", "min(monitor_w, monitor_h)*0.40" } })
hl.window_rule({ match = { class = "^(.*satty.*)$", title = "^(Satty)$" }, float = true, min_size = { "max(monitor_w, monitor_h)*0.35", "min(monitor_w, monitor_h)*0.35" } })
hl.window_rule({ match = { class = "^(.*[Ll]auncher.*)$" }, float = true })
hl.window_rule({ match = { class = "^(.*\\.exe)$", float = true }, center = true, fullscreen_state = 0 }) -- Windows programs (Wine)

-- Dolphin opens floating, under the pointer (dialogs keep their own size)
hl.window_rule({
    match = {
        class = "^(org\\.kde\\.dolphin)$",
        title = "negative:^(Moving.*|Create New.*|Extract.*|Compress.*|Copying.*|Progress.*|Configure.*|Properties.*|Choose\\sApplication.*)$",
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
hl.window_rule({ match = { class = "^(kitty|ghostty|[Kk]onsole|Alacritty|foot)$" }, opacity = "1.0 override" })
hl.window_rule({ match = { class = "^(mpv|org\\.kde\\.haruna|.*plex.*|org\\.kde\\.gwenview|.*vlc.*)$" }, opacity = "1.0 override" })

-- Hyprland's run dialog
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

-- Oblio's shell: frosted glass only where it's drawn; it animates itself, so no Hyprland animation on top
hl.layer_rule({ match = { namespace = "oblio-dock" }, blur = true, ignore_alpha = 0.1, no_anim = true })
-- settings panel: blur behind the card, not the dimmed screen around it
hl.layer_rule({ match = { namespace = "oblio-settings" }, blur = true, ignore_alpha = 0.5, no_anim = true })
