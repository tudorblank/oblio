# Oblio TODO

## Next

- [x] System config
  - [x] mkinitcpio hooks: no plymouth, `sd-btrfs-overlayfs` for booting snapshots (`oblio-settings`)
  - [x] Limine: kernel cmdline (`oblio-settings`), menu timeout and branding (`system/limine.conf`)
  - [x] btrfs subvolume layout, including `@docker` (`system/btrfs.conf`)
  - [x] snapper template: manual snapshots only, no timeline, no quotas (`oblio-settings`)
  - [x] `oblio-snapshot` command (`oblio-settings`)
  - [x] networkd wired + wireless `.network` files (`oblio-settings`)
  - [x] locale, timezone, keymap, hostname (`hosts/desktop.conf`)
- [ ] Installer
  - [ ] Partition, create subvolumes and mount from `system/btrfs.conf`, `genfstab`
  - [ ] Install Cachy's `pacman` before switching to `Architecture = auto` (Arch's pacman only knows `x86_64`)
  - [ ] Write `/etc/pacman.conf` with `scripts/oblio-repos conf`, add `scripts/oblio-repos packages`
  - [ ] Build and install `packages/oblio-hooks` and `packages/oblio-settings`
  - [ ] Apply `hosts/<name>.conf`: hostname, timezone, locales (`LC_FORMATS` → all `LC_*` except messages), `/etc/vconsole.conf`
  - [ ] `/etc/default/limine`: `KERNEL_CMDLINE[default]+=root=UUID=… rw rootflags=subvol=/@` (the drop-in uses `+=`, which ignores `/etc/kernel/cmdline`)
  - [ ] Write `system/limine.conf` to the ESP before the first `limine-update`, check the entry tool keeps it
  - [ ] `limine-scan` once to add Windows Boot Manager
  - [ ] `snapper -c root create-config -t oblio /`
  - [ ] `/etc/nsswitch.conf` hosts: `mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns`
  - [ ] Replace `/etc/resolv.conf` with a symlink to `/run/systemd/resolve/stub-resolv.conf` (from outside the chroot)
  - [ ] `arch-update` from the AUR with paru
  - [ ] Enable/disable units from `services.txt` (USER section with `systemctl --global enable`)
  - [ ] Run `chwd -a`
- [x] Drivers and graphics
  - [x] GPU, Wi-Fi, laptop power, handhelds: `chwd -a` at install (scans every PCI and USB device)
  - [x] Audio (PipeWire) and Bluetooth
  - [x] Printing (CUPS, driverless network + USB printers), firmware updates (fwupd), controllers, tablets
- [ ] Minimal Hyprland

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
