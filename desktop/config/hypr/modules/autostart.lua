-- Started with Hyprland: https://wiki.hypr.land/configuring/core/autostart/

hl.on("hyprland.start", function()
    -- apps started over D-Bus (portals, file pickers) get this session's environment
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")
    hl.exec_cmd("qs -c oblio")
    -- admin apps run with sudo/pkexec (GParted, ...) can open windows
    hl.exec_cmd("xhost +SI:localuser:root")
end)
