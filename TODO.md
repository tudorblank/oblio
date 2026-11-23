# Oblio TODO

## Next

- [ ] Build the Oblio ISO and run a full install in the VM (`tools/build-iso`, `tools/oblio-vm install`)
  - [ ] Erase mode, no encryption
  - [ ] Encryption: passphrase prompt at boot, snapshot entries still boot
  - [ ] Manual mode with a shared EFI partition
  - [ ] Kernel choice: main kernel boots first, LTS second
- [x] Minimal Hyprland (`desktop/setup`, `--link` for live editing)
- [x] Window management: minimize, show desktop, tiling/floating per workspace (`oblio.lua`)
- [x] Dock (`desktop/config/quickshell/oblio`, Quickshell)
- [ ] Shell: top bar (workspaces, clock, tray, volume, network), notifications, launcher, lock screen
- [ ] Dock: tooltips with window titles, right-click menu, pinning from the dock
- [ ] Animations and look, using `hypr-config-temp` as inspiration
- [ ] Start Hyprland automatically after login on tty1
- [ ] Make Hyprland an installer component once it settles

## Done

- [x] System config: `oblio-settings`, `config/`
- [x] Drivers: `chwd -a` at install, audio, Bluetooth, printing, firmware updates, controllers, tablets
- [x] Installer: step by step, terminal only (`installer/oblio-install`)
- [x] Oblio ISO: Arch's live ISO + installer + prebuilt Oblio packages (`tools/build-iso`)

## Later

- [ ] Host Oblio's packages in an online repo, so installed systems get `oblio-*` updates through pacman
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

## Branding

- [ ] Light version of the wordmark for dark backgrounds
