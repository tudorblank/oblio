# Oblio

A personal Arch Linux distribution built on CachyOS's repositories, kernels and tuning.
It installs in two parts:

1. **The base**: a complete, fast system with a terminal. This is what the Oblio ISO installs.
2. **The Oblio desktop**: Hyprland with Oblio's shell (dock, settings, login screen), installed
   afterwards with one command, straight from this repository.

## Part 1: the base

**Before you install:** turn off **Secure Boot** in your computer's firmware settings (often under
Boot or Security, opened with F2, F10, F12 or Del while it starts). Oblio's ISO isn't signed for
Secure Boot, so with it on the computer refuses to start it. Also make sure the firmware boots in
UEFI mode (not "Legacy" or "CSM").

Boot the Oblio ISO and follow the steps: keyboard, language, time zone, disk (erase it, or pick
partitions for dual boot), encryption, kernel, components, user. Nothing touches the disk before
the summary is confirmed. Esc goes back a step, Ctrl+C quits.

After the reboot you log in on a text console, with fish as the shell. The first login greets you
and points at the desktop install; your home already has Desktop, Documents, Downloads, Music,
Pictures, Public and Videos.

What it installs:

| Component | Packages | Running |
|---|---|---|
| Core system | `base` `mkinitcpio` `linux-firmware` `amd-ucode` `intel-ucode` `fish` `sudo` `micro` (the editor) `less` `man-db` `man-pages` `xdg-user-dirs` `terminus-font` (the console font, sized to your screen) | systemd-oomd, fstrim (weekly) |
| Kernel | your choice of CachyOS kernel (`linux-cachyos`, `-bore`, `-eevdf`, `-bmq`, `-rt-bore`, `-hardened`, `-server`, `-deckify`), plus `linux-cachyos-lts` as a fallback if you want it | |
| CachyOS optimizations | `cachyos-settings` `ananicy-cpp` `cachyos-ananicy-rules` `cachyos-keyring` `cachyos-mirrorlist` `cachyos-rate-mirrors`, and `cachyos-v3-mirrorlist` or `cachyos-v4-mirrorlist` to match your CPU | ananicy-cpp, mirror ranking |
| Hardware | `chwd` (picks and installs the right GPU drivers for your machine) `power-profiles-daemon` `usbutils` `smartmontools` `nvme-cli` `hdparm` `ethtool` `dmidecode` `hwinfo` | power-profiles-daemon |
| Network | `iwd` (Wi-Fi) with systemd-networkd and systemd-resolved, `ufw` (firewall: incoming blocked, outgoing allowed), `openssh` `inetutils` `bind` (dig) `modemmanager` `usb_modeswitch` (mobile data modems) | ufw, networkd, resolved, timesyncd, iwd |
| Audio | `pipewire` `pipewire-audio` `pipewire-alsa` `pipewire-pulse` `pipewire-jack` `wireplumber` `rtkit` `sof-firmware` `alsa-firmware` `alsa-utils` | |
| Filesystems | `btrfs-progs` `dosfstools` `exfatprogs` `ntfs-3g` `xfsprogs` `f2fs-tools` `jfsutils` `nilfs-utils` `mtools` `lvm2` `mdadm` `dmraid` `fsarchiver` | |
| Command-line tools | `nano` `vim` `cachyos-micro-settings` `unzip` `zip` `7zip` `wget` `rsync` `ripgrep` `plocate` `pkgfile` (tells you which package has a missing command) `duf` `pv` `btop` `fastfetch` `tealdeer` (`tldr`: short command examples) | pkgfile list update |
| Boot and snapshots | `limine` `limine-mkinitcpio-hook` `limine-snapper-sync` `snapper` `snap-pac` (a btrfs snapshot before and after every update; boot any of them from the Limine menu) | old snapshot cleanup |
| Maintenance | `pacman-contrib` (paccache, checkupdates, pactree) | old package cache cleanup |
| Oblio | `oblio-hooks` (Oblio's name in os-release, reboot-required notices), `oblio-settings` (system configuration, the fish prompt and welcome, the `oblio-desktop` and `oblio-snapshot` commands) | |

Optional, picked in the installer (all on by default):

| Component | Packages |
|---|---|
| Bluetooth | `bluez` `bluez-utils` |
| Printing | `cups` `ipp-usb` `avahi` `nss-mdns` |
| Firmware updates | `fwupd` |
| Game controllers | `steam-devices` |
| Drawing tablets | `libwacom` |
| Development tools | `base-devel` `git` `paru` `rebuild-detector` (needed for the AUR) |

**Dual boot with Windows:** Windows keeps the computer's hardware clock in local time, Linux keeps
it in UTC, so after switching from one to the other the clock is off by your time zone's offset.
Fix it once, on the Windows side: open a terminal as administrator and run

```
reg add "HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /d 1 /t REG_DWORD /f
```

then restart Windows and let it sync the time (Settings, Time & language, Sync now). If Windows sits
on another drive and doesn't show up in Oblio's boot menu, run `sudo limine-scan` once in Oblio.

The installer also runs from a plain Arch ISO, building Oblio's packages on the fly:

```
curl -L https://github.com/tudorblank/oblio/archive/refs/heads/main.tar.gz | tar xz
oblio-main/tools/installer/oblio-install
```

## Part 2: the Oblio desktop

On the installed system, as your user:

```
oblio-desktop
reboot
```

`oblio-desktop` is part of every Oblio install. It shows which desktop sessions you already have,
asks before changing anything, then downloads the desktop from this repository and sets it up; run
it again later to update. After the reboot you get Oblio's login screen: pick the user and the session at the bottom
left (Hyprland, or anything else installed) and log in. If another login manager is already set up
(SDDM, GDM...), it's left alone unless you run `oblio-desktop --greeter`.

What it provides:

| | Packages |
|---|---|
| Compositor | `hyprland` with Oblio's config (Lua modules in `~/.config/hypr/modules/`) |
| Shell | `quickshell` running Oblio's dock and settings panel |
| Login screen | `greetd` with Oblio's greeter (session picker, remembers your choice) |
| Apps | `alacritty` (terminal), `dolphin` (files), `zen-browser-bin` (browser), `hyprlauncher` (app launcher) |
| Desktop plumbing | `hyprpolkitagent` (password prompts), `xdg-desktop-portal-hyprland` (screen sharing, file pickers), `xdg-utils` (opening links and files), `fuse2` (AppImages), `qt6-wayland`, `archlinux-xdg-menu`, `xorg-xhost` |
| Tools | `grim` `slurp` `wl-clipboard` (screenshots), `hyprpicker` (color picker), `brightnessctl` `playerctl` (brightness and media keys) |
| Look | `breeze-icons`, `capitaine-cursors`, `inter-font`, `ttf-dejavu`, `ttf-nerd-fonts-symbols` |

On another Arch-based system, the same desktop installs with:

```
curl -L https://github.com/tudorblank/oblio/archive/refs/heads/main.tar.gz | tar xz
oblio-main/desktop/setup
```

### Using it

In a VM the main key is Alt instead of Super.

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

Dock: click opens an app; on a running app it focuses its window if it isn't focused, minimizes it
if it is, and brings minimized windows back (to their workspace, place and size, focused); middle
click opens a new window; right click opens a menu: the app's windows, New window, Pin to dock /
Unpin from dock, Quit. The dock never moves the pointer. It can always show, auto-hide (the bottom
edge brings it back) or hide smartly (only while a window reaches into it), and it disappears when
it has nothing to show (SUPER+I, Dock).

A floating window comes to the front when it gets focus. Floating windows always stay above tiled
ones; for normal desktop stacking, switch the workspace to floating with SUPER+T.

Hyprland's config: `hyprland.lua` loads `modules/` (monitors, env, input, layout, decorations,
animations, misc, windowrules, windows, binds, autostart); what you change in the settings panel is
saved to `settings.lua` next to it and wins over the modules.

## Working on Oblio

```
base/         what an installed Oblio is made of
  config/       components/ (one file per component: packages + services; optional ones show up
                in the installer), pacman.conf (Cachy repos filled in per CPU), btrfs.conf, limine.conf
  packages/     Oblio's own packages: oblio-hooks, oblio-settings
desktop/      the Oblio desktop: setup, config/ (lands in ~/.config: hypr/, quickshell/), greeter/
tools/        installing and tooling
  installer/    oblio-install (the step-by-step installer), engine.sh (install steps), oblio-repos (CPU detection)
  build-packages, oblio-vm (test VM)
iso/          the Oblio ISO: build-iso, and what it adds on top of Arch's live ISO
```

Build the ISO (it carries the base only; the desktop always comes from this repository):

```
sudo pacman -S archiso
iso/build-iso
```

Test in a VM:

```
sudo pacman -S qemu-desktop edk2-ovmf
tools/oblio-vm install   # boots the newest ISO from out/
tools/oblio-vm run       # boots the installed system
tools/oblio-vm reset     # wipes the VM disk
```

Live desktop editing: `git clone` this repository and run `desktop/setup --link`. Everything in
`desktop/config/` is then symlinked into `~/.config`, so edits in the repo apply right away.
