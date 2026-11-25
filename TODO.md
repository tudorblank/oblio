# Oblio TODO

## Next: the desktop

- [ ] Make the shell stable and usable (current round), then an app launcher of Oblio's own
      (rofi for now), then Oblio's own glass blur on the GPU (refraction, shapes), replacing
      Hyprland's in `edges/Surface.qml`
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
- [ ] Thunar light mode: the home icon in the path field is faint
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
- [x] Desktop-space engine (`edges/`): bar and dock as edge panels with space, shape, material and
      showing in one place; Settings > Bar / Dock
- [x] Bar on any edge (widgets lay out vertically on a side bar); right-click menu; network (iwd),
      Bluetooth, notifications (server, cards, list, Do Not Disturb), apps in the volume popup;
      rofi as the app launcher (themed by apply-theme); Bluetooth in the base for every install
- [x] Bar: widgets in three sections edited in Settings (add, drag, options), scattered islands,
      roundness; look = material (solid/blur) + tint color + opacity
- [x] Shell menus block keybinds and clicks to windows (Hyprland submap), SUPER+Q closes them
- [x] Dock: pinning, right-click menu, drag to rearrange and pin, one dot per window, any side edge,
      icons at the start, center or end of a full or fixed-length dock, live window previews on hover
- [x] Settings panel (SUPER+I): display, bar, dock, windows, appearance, input; drag to move,
      resize from any edge, one dropdown open at a time
- [x] Display settings: resolution, refresh rate, scale, rotation, arrangement, mirroring, keep-or-go-back
- [x] Theme: light/dark, accent, fonts (SF Pro, JetBrains Mono) for the shell, GTK 3/4, Qt, browsers,
      icons (WhiteSur), terminal, Hyprland
- [x] Thunar instead of Dolphin, styled like GNOME Files (oblio-gtk-module for its sidebar indent); USB
      drives mount when plugged in
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
