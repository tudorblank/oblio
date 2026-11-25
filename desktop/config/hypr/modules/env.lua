-- Environment variables: https://wiki.hypr.land/configuring/core/environment-variables/
-- Also works out what kind of machine this is, for the other modules.

oblio = oblio or {}

-- Oblio's shell (bar, dock, settings, notifications), copied here by desktop/setup; oblio.qs is
-- the one command that starts it (autostart, desktop/setup)
oblio.shell = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/oblio-shell"
oblio.qs = "qs -p '" .. oblio.shell .. "'"

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
-- NVIDIA is the only GPU (no AMD/Intel one next to it, as on PRIME laptops)
oblio.nvidia_only = oblio.nvidia and output("cat /sys/class/drm/card*/device/vendor 2>/dev/null | sort -u") == "0x10de"

-- Qt apps take colors, light/dark, accent, fonts and file dialogs from the GTK theme
-- (Settings > Appearance), and follow it live
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")

-- oblio-gtk-module: fixes for GTK 3 apps that a stylesheet can't reach (Thunar's sidebar)
if exists("/usr/lib/gtk-3.0/modules/liboblio-gtk.so") then
    hl.env("GTK3_MODULES", "oblio-gtk")
end

hl.env("XCURSOR_THEME", "capitaine-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- only when NVIDIA drives everything: on a PRIME laptop these would send every video and
-- X11 app to the NVIDIA GPU and keep it awake; there `prime-run APP` uses it for one app
if oblio.nvidia_only then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")         -- video decoding
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia") -- OpenGL
    hl.env("NVD_BACKEND", "direct")
end
