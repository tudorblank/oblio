# Oblio TODO

## Next: the desktop

- [ ] Desktop icons, a part of the shell: the Desktop folder over the wallpaper, on by default (off in
      Settings); free placement (freeform or snapped to a grid) and Arrange by; double-click opens;
      select, rename, trash, copy/paste and drag with Files and other apps; right-click menus
- [ ] Desktop icons, next: look and polish (labels readable on any wallpaper, selection, animations,
      empty states, light and dark)
- [ ] Desktop icons, untested: dragging files out of an X11 app (Xwayland, e.g. `GDK_BACKEND=x11
      nautilus`) onto the desktop; Zen running under X11; real multi-monitor (tested only with
      virtual screens); a real hand's drags (tested with a virtual pointer)
- [ ] Desktop icons: progress for big copies and moves (files just appear when done)
- [ ] Bar/dock: a screen that goes away logs a TypeError in EdgePanel.qml (screen is null while
      it's torn down)
- [ ] Desktop icons: special icons (Home, Trash, mounted drives, maybe Settings)
- [x] Search (SUPER+R): Oblio's own app search in the shell, replacing rofi
- [ ] Search: more than apps (files, settings pages, calculations, commands)
- [ ] A calendar app that syncs with the bar's clock widget (its calendar popup)
- [ ] Wi-Fi passwords reach iwctl as an argument (visible to the user's own processes for a moment);
      an iwd agent over D-Bus would avoid that
- [ ] Media widget: scrolling title, waveform style (needs cava or a PipeWire capture)
- [ ] Tray menus in Oblio's own popover (they use Qt's menu now, outside the menu keybind mode)
- [ ] On-screen display for volume and brightness keys
- [ ] Later bar widgets (need more of the system first): keyboard layout, quick toggles (caffeine,
      night light), system monitor, weather, clipboard, screenshot and color picker (with more
      desktop packages), privacy indicators, devices. No control center.
- [ ] Daily update check with a notification (the notification server is in now)
- [ ] Idle and lid: lock, screen off, suspend
- [ ] Lock screen in the same style as the login screen
- [ ] SUPER+M exits straight away; the bar's power widget asks first (lock needs a lock screen)
- [ ] Keybind cheatsheet inside the desktop
- [ ] Clipboard history
- [ ] Animations and look, using `hypr-config-temp` as inspiration
- [ ] Login screen files as an `[oblio]` package (system files, now installed by setup with sudo)
- [ ] Qt apps: progress bars and sliders take the soft selection tint (Qt uses one color for both);
      a Qt-only palette could keep them bright, at the cost of picking up accent changes only on restart

## Next: base and ISO

- [ ] Rebuild the ISO (oblio-keyring, [oblio] repo in installs, Wi-Fi step fixes) and run a full install
      in the VM (`iso/build-iso`, `tools/oblio-vm install`)
  - [ ] Erase mode, no encryption
  - [ ] Encryption: passphrase prompt at boot, snapshot entries still boot
  - [ ] Manual mode with a shared EFI partition
  - [ ] Kernel choice: main kernel boots first, LTS second
  - [ ] The installed system updates from [oblio] (`oblio-update`)
- [ ] Build the ISO yourself and write it to a USB stick (documented, tested)
- [ ] Make Hyprland an installer component once it settles

## Done

- [x] Base: system config (`oblio-settings`, `base/config`), drivers (`chwd -a`), audio, Bluetooth,
      printing, firmware updates, controllers, tablets, ufw firewall, acpi
- [x] Installer: step by step, terminal only, guided Wi-Fi; Oblio ISO with prebuilt packages
- [x] Two-part install: the ISO installs the base, `oblio-desktop` installs the desktop from GitHub
- [x] Updates: signed [oblio] pacman repository built by GitHub Actions, `oblio-update`, desktop
      version tracking
- [x] Hyprland: window management (minimize, show desktop, tiling/floating per workspace); dock clicks
      follow fixed rules (minimize only the focused window, focus goes back to the last visible one),
      windows fly into and out of their dock icon
- [x] NVIDIA on hybrid laptops: NVIDIA's GLX/VA-API variables only when NVIDIA is the only GPU
- [x] Desktop-space engine (`edges/`): bar and dock as edge panels with space, shape and showing
      in one place; Settings > Bar / Dock
- [x] Bar on any edge (widgets lay out vertically on a side bar); right-click menu; network (iwd),
      Bluetooth, notifications (server, cards, list, Do Not Disturb), apps in the volume popup;
      Bluetooth in the base for every install
- [x] Bar: widgets in three sections edited in Settings (add, drag, options), scattered islands,
      roundness
- [x] Shell menus block keybinds and clicks to windows (Hyprland submap), SUPER+Q closes them
- [x] Dock: pinning, right-click menu, drag to rearrange and pin, one dot per window, any side edge,
      icons at the start, center or end of a full or fixed-length dock, live window previews on hover
- [x] Settings panel (SUPER+I): display, bar, dock, windows, appearance, input; drag to move,
      resize from any edge, one dropdown open at a time
- [x] Display settings: resolution, refresh rate, scale, rotation, arrangement, mirroring, keep-or-go-back
- [x] Styles (Appearance): the one place for material, tint, opacity and blur strength; Default
      holds every shell part (bar, dock, menus, settings, search) until one goes to a style you
      made; apps only when added (one, or all); a target is in one style; Hyprland gets one named
      rule per target
- [x] Animations (Appearance): on or off and their speed, for Hyprland, the shell and window flights
- [x] Glass (oblio-glass, a Hyprland plugin forked from hyprglass): exact shapes from the shell,
      live styles (own blur strength and refraction per glass style), apps by tag; built by setup
- [x] Blur styles drawn by oblio-glass too (own strength and color per style; no tap cap, edges
      repeat past the screen); Hyprland's blur follows Default as the fallback, matched by measurement
- [ ] Glass optics of our own (GLASS.md section 6): squircle Snell bezel, clamped travel, tint as
      absorption, rim in the backdrop's colour, colour fringing only in motion
- [ ] Glass: rebuild automatically after a Hyprland update (today: run desktop/setup)
- [x] Theme: light/dark, accent, fonts (SF Pro, JetBrains Mono) for the shell, GTK 3/4, Qt, browsers,
      icons (WhiteSur), terminal, Hyprland
- [x] Files (Nautilus) as the file manager, in Oblio's GTK theme; Thunar and oblio-gtk-module removed
- [x] Login screen: greetd + Quickshell greeter, session picker, remembers user and session;
      redesigned like the shell (the user's lock screen wallpaper, accent and mode, one frosted card),
      later PAM prompts (one-time codes, new passwords) asked in the field
- [x] Wallpaper: Settings > Wallpaper (folder, desktop and lock screen pictures, drag and drop,
      applied on Apply); drawn by the shell
- [x] Home folders on a fresh install (xdg-user-dirs)

## Later

- [ ] `limine-scan` after first boot on machines that dual-boot Windows from another disk
- [ ] Publish Oblio's signing key on a keyserver, so pacman can look it up by itself

## Optional improvements

- [ ] `oblio-settings`: overrides layered on top of `cachyos-settings` instead of forking it. First one: journal limit 50 MB → ~300 MB
- [ ] `scx-scheds`: sched-ext CPU schedulers, switchable without rebooting
- [ ] BBRv3 TCP congestion control (built into the kernel, off by default)
- [ ] A/B test `ananicy-cpp` on vs off for games (reports from June 2026 suggest it can cause stutter)
- [ ] Printer driver packs for old printers: `gutenprint`, `hplip`; scanning: `sane-airscan`
- [ ] Xbox wireless: `xpadneo-dkms` (Bluetooth), `xone-dkms` (USB dongle). DKMS = kernel headers + rebuild on every kernel update
- [ ] `opentabletdriver` for tablets the kernel doesn't support (needs .NET)
- [ ] `fwupd-refresh.timer` for automatic firmware metadata refresh

## Assets

- [ ] Decide what Oblio's assets are, then wire them in (os-release LOGO, login screen)
