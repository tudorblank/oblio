# SPDX-License-Identifier: GPL-3.0-or-later
#
# Oblio install steps. Sourced by oblio-install, which sets:
#   OBLIO_ROOT                      the Oblio source tree (base/, tools/installer/)
#   KEYMAP LOCALE FORMATS TIMEZONE  console keymap, language, formats, timezone
#   HOST_NAME USERNAME USER_PASS    machine name, user
#   ROOT_MODE ROOT_PASS             root: same | separate | locked
#   DISK DISK_MODE                  disk; erase | manual
#   ESP_PART ESP_FORMAT ROOT_PART   manual mode: partitions, format the ESP (yes|no)
#   ENCRYPT LUKS_PASS               yes | no
#   KERNEL LTS                      main kernel; LTS fallback yes | no
#   COMPONENTS                      array of component file names

mnt=/mnt
cachyos_key=F3B607488DB35A47
log=/tmp/oblio-install.log
live_conf=/tmp/oblio-pacman.conf
live_mirrors=/tmp/oblio-pacman.d
iso_repo=/usr/share/oblio/repo
luks_name=oblio

step="starting"
msg()  { step="$*"; printf '\e[1;31m==>\e[0m \e[1m%s\e[0m\n' "$*"; }
warn() { printf '\e[1;33mwarning:\e[0m %s\n' "$*" >&2; }
die()  { printf '\e[1;31merror:\e[0m %s\n' "$*" >&2; exit 1; }

chroot_do() { arch-chroot "$mnt" "$@"; }
as_user()   { arch-chroot "$mnt" runuser -u "$USERNAME" -- env HOME="/home/$USERNAME" USER="$USERNAME" bash -c "$1"; }

# partition N of a disk: /dev/vda -> /dev/vda1, /dev/nvme0n1 -> /dev/nvme0n1p1
part() {
    if [[ $1 == *[0-9] ]]; then echo "${1}p$2"; else echo "${1}$2"; fi
}

# one value per line from an array field of a component file
component_field() {
    (
        declare -a PACKAGES=() SERVICES=() USER_SERVICES=() DISABLE_SERVICES=()
        # shellcheck disable=SC1090
        source "$1"
        declare -n field="$2"
        printf '%s\n' "${field[@]}"
    ) | grep -v '^$' || true
}

# a field across all selected components
collect() {
    local c
    for c in "${COMPONENTS[@]}"; do
        component_field "$OBLIO_ROOT/base/config/components/$c" "$1"
    done
}

kernel_packages() {
    echo "$KERNEL"
    if [[ $LTS == yes ]]; then echo linux-cachyos-lts; fi
}

# Oblio's own packages come prebuilt on the Oblio ISO; on a plain Arch ISO they are built here
have_iso_repo() { [[ -f $iso_repo/oblio.db ]]; }
local_packages=(oblio-hooks oblio-settings arch-update)

