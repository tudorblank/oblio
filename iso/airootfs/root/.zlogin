# fix for screen readers
if grep -Fqa 'accessibility=' /proc/cmdline &> /dev/null; then
    setopt SINGLE_LINE_ZLE
fi

~/.automated_script.sh

# start the installer once, on the first console
if [[ $(tty) == /dev/tty1 && ! -e /tmp/oblio-installer-started ]]; then
    touch /tmp/oblio-installer-started
    oblio-install
fi
