-- Oblio's glass: the oblio-glass plugin (desktop/glass), built by desktop/setup against this
-- Hyprland. It draws glass behind the shapes the shell sends (layers) and behind windows a glass
-- style tags (Settings > Appearance > Styles). Missing, or paused after a Hyprland update until
-- setup builds it again: glass styles draw as blur.
local so = (os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")) .. "/oblio-glass/oblio-glass.so"
local f = io.open(so)
if f then
    f:close()
    hl.plugin.load(so)
end

if hl.plugin.oblio_glass then
    hl.plugin.oblio_glass.config({
        enabled = false,                                      -- windows: only the ones a style tags
        -- layers: only the shapes the shell sends; what moves behind them resampled at the screen's rate
        layers = { enabled = true, mask_mode = "alpha", live_resample_fps = 0 },
    })
end
