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
