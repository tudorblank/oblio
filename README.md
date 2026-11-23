# Oblio

A personal Arch Linux distribution built on CachyOS's repositories, kernels and tuning.
Terminal installer, btrfs with bootable snapshots, Limine.

## Layout

```
branding/     logo and icon
config/       what an Oblio system is made of
  components/   one file per component: packages + services (optional ones show up in the installer)
  pacman.conf   template, Cachy repos are filled in per CPU
  btrfs.conf    subvolume layout and mount options
  limine.conf   boot menu settings
packages/     Oblio's own packages (oblio-hooks, oblio-settings)
installer/    oblio-install (the step-by-step installer), engine.sh (install steps), oblio-repos (CPU detection)
iso/          what the Oblio ISO adds on top of Arch's live ISO
desktop/      the Oblio desktop: hyprland/ (setup, oblio.lua window management), shell/ (Quickshell: dock)
tools/        build-packages, build-iso, oblio-vm
```

## Build the ISO

```
sudo pacman -S archiso
tools/build-iso
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
oblio-main/installer/oblio-install
```

## Desktop

On an installed Oblio, as your user:

```
curl -L https://github.com/tudorblank/oblio/archive/refs/heads/main.tar.gz | tar xz
oblio-main/desktop/setup
start-hyprland
```

Hyprland with Oblio's window management and dock, Alacritty, Dolphin, Zen and Hyprland's
launcher. In a VM the main key is Alt instead of Super.

| Keys | |
|---|---|
| SUPER+Enter / E / W / R | terminal / files / browser / launcher |
| SUPER+I | settings: dock, windows, appearance, input |
| SUPER+Q | close window |
| SUPER+D / SUPER+F | maximize / fullscreen |
| SUPER+C / SUPER+SHIFT+C | minimize / restore last minimized |
| SUPER+SHIFT+D | show desktop (minimize all), again to bring them back |
| SUPER+T | this workspace: tiling <-> floating (KDE-like, cascading windows) |

Everything in `desktop/config/` lands at the same path in `~/.config`. `desktop/setup --link`
symlinks instead of copying, so edits in the repo apply live. `hyprland.lua` is written on the
first run only (`--fresh` rewrites it); Oblio's parts live in the `oblio*.lua` files next to it.

Dock: click opens, focuses or restores; clicking the focused app minimizes it; right click
minimizes or restores all of an app's windows; middle click opens a new window.
