#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Oblio installer. Run as root from the Arch Linux ISO, booted in UEFI mode.
#   ./install.sh --disk /dev/vda --user name [--host desktop]
# Erases the whole disk.

set -Eeuo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mnt=/mnt
cachyos_key=F3B607488DB35A47
log=/tmp/oblio-install.log
live_conf=/tmp/oblio-pacman.conf
live_mirrors=/tmp/oblio-pacman.d

disk=""
user=""
host="desktop"

step="starting"
msg()  { step="$*"; printf '\e[1;31m==>\e[0m \e[1m%s\e[0m\n' "$*"; }
die()  { printf '\e[1;31merror:\e[0m %s\n' "$*" >&2; exit 1; }

usage() {
    echo "usage: ${0##*/} --disk <device> --user <name> [--host <profile>]" >&2
    echo "profiles: $(cd "$repo/hosts" && ls -- *.conf | sed 's/\.conf$//' | tr '\n' ' ')" >&2
    exit 1
}

# package / unit names from a list file, comments stripped
list() {
    sed 's/#.*//' "$1" | tr -s ' \t' '\n' | grep -v '^$' || true
}

# names under one "# SECTION:" header
section() {
    awk -v s="# $2:" '$0 == s {f=1; next} /^# [A-Z]+:/ {f=0} f' "$1" |
        sed 's/#.*//' | tr -s ' \t' '\n' | grep -v '^$' || true
}

# partition N of the disk: /dev/vda -> /dev/vda1, /dev/nvme0n1 -> /dev/nvme0n1p1
part() {
    if [[ $disk == *[0-9] ]]; then echo "${disk}p$1"; else echo "${disk}$1"; fi
}

chroot_do() { arch-chroot "$mnt" "$@"; }
as_user()   { arch-chroot "$mnt" runuser -u "$user" -- env HOME="/home/$user" USER="$user" bash -c "$1"; }

# prompts go to stderr, only the password reaches stdout
ask_password() {
    local who="$1" a b
    while true; do
        read -rsp "Password for $who: " a; echo >&2
        read -rsp "Repeat: " b; echo >&2
        [[ -n $a && $a == "$b" ]] && break
        echo "Empty or not matching, try again." >&2
    done
    printf '%s' "$a"
}

preflight() {
    [[ $EUID == 0 ]] || die "run as root"
    [[ -d /sys/firmware/efi ]] || die "not booted in UEFI mode"
    [[ -n $disk && -n $user ]] || usage
    [[ -b $disk ]] || die "$disk is not a block device"
    [[ $user =~ ^[a-z_][a-z0-9_-]*$ ]] || die "invalid user name: $user"
    [[ -f $repo/hosts/$host.conf ]] || die "no host profile: hosts/$host.conf"
    curl -fsI --max-time 10 https://mirror.cachyos.org >/dev/null || die "no network"

    echo
    lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MODEL "$disk"
    echo
    read -rp "Everything on $disk will be erased. Type the device path to continue: " answer
    [[ $answer == "$disk" ]] || die "aborted"

    user_pw="$(ask_password "$user")"
    root_pw="$(ask_password root)"
}

prepare_live() {
    msg "Preparing the live environment"
    pacman -Sy --noconfirm archlinux-keyring
    pacman-key --recv-keys "$cachyos_key" --keyserver hkps://keyserver.ubuntu.com ||
        pacman-key --recv-keys "$cachyos_key" --keyserver hkps://keys.openpgp.org
    pacman-key --lsign-key "$cachyos_key"

    # Only the keyring and mirrorlists, which are plain data files. Cachy's pacman
    # needs newer libraries than the ISO has, so it goes into Oblio, never here.
    grep -qx '\[cachyos\]' /etc/pacman.conf ||
        printf '\n[cachyos]\nServer = https://mirror.cachyos.org/repo/$arch/$repo\n' >> /etc/pacman.conf
    pacman -Sy --noconfirm cachyos/cachyos-keyring cachyos/cachyos-mirrorlist \
        cachyos/cachyos-v3-mirrorlist cachyos/cachyos-v4-mirrorlist

    level="$("$repo/scripts/oblio-repos" level)"
    msg "CPU level: $level"
    write_live_conf
}