root_device() {
    if [[ $ENCRYPT == yes ]]; then echo "/dev/mapper/$luks_name"; else echo "$ROOT_PART"; fi
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

    level="$("$OBLIO_ROOT/tools/installer/oblio-repos" level)"
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

    "$OBLIO_ROOT/tools/installer/oblio-repos" conf "$level" |
        sed -e "s|^Architecture = auto$|Architecture = $archs|" \
            -e "s|/etc/pacman.d/cachyos|$live_mirrors/cachyos|" > "$live_conf"

    if have_iso_repo; then
        # first repo, so Oblio's packages win
        awk -v repo="$iso_repo" '
            !done && /^\[/ && $0 != "[options]" {
                print "[oblio]"; print "SigLevel = Optional TrustAll"; print "Server = file://" repo; print ""
                done = 1
            }
            { print }' "$live_conf" > "$live_conf.new"
        mv "$live_conf.new" "$live_conf"
    fi
    pacman-conf --config "$live_conf" --repo-list >/dev/null
}

partition() {
    umount -R "$mnt" 2>/dev/null || true
    cryptsetup close "$luks_name" 2>/dev/null || true

    if [[ $DISK_MODE == erase ]]; then
        msg "Partitioning $DISK"
        wipefs -af "$DISK"
        sgdisk --zap-all "$DISK"
        sgdisk -n 1:0:+2G -t 1:ef00 -c 1:EFI \
               -n 2:0:0   -t 2:8304 -c 2:Oblio "$DISK"
        partprobe "$DISK"
        udevadm settle
        ESP_PART="$(part "$DISK" 1)"
        ROOT_PART="$(part "$DISK" 2)"
        ESP_FORMAT=yes
    fi

    if [[ $ESP_FORMAT == yes ]]; then
        msg "Formatting $ESP_PART (EFI)"
        if [[ $DISK_MODE == manual ]]; then
            # mark it as an EFI system partition so firmware boots from it
            sgdisk -t "$(lsblk -no PARTN "$ESP_PART")":ef00 "$DISK"
            partprobe "$DISK"
            udevadm settle
        fi
        mkfs.fat -F 32 -n EFI "$ESP_PART"
    fi

    wipefs -af "$ROOT_PART"
    if [[ $ENCRYPT == yes ]]; then
        msg "Encrypting $ROOT_PART"
        printf '%s' "$LUKS_PASS" | cryptsetup luksFormat --type luks2 --batch-mode --key-file - "$ROOT_PART"
        # TRIM and no extra work queues: faster on SSDs, stored in the LUKS header
        printf '%s' "$LUKS_PASS" | cryptsetup open --key-file - --allow-discards \
            --perf-no_read_workqueue --perf-no_write_workqueue --persistent "$ROOT_PART" "$luks_name"
    fi

    msg "Formatting $(root_device) (btrfs)"
    mkfs.btrfs -f -L Oblio "$(root_device)"
}

mount_subvolumes() {
    msg "Creating btrfs subvolumes"
    # shellcheck source=../../base/config/btrfs.conf
    source "$OBLIO_ROOT/base/config/btrfs.conf"
    local root s
    root="$(root_device)"

    mount "$root" "$mnt"
    for s in "${SUBVOLUMES[@]}"; do
        btrfs subvolume create "$mnt/${s%%:*}"
    done
    umount "$mnt"

    for s in "${SUBVOLUMES[@]}"; do
        mount --mkdir -o "$MOUNT_OPTIONS,subvol=/${s%%:*}" "$root" "$mnt${s#*:}"
    done
    mount --mkdir -o fmask=0077,dmask=0077 "$ESP_PART" "$mnt/boot"
}

install_base() {
    msg "Installing the base system"
    # oblio-hooks first: Limine's entry tool names the boot entry after os-release
    # when the first kernel is installed, so the branding has to be in place by then
    local -a extra=(oblio-hooks)
    # without the ISO's repo, Oblio's packages are built here, which needs the build tools
    have_iso_repo || extra=(base-devel git)
    # shellcheck disable=SC2046
    pacstrap -C "$live_conf" "$mnt" base fish sudo cachyos-keyring cachyos-mirrorlist \
        $("$OBLIO_ROOT/tools/installer/oblio-repos" packages "$level") "${extra[@]}"

    "$OBLIO_ROOT/tools/installer/oblio-repos" conf "$level" > "$mnt/etc/pacman.conf"

    # subvolid= would point at the old subvolume after a snapshot restore
    genfstab -U "$mnt" | sed -E 's/,?subvolid=[0-9]+//' >> "$mnt/etc/fstab"
}

configure_host() {
    msg "Configuring locale, time and hostname"
    ln -sf "/usr/share/zoneinfo/$TIMEZONE" "$mnt/etc/localtime"
    chroot_do hwclock --systohc

    local l v
    for l in $(printf '%s\n' "$LOCALE" "$FORMATS" | sort -u); do
        sed -i "s/^#${l//./\\.} /${l} /" "$mnt/etc/locale.gen"
    done
    chroot_do locale-gen

    {
        echo "LANG=$LOCALE"
        if [[ $FORMATS != "$LOCALE" ]]; then
            for v in LC_ADDRESS LC_IDENTIFICATION LC_MEASUREMENT LC_MONETARY LC_NAME \
                     LC_NUMERIC LC_PAPER LC_TELEPHONE LC_TIME; do
                echo "$v=$FORMATS"
            done
        fi
    } > "$mnt/etc/locale.conf"

    echo "KEYMAP=$KEYMAP" > "$mnt/etc/vconsole.conf"
    echo "$HOST_NAME" > "$mnt/etc/hostname"

    sed -i 's/^hosts:.*/hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns/' \
        "$mnt/etc/nsswitch.conf"
}

kernel_cmdline() {
    if [[ $ENCRYPT == yes ]]; then
        echo "rd.luks.name=$(blkid -s UUID -o value "$ROOT_PART")=$luks_name root=/dev/mapper/$luks_name rw rootflags=subvol=/@"
    else
        echo "root=UUID=$(blkid -s UUID -o value "$ROOT_PART") rw rootflags=subvol=/@"
    fi
}

configure_boot() {
    msg "Configuring Limine"
    # must exist before the first kernel is installed: the drop-in uses +=,
    # which ignores /etc/kernel/cmdline and /proc/cmdline
    cat > "$mnt/etc/default/limine" <<EOF
ESP_PATH="/boot"
KERNEL_CMDLINE[default]+=$(kernel_cmdline)
EOF
    install -m644 "$OBLIO_ROOT/base/config/limine.conf" "$mnt/boot/limine.conf"

    if [[ $ENCRYPT == yes ]]; then
        # unlock right after block devices are up, before filesystems are mounted
        mkdir -p "$mnt/etc/mkinitcpio.conf.d"
        cat > "$mnt/etc/mkinitcpio.conf.d/06-oblio-encrypt.conf" <<'EOF'
HOOKS=($(for h in "${HOOKS[@]}"; do echo "$h"; [[ $h == block ]] && echo sd-encrypt; done))
EOF
    fi
}

create_user() {
    msg "Creating user $USERNAME"
    chroot_do useradd -m -G wheel -s /usr/bin/fish "$USERNAME"
    printf '%s:%s\n' "$USERNAME" "$USER_PASS" | chroot_do chpasswd

    case "$ROOT_MODE" in
        same)     printf 'root:%s\n' "$USER_PASS" | chroot_do chpasswd ;;
        separate) printf 'root:%s\n' "$ROOT_PASS" | chroot_do chpasswd ;;
        locked)   chroot_do passwd -l root >/dev/null ;;
    esac

    echo '%wheel ALL=(ALL:ALL) ALL' > "$mnt/etc/sudoers.d/10-wheel"
    chmod 440 "$mnt/etc/sudoers.d/10-wheel"
    chroot_do visudo -cq
}

