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

-- Files (Nautilus) opens floating, under the pointer (its dialogs keep their own size)
hl.window_rule({
    match = {
        class = "^(org\\.gnome\\.Nautilus)$",
        title = "negative:^(Properties|.* Properties|Preferences|Rename.*|Open With.*|Select .*|Compress.*|Keyboard Shortcuts)$",
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

-- Hyprland's run dialog
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

-- a window the shell is animating (windows.lua): invisible in its place while its picture flies
hl.window_rule({
    name     = "oblio-hidden",
    match    = { tag = "oblio-hidden" },
    opacity  = "0.0 override 0.0 override",
    no_anim  = true,
})
-- held while it shows again, so it appears at once instead of fading in under the picture
hl.window_rule({ name = "oblio-still", match = { tag = "oblio-still" }, no_anim = true })

-- Oblio's shell animates its own layers (the wallpaper fades by itself; windows flying into and
-- out of the dock show at once, exactly over the window). The shell's parts get theirs, with blur,
-- from Settings > Appearance > Styles, as named rules in settings.lua; these two have no style
for _, name in ipairs({ "oblio-wallpaper", "oblio-fx" }) do
    hl.layer_rule({ match = { namespace = "^(" .. name .. ")$" }, no_anim = true })
end
