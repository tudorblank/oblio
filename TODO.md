# Oblio TODO

## Next: the desktop

- [ ] Shell: top bar (workspaces, clock, tray, battery, volume, brightness, Wi-Fi via iwd, Bluetooth)
- [ ] Notifications (Quickshell server) and an on-screen display for volume/brightness
- [ ] Daily update check with a notification (needs notifications)
- [ ] Idle and lid: lock, screen off, suspend
- [ ] Lock screen in the same style as the login screen
- [ ] Power menu (lock, log out, suspend, reboot, power off); SUPER+M exits straight away now
- [ ] Launcher (Quickshell) to replace hyprlauncher
- [ ] Keybind cheatsheet inside the desktop
- [ ] Wallpaper
- [ ] Clipboard history
- [ ] Animations and look, using `hypr-config-temp` as inspiration
- [ ] Greeter redesign (own theme, 100% scale like the desktop; leave alone until then)
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
- [x] Hyprland: window management (minimize, show desktop, tiling/floating per workspace)
- [x] NVIDIA on hybrid laptops: NVIDIA's GLX/VA-API variables only when NVIDIA is the only GPU
- [x] Dock: pinning, right-click menu, drag to rearrange and pin, window counts
- [x] Settings panel (SUPER+I): display, dock, windows, appearance, input
- [x] Display settings: resolution, refresh rate, scale, rotation, arrangement, mirroring, keep-or-go-back
- [x] Theme: light/dark, accent, fonts (SF Pro, JetBrains Mono) for the shell, GTK 3/4, Qt, browsers,
      icons (WhiteSur), terminal, Hyprland
- [x] Thunar instead of Dolphin, styled like GNOME Files; USB drives mount when plugged in
- [x] Login screen: greetd + Quickshell greeter, session picker, remembers user and session
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