install_packages() {
    msg "Installing packages"
    local -a pkgs
    mapfile -t pkgs < <({ collect PACKAGES; kernel_packages; } | sort -u)
    if ! have_iso_repo; then
        mapfile -t pkgs < <(printf '%s\n' "${pkgs[@]}" | grep -vxF -f <(printf '%s\n' "${local_packages[@]}"))
    fi
    # before the kernels, for the same reason as oblio-hooks in install_base
    have_iso_repo || build_local_packages

    pacstrap -C "$live_conf" "$mnt" "${pkgs[@]}"

    if ! have_iso_repo; then
        build_arch_update
        if [[ " ${COMPONENTS[*]} " != *" devtools.conf "* ]]; then
            # only needed for the builds above; the cleanup step removes them
            chroot_do pacman -D --asdeps base-devel git >/dev/null
        fi
    fi
}

build_local_packages() {
    msg "Building Oblio packages"
    local src="/home/$USERNAME/oblio-packages" p
    rm -rf "$mnt$src"
    cp -a "$OBLIO_ROOT/base/packages" "$mnt$src"
    chroot_do chown -R "$USERNAME:$USERNAME" "$src"

    for p in oblio-hooks oblio-settings; do
        as_user "cd ~/oblio-packages/$p && makepkg -f --noconfirm --nodeps"
    done
    local -a built=("$mnt$src"/*/*.pkg.tar.zst)
    chroot_do pacman -U --noconfirm "${built[@]#"$mnt"}"
    rm -rf "$mnt$src"
}

build_arch_update() {
    msg "Building arch-update from the AUR"
    local dir="/home/$USERNAME/.cache/arch-update"
    rm -rf "$mnt$dir"
    as_user "git clone --depth 1 https://aur.archlinux.org/arch-update.git ~/.cache/arch-update"

    # runtime + build dependencies; the test suite (and its checkdepends) is skipped
    local -a deps
    mapfile -t deps < <(as_user "cd ~/.cache/arch-update && makepkg --printsrcinfo" |
        awk -F' = ' '/^\t(make)?depends = / {print $2}' | sed 's/[<>=].*//')
    chroot_do pacman -S --needed --noconfirm --asdeps "${deps[@]}"
    as_user "cd ~/.cache/arch-update && CARGO_HOME=\$PWD/cargo makepkg -f --noconfirm --nocheck"

    local -a built=("$mnt$dir"/*.pkg.tar.zst)
    chroot_do pacman -U --noconfirm "${built[@]#"$mnt"}"
    rm -rf "$mnt$dir"
}

enable_services() {
    msg "Enabling services"
    local -a units
    mapfile -t units < <(collect SERVICES)
    if (( ${#units[@]} )); then systemctl --root="$mnt" enable "${units[@]}"; fi
    mapfile -t units < <(collect USER_SERVICES)
    if (( ${#units[@]} )); then systemctl --root="$mnt" --global enable "${units[@]}"; fi
    mapfile -t units < <(collect DISABLE_SERVICES)
    if (( ${#units[@]} )); then systemctl --root="$mnt" disable "${units[@]}"; fi
}

cleanup() {
    msg "Cleaning up"
    # only lines that look like package names reach pacman
    local -a orphans
    mapfile -t orphans < <(chroot_do pacman -Qdtq | grep -E '^[a-zA-Z0-9@._+-]+$' || true)
    if (( ${#orphans[@]} )); then chroot_do pacman -Rns --noconfirm "${orphans[@]}"; fi

    # everything downloaded during install; a fresh system has nothing to roll back to
    chroot_do paccache -rk0
    chroot_do paccache -ruk0

    # build leftovers, when Oblio's packages were built during install
    rm -rf "$mnt/home/$USERNAME/oblio/packages"/*/{src,pkg}
    rm -f "$mnt/home/$USERNAME/oblio/packages"/*/*.pkg.tar.zst

    # paru: delete untracked build files after each AUR install
    if [[ -f $mnt/etc/paru.conf ]]; then
        sed -i 's/^#CleanAfter$/CleanAfter/' "$mnt/etc/paru.conf"
    fi
}

finish() {
    msg "Configuring snapshots"
    chroot_do snapper --no-dbus -c root create-config -t oblio /

    msg "Detecting hardware (chwd)"
    # chwd rebuilds the initramfs with `mkinitcpio -P`, and limine-mkinitcpio-hook's
    # wrapper asks "run limine-mkinitcpio now? [Y/n]" on stdin; no stdin = its default, yes
    chroot_do chwd -a < /dev/null

    enable_services

    msg "Installing Limine"
    chroot_do limine-install
    chroot_do limine-update

    # tidying up is optional: a problem here must not stop a bootable install
    cleanup || warn "cleanup did not finish, the system is installed anyway (see the log)"

    # last: arch-chroot bind-mounts the live resolv.conf while chrooted
    ln -sf ../run/systemd/resolve/stub-resolv.conf "$mnt/etc/resolv.conf"

    install -Dm644 "$log" "$mnt/var/log/oblio-install.log"
    umount -R "$mnt"
    if [[ $ENCRYPT == yes ]]; then cryptsetup close "$luks_name"; fi
}

run_install() {
    prepare_live
    partition
    mount_subvolumes
    install_base
    configure_host
    configure_boot
    create_user
    install_packages
    finish
}
