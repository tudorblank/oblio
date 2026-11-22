# Oblio TODO

## Next

- [ ] System config (`system/`)
  - [ ] mkinitcpio hooks (no plymouth)
  - [ ] Limine: kernel cmdline (`quiet nowatchdog`, no `splash`), menu timeout
  - [ ] btrfs subvolume layout, including `@docker`
  - [ ] snapper config for `/`
  - [ ] networkd `.network` files, `/etc/resolv.conf` → systemd-resolved stub
  - [ ] locale, timezone, keymap
- [ ] Installer
  - [ ] Install Cachy's `pacman` before switching to `Architecture = auto` (Arch's pacman only knows `x86_64`)
  - [ ] Write `/etc/pacman.conf` with `scripts/oblio-repos conf`, add `scripts/oblio-repos packages`
  - [ ] Build and install `packages/oblio-hooks`
  - [ ] `arch-update` from the AUR with paru
  - [ ] Enable/disable units from `services.txt` (USER section with `systemctl --global enable`)
  - [ ] Run `chwd -a`
- [ ] Drivers and graphics
- [ ] Minimal Hyprland

## Optional improvements

- [ ] `oblio-settings`: overrides layered on top of `cachyos-settings` instead of forking it. First one: journal limit 50 MB → ~300 MB
- [ ] `scx-scheds`: sched-ext CPU schedulers, switchable without rebooting
- [ ] Try `linux-cachyos-bore` next to the default kernel, compare in Limine
- [ ] BBRv3 TCP congestion control (built into the kernel, off by default)
- [ ] `ufw` firewall
- [ ] `sof-firmware` (audio firmware for many laptops)

## Current machine (CachyOS install)

- [ ] Refresh the outdated chwd Nvidia profile (still loads Nvidia in the initramfs)
- [ ] Merge `/etc/pacman.conf.pacnew` and `/etc/resolv.conf.pacnew`
- [ ] BIOS: Fast Boot, CSM off (firmware takes 9.2 s of the 18 s boot)

## Branding

- [ ] Light version of the wordmark for dark backgrounds
