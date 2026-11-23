-- Environment variables: https://wiki.hypr.land/configuring/core/environment-variables/
-- Also works out what kind of machine this is, for the other modules.

oblio = oblio or {}

local function output(cmd)
    local p = io.popen(cmd)
    if not p then return "" end
    local out = p:read("*a") or ""
    p:close()
    return (out:gsub("%s+$", ""))
end

local function exists(path)
    local f = io.open(path)
    if f then f:close() end
    return f ~= nil
end

local virt = output("systemd-detect-virt --vm")
oblio.vm = virt ~= "" and virt ~= "none"
oblio.nvidia = exists("/proc/driver/nvidia/version")

hl.env("XCURSOR_THEME", "capitaine-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Dolphin's "Open with" menus outside Plasma
hl.env("XDG_MENU_PREFIX", "arch-")

if oblio.nvidia then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")         -- video decoding
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia") -- OpenGL
    hl.env("NVD_BACKEND", "direct")
end
