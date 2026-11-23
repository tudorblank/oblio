# Oblio TODO

## Next

- [ ] Build the Oblio ISO and run a full install in the VM (`iso/build-iso`, `tools/oblio-vm install`)
  - [ ] Erase mode, no encryption
  - [ ] Encryption: passphrase prompt at boot, snapshot entries still boot
  - [ ] Manual mode with a shared EFI partition
  - [ ] Kernel choice: main kernel boots first, LTS second
- [x] Minimal Hyprland (`desktop/setup`)
- [x] Window management: minimize, show desktop, tiling/floating per workspace (`hypr/modules/windows.lua`)
- [x] Dock (`desktop/oblio-shell`, Quickshell)
- [x] Settings panel (SUPER+I): display, dock, windows, appearance, input
- [x] Display settings: resolution, refresh rate, scale, rotation, arrangement, mirroring; keep-or-go-back
  confirmation; 100% by default, the scale that suits the screen's size marked as recommended
- [ ] NVIDIA on hybrid laptops: `env.lua` (and the greeter) set NVIDIA's GLX/VA-API variables whenever the
  driver is loaded, so the dGPU never sleeps; only set them when NVIDIA drives the display
- [ ] Shell: top bar (workspaces, clock, tray, battery, volume, brightness, Wi-Fi via iwd, Bluetooth)
- [ ] Notifications (Quickshell server) and an on-screen display for volume/brightness
- [ ] Idle and lid: lock, screen off, suspend
- [x] Theme: light/dark, accent, fonts (SF Pro, JetBrains Mono) for the shell, GTK 3/4, browsers, icons,
      terminal, Hyprland; Settings > Appearance
- [x] WhiteSur icons (pinned download), Thunar restyled like GNOME Files (per-app stylesheets)
- [x] Qt apps follow the theme (QT_QPA_PLATFORMTHEME=gtk3: light/dark, accent, fonts, live)
- [ ] Thunar light mode: the home icon in the path field is faint
- [x] Updates: [oblio] pacman repo (signed, built by GitHub Actions), oblio-update, desktop version tracking
- [ ] Daily update check with a notification (needs notifications)
- [ ] Wallpaper
- [ ] Greeter redesign (own theme; leave alone until then)
- [ ] Power menu (lock, log out, suspend, reboot, power off); SUPER+M exits straight away now
- [ ] Keybind cheatsheet inside the desktop
- [ ] Launcher (Quickshell) to replace hyprlauncher
- [x] Thunar instead of Dolphin (no KDE frameworks); USB drives mount when plugged in (thunar-volman)
- [ ] Clipboard history
- [ ] Greeter: 100% like the desktop (it uses Hyprland's "auto")
- [x] Dock: right-click menu (windows, new window, pin to dock, quit), pinning from the dock
- [ ] Animations and look, using `hypr-config-temp` as inspiration
- [x] Two-part install: the ISO installs the base, `oblio-desktop` installs the desktop from GitHub
- [x] Home folders on a fresh install (xdg-user-dirs: Desktop, Documents, Downloads, Music, Pictures, Public, Videos)
- [x] Login screen: greetd + Quickshell greeter, session picker, remembers user and session
- [ ] Lock screen in the same style as the login screen
- [ ] Build the ISO yourself and write it to a USB stick (documented, tested)
- [ ] Make Hyprland an installer component once it settles

## Done

- [x] System config: `oblio-settings`, `config/`
- [x] Drivers: `chwd -a` at install, audio, Bluetooth, printing, firmware updates, controllers, tablets
- [x] Installer: step by step, terminal only (`tools/installer/oblio-install`)
- [x] Oblio ISO: Arch's live ISO + installer + prebuilt Oblio packages (`iso/build-iso`)

## Later

- [ ] Go through the CachyOS install on this PC: pick packages worth adding to the base

- [ ] `limine-scan` after first boot on machines that dual-boot Windows from another disk

## Optional improvements

- [ ] `oblio-settings`: overrides layered on top of `cachyos-settings` instead of forking it. First one: journal limit 50 MB → ~300 MB
- [ ] `scx-scheds`: sched-ext CPU schedulers, switchable without rebooting
- [ ] Try `linux-cachyos-bore` next to the default kernel, compare in Limine
- [ ] BBRv3 TCP congestion control (built into the kernel, off by default)
- [ ] `ufw` firewall
- [ ] A/B test `ananicy-cpp` on vs off for games (reports from June 2026 suggest it can cause stutter)
- [ ] Printer driver packs for old printers: `gutenprint`, `hplip`; scanning: `sane-airscan`
- [ ] Xbox wireless: `xpadneo-dkms` (Bluetooth), `xone-dkms` (USB dongle). DKMS = kernel headers + rebuild on every kernel update
- [ ] `opentabletdriver` for tablets the kernel doesn't support (needs .NET)
- [ ] `fwupd-refresh.timer` for automatic firmware metadata refresh

## Current machine (CachyOS install)

- [ ] Refresh the outdated chwd Nvidia profile (still loads Nvidia in the initramfs)
- [ ] Merge `/etc/pacman.conf.pacnew` and `/etc/resolv.conf.pacnew`
- [ ] BIOS: Fast Boot, CSM off (firmware takes 9.2 s of the 18 s boot)

## Assets

- [ ] Decide what Oblio's assets are, then wire them in (os-release LOGO, login screen)
