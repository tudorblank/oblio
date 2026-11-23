# Oblio

A personal Arch Linux distribution built on CachyOS's repositories, kernels and tuning.
Terminal installer, btrfs with bootable snapshots, Limine.

## Layout

```
base/         what an Oblio system is made of
  config/       components/ (one file per component: packages + services; optional ones show up
                in the installer), pacman.conf (Cachy repos filled in per CPU), btrfs.conf, limine.conf
  packages/     Oblio's own packages: oblio-hooks (branding, pacman hooks), oblio-settings (system config)
desktop/      the Oblio desktop: setup, config/ (lands in ~/.config: hypr/, quickshell/), greeter/ (login screen)
tools/        installing and tooling
  installer/    oblio-install (the step-by-step installer), engine.sh (install steps), oblio-repos (CPU detection)
  build-packages, oblio-vm (test VM)
iso/          the Oblio ISO: build-iso, and what it adds on top of Arch's live ISO
```

## Build the ISO

```
sudo pacman -S archiso
iso/build-iso
```

The ISO lands in `out/`. It boots straight into the installer.

## Test in a VM

```
sudo pacman -S qemu-desktop edk2-ovmf
tools/oblio-vm install   # boots the newest ISO from out/
tools/oblio-vm run       # boots the installed system
tools/oblio-vm reset     # wipes the VM disk
```

## Install

Boot the ISO and follow the steps: keyboard, language, time zone, disk (erase or manual),
encryption, kernel, components, user. Nothing touches the disk before the summary is confirmed.

The installer also runs from a plain Arch ISO, building Oblio's packages on the fly:

```
curl -L https://github.com/tudorblank/oblio/archive/refs/heads/main.tar.gz | tar xz
oblio-main/tools/installer/oblio-install
```

## Desktop

On an installed Oblio, as your user:

```
curl -L https://github.com/tudorblank/oblio/archive/refs/heads/main.tar.gz | tar xz
oblio-main/desktop/setup
reboot
```

After the reboot you get Oblio's login screen (greetd + a Quickshell greeter): pick the user and
the session (Hyprland, or anything else installed) and log in. If another login manager is already
set up (SDDM, GDM...), setup leaves it alone unless you run `desktop/setup --greeter`.

Hyprland with Oblio's window management and dock, Alacritty, Dolphin, Zen and Hyprland's
launcher. In a VM the main key is Alt instead of Super.

| Keys | |
|---|---|
| SUPER+Enter / E / W / R | terminal / files / browser / launcher |
| SUPER+I | settings: dock, windows, appearance, input |
| SUPER+Q | close window |
| SUPER+D / SUPER+F | maximize / fullscreen |
| SUPER+C / SUPER+ALT+C | minimize / restore last minimized (back where it was, same place and size) |
| SUPER+SHIFT+D | show desktop (minimize all), again to bring them back |
| SUPER+T | this workspace: tiling <-> floating (KDE-like, cascading windows) |
| SUPER+S / Print | screenshot of an area / the screen (saved to ~/Pictures/Screenshots, copied) |
| SUPER+P / SUPER+SHIFT+P | scratchpad / move the window there |
| SUPER+Escape | click a frozen window to kill it |
| SUPER+CTRL+SHIFT+arrows | resize the window (or drag its edge, or SUPER+right-drag) |
| SUPER+SHIFT+I / CTRL+SHIFT+Escape | color picker / task manager (btop) |

All keys: `~/.config/hypr/modules/binds.lua`.

Everything in `desktop/config/` lands at the same path in `~/.config` (a file it replaces is kept
as `NAME.bak.DATE`); `desktop/setup --link` symlinks instead of copying, so edits in the repo apply
live. Hyprland: `hyprland.lua` loads `modules/` (monitors, env, input, layout, decorations,
animations, misc, windowrules, windows, binds, autostart); what you change in the settings panel is
saved to `settings.lua` next to it and wins over the modules.

Dock: click opens an app; on a running app it focuses its window if it isn't focused, minimizes it
if it is, and brings minimized windows back (to their workspace, place and size, focused); middle click opens a new window; right click opens
a menu: the app's windows, New window, Pin to dock / Unpin from dock, Quit. The dock never moves
the pointer. It can always show, auto-hide (the bottom edge brings it back) or hide smartly (only
while a window reaches into it), and it disappears when it has nothing to show (SUPER+I, Dock).