# pacman.conf for pacstrap, readable by the ISO's own (Arch) pacman: it knows
# neither Architecture = auto for v3/v4 nor the $arch_v3/$arch_v4 mirror variables
write_live_conf() {
    local archs f
    case "$level" in
        generic)   archs="x86_64" ;;
        v3)        archs="x86_64 x86_64_v2 x86_64_v3" ;;
        v4|znver4) archs="x86_64 x86_64_v2 x86_64_v3 x86_64_v4" ;;
    esac

    mkdir -p "$live_mirrors"
    for f in /etc/pacman.d/cachyos*-mirrorlist; do
        sed -e 's/\$arch_v3/x86_64_v3/g' -e 's/\$arch_v4/x86_64_v4/g' "$f" > "$live_mirrors/${f##*/}"
    done

    "$repo/scripts/oblio-repos" conf "$level" |
        sed -e "s|^Architecture = auto$|Architecture = $archs|" \
            -e "s|/etc/pacman.d/cachyos|$live_mirrors/cachyos|" > "$live_conf"
    pacman-conf --config "$live_conf" --repo-list >/dev/null
}

partition() {
    msg "Partitioning $disk"
    umount -R "$mnt" 2>/dev/null || true
    wipefs -af "$disk"
    sgdisk --zap-all "$disk"
    sgdisk -n 1:0:+2G -t 1:ef00 -c 1:EFI \
           -n 2:0:0   -t 2:8304 -c 2:Oblio "$disk"
    partprobe "$disk"
    udevadm settle

    esp="$(part 1)"
    root="$(part 2)"
    mkfs.fat -F 32 -n EFI "$esp"
    mkfs.btrfs -f -L Oblio "$root"
}

mount_subvolumes() {
    msg "Creating btrfs subvolumes"
    # shellcheck source=system/btrfs.conf
    source "$repo/system/btrfs.conf"

    mount "$root" "$mnt"
    local s
    for s in "${SUBVOLUMES[@]}"; do
        btrfs subvolume create "$mnt/${s%%:*}"
    done
    umount "$mnt"

    for s in "${SUBVOLUMES[@]}"; do
        mount --mkdir -o "$MOUNT_OPTIONS,subvol=/${s%%:*}" "$root" "$mnt${s#*:}"
    done
    mount --mkdir -o fmask=0077,dmask=0077 "$esp" "$mnt/boot"
}

install_base() {
    msg "Installing the base system"
    # shellcheck disable=SC2046
    pacstrap -C "$live_conf" "$mnt" base base-devel git fish \
        cachyos-keyring cachyos-mirrorlist $("$repo/scripts/oblio-repos" packages "$level")

    "$repo/scripts/oblio-repos" conf "$level" > "$mnt/etc/pacman.conf"

    # subvolid= would point at the old subvolume after a snapshot restore
    genfstab -U "$mnt" | sed -E 's/,?subvolid=[0-9]+//' >> "$mnt/etc/fstab"
}

configure_host() (
    msg "Configuring host profile: $host"
    # subshell: the profile sets LANG and HOSTNAME
    # shellcheck source=hosts/desktop.conf
    source "$repo/hosts/$host.conf"

    ln -sf "/usr/share/zoneinfo/$TIMEZONE" "$mnt/etc/localtime"
    chroot_do hwclock --systohc

    local l v
    for l in "${LOCALES[@]}"; do
        sed -i "s/^#${l//./\\.} /${l} /" "$mnt/etc/locale.gen"
    done
    chroot_do locale-gen

    {
        echo "LANG=$LANG"
        for v in LC_ADDRESS LC_IDENTIFICATION LC_MEASUREMENT LC_MONETARY LC_NAME \
                 LC_NUMERIC LC_PAPER LC_TELEPHONE LC_TIME; do
            echo "$v=$LC_FORMATS"
        done
    } > "$mnt/etc/locale.conf"

    echo "KEYMAP=$KEYMAP" > "$mnt/etc/vconsole.conf"
    echo "$HOSTNAME" > "$mnt/etc/hostname"

    sed -i 's/^hosts:.*/hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns/' \
        "$mnt/etc/nsswitch.conf"
)

configure_boot() {
    msg "Configuring Limine"
    local uuid
    uuid="$(blkid -s UUID -o value "$root")"
    # must exist before the first kernel is installed: the drop-in uses +=,
    # which ignores /etc/kernel/cmdline and /proc/cmdline
    cat > "$mnt/etc/default/limine" <<EOF
ESP_PATH="/boot"
KERNEL_CMDLINE[default]+=root=UUID=$uuid rw rootflags=subvol=/@
EOF
    install -m644 "$repo/system/limine.conf" "$mnt/boot/limine.conf"
}

