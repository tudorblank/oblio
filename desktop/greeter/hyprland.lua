-- SPDX-License-Identifier: GPL-3.0-or-later
--
-- Hyprland for Oblio's login screen, run by greetd as the "greeter" user.
-- desktop/setup installs it as /etc/greetd/oblio-hyprland.lua.

local function exists(path)
    local f = io.open(path)
    if f then f:close() end
    return f ~= nil
end

-- keyboard layout: the console's, when it is also a desktop layout
local layout = "us"
local vconsole = io.open("/etc/vconsole.conf")
if vconsole then
    local keymap = vconsole:read("*a"):match("KEYMAP=\"?([%w_-]+)")
    vconsole:close()
    if keymap and exists("/usr/share/X11/xkb/symbols/" .. keymap) then layout = keymap end
end

local virt = io.popen("systemd-detect-virt --vm")
local vm = virt and (virt:read("*l") or "none") ~= "none"
if virt then virt:close() end

-- NVIDIA as the only GPU; on PRIME laptops these would wake it (see env.lua)
local vendors = io.popen("cat /sys/class/drm/card*/device/vendor 2>/dev/null | sort -u")
local nvidia_only = vendors and vendors:read("*a"):gsub("%s+$", "") == "0x10de"
if vendors then vendors:close() end

if exists("/proc/driver/nvidia/version") and nvidia_only then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("NVD_BACKEND", "direct")
end

hl.config({
    input = {
        kb_layout = layout,
    },
    cursor = {
        no_hardware_cursors = vm,
    },
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
