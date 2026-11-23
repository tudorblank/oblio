# Oblio's greeting: a welcome on the first console login after installing, nothing ever after.
# Your own ~/.config/fish/functions/fish_greeting.fish replaces it.
function fish_greeting
    # only on the text console of a fresh install, never in a desktop terminal
    string match -qr '^/dev/tty[0-9]+$' (tty); or return
    set -l seen (set -q XDG_STATE_HOME; and echo $XDG_STATE_HOME; or echo ~/.local/state)/oblio-welcome
    test -e $seen; and return
    mkdir -p (path dirname $seen); and touch $seen
    echo
    set_color --bold red; echo "  Hey! Thank you for installing Oblio."; set_color normal
    echo
    echo "  Type "(set_color --bold)"ls"(set_color normal)" to see your home folder."
    echo "  To install the official Oblio desktop, type "(set_color --bold)"oblio-desktop"(set_color normal)"."
    echo
end