create_user() {
    msg "Creating user $user"
    chroot_do useradd -m -G wheel -s /usr/bin/fish "$user"
    printf '%s:%s\n' "$user" "$user_pw" | chroot_do chpasswd
    printf 'root:%s\n' "$root_pw" | chroot_do chpasswd

    echo '%wheel ALL=(ALL:ALL) ALL' > "$mnt/etc/sudoers.d/10-wheel"
    chmod 440 "$mnt/etc/sudoers.d/10-wheel"
    chroot_do visudo -cq
}

install_oblio_packages() {
    msg "Building Oblio packages"
    local src="/home/$user/oblio"
    cp -a "$repo" "$mnt$src"
    chroot_do chown -R "$user:$user" "$src"

    local p
    for p in oblio-hooks oblio-settings; do
        as_user "cd ~/oblio/packages/$p && makepkg -f --noconfirm --nodeps"
    done

    local -a built=("$mnt$src"/packages/*/*.pkg.tar.zst)
    chroot_do pacman -U --noconfirm "${built[@]#"$mnt"}"
}

install_packages() {
    msg "Installing packages"
    local -a pkgs
    mapfile -t pkgs < <(list "$repo/pkgs.txt" | grep -vxE 'oblio-hooks|oblio-settings|arch-update')
    chroot_do pacman -S --needed --noconfirm "${pkgs[@]}"
}

install_aur() {
    msg "Building arch-update from the AUR"
    local dir="/home/$user/.cache/arch-update"
    rm -rf "$mnt$dir"
    as_user "git clone --depth 1 https://aur.archlinux.org/arch-update.git ~/.cache/arch-update"

    # runtime + build dependencies; the test suite (and its checkdepends) is skipped
    local -a deps
    mapfile -t deps < <(as_user "cd ~/.cache/arch-update && makepkg --printsrcinfo" |
        awk -F' = ' '/^\t(make)?depends = / {print $2}' | sed 's/[<>=].*//')

    local before
    before="$(chroot_do pacman -Qq | sort)"
    chroot_do pacman -S --needed --noconfirm --asdeps "${deps[@]}"
    as_user "cd ~/.cache/arch-update && CARGO_HOME=\$PWD/cargo makepkg -f --noconfirm --nocheck"

    local -a built=("$mnt$dir"/*.pkg.tar.zst)
    chroot_do pacman -U --noconfirm "${built[@]#"$mnt"}"

    # remove build-only leftovers: compare against what was installed before,
    # since names differ from what got installed (cargo is provided by rust)
    local -a leftovers
    mapfile -t leftovers < <(comm -13 <(echo "$before") <(chroot_do pacman -Qdtq | sort))
    (( ${#leftovers[@]} )) && chroot_do pacman -Rns --noconfirm "${leftovers[@]}"
    rm -rf "$mnt$dir"
}

finish() {
    msg "Configuring snapshots"
    chroot_do snapper --no-dbus -c root create-config -t oblio /

    msg "Detecting hardware (chwd)"
    chroot_do chwd -a

    msg "Enabling services"
    local -a units
    mapfile -t units < <(section "$repo/services.txt" SYSTEM)
    systemctl --root="$mnt" enable "${units[@]}"
    mapfile -t units < <(section "$repo/services.txt" USER)
    (( ${#units[@]} )) && systemctl --root="$mnt" --global enable "${units[@]}"
    mapfile -t units < <(section "$repo/services.txt" DISABLE)
    (( ${#units[@]} )) && systemctl --root="$mnt" disable "${units[@]}"

    msg "Installing Limine"
    chroot_do limine-install
    chroot_do limine-update

    # last: arch-chroot bind-mounts the live resolv.conf while chrooted
    ln -sf ../run/systemd/resolve/stub-resolv.conf "$mnt/etc/resolv.conf"

    install -Dm644 "$log" "$mnt/var/log/oblio-install.log"
    umount -R "$mnt"
}

main() {
    while (( $# )); do
        case "$1" in
            --disk) disk="${2:-}"; shift 2 ;;
            --user) user="${2:-}"; shift 2 ;;
            --host) host="${2:-}"; shift 2 ;;
            *) usage ;;
        esac
    done

    preflight
    exec > >(tee -a "$log") 2>&1
    trap 'echo; die "failed during: $step (log: $log)"' ERR

    prepare_live
    partition
    mount_subvolumes
    install_base
    configure_host
    configure_boot
    create_user
    install_oblio_packages
    install_packages
    install_aur
    finish

    msg "Oblio is installed. Remove the ISO and reboot."
    echo "On a machine that dual-boots Windows, run 'sudo limine-scan' after the first boot."
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main "$@"
fi
