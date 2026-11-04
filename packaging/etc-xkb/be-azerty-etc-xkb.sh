#!/bin/sh
# The Belgian AZERTY options (caps:be_windows, be_azerty:accents, be_azerty:mac) for systems without a package of this
# project (NixOS, Gentoo, Slackware, Void, Solus, ...): puts the two files in /etc/xkb, which libxkbcommon (and so the
# Wayland desktops) reads before the system's own keyboard folder. Changes no file of the system. Run from a copy of
# the repository, as root:
#   sh packaging/etc-xkb/be-azerty-etc-xkb.sh install    put the two files in /etc/xkb
#   sh packaging/etc-xkb/be-azerty-etc-xkb.sh remove     take them out again (only ours)
#   sh packaging/etc-xkb/be-azerty-etc-xkb.sh status     say what is there
# Not read by an X11 session (the X server has its own folder) or the text console. Tested in containers only.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$HERE/../.." && pwd)
ETC=${ETC_XKB:-/etc/xkb}
RULES=$ETC/rules/evdev; SYMS=$ETC/symbols/be_capslock
MARK='// belgian-azerty-windows (etc-xkb):'
ours_rules() { [ -f "$RULES" ] && head -1 "$RULES" | grep -qF "$MARK"; }
ours_syms() { [ -f "$SYMS" ] && cmp -s "$SYMS" "$ROOT/xkb/symbols/be_capslock"; }
# SELinux (Fedora, openSUSE's new installs): /etc/xkb gets usr_t, the label of the system's own keyboard files, or
# confined programs such as systemd-localed cannot read our rules (localectl then refuses every layout).
CIL=$ROOT/packaging/selinux/belgian_azerty_xkb.cil
selinux_label() {
    [ "$ETC" = /etc/xkb ] && [ -e /etc/selinux/config ] && command -v semodule >/dev/null 2>&1 || return 0
    if semodule -i "$CIL" >/dev/null 2>&1; then echo "SELinux: label usr_t added for /etc/xkb"
    else echo "SELinux: could not add the label for /etc/xkb (semodule failed): localectl may refuse layouts" >&2; fi
    command -v restorecon >/dev/null 2>&1 && restorecon -R "$ETC" >/dev/null 2>&1 || :
}
selinux_unlabel() {
    command -v semodule >/dev/null 2>&1 && semodule -l 2>/dev/null | grep -qx belgian_azerty_xkb || return 0
    semodule -r belgian_azerty_xkb >/dev/null 2>&1 && echo "SELinux: label for /etc/xkb removed"
}
need_root() { [ "$(id -u)" = 0 ] || { echo "run as root (sudo)" >&2; exit 1; }; }

gen_rules() {   # the system's rules (include), then exactly the blocks the Debian package's update-xkb-rules writes
    t=$(mktemp -d); : > "$t/evdev.distrib"
    sed "s|^RULES=.*|RULES=$t/evdev|" "$ROOT/packaging/belgian-azerty-windows/update-xkb-rules" > "$t/u.sh"
    sh "$t/u.sh"
    { echo "$MARK the system rules, then our three options. Removed with \"be-azerty-etc-xkb.sh remove\"."
      echo '! include %S/evdev'; cat "$t/evdev"; } > "$1"
    rm -rf "$t"
}

case "${1:-status}" in
install)
    need_root
    [ -f "$ROOT/xkb/symbols/be_capslock" ] || { echo "run this from a copy of the repository" >&2; exit 1; }
    mkdir -p "$ETC/rules" "$ETC/symbols"
    # an older copy of ours starts with the same first line; anything else is the user's own file
    if [ -f "$SYMS" ] && ! ours_syms && [ "$(head -1 "$SYMS")" != "$(head -1 "$ROOT/xkb/symbols/be_capslock")" ]; then
        echo "$SYMS exists and is not ours: left alone, nothing installed" >&2; exit 2
    fi
    cp "$ROOT/xkb/symbols/be_capslock" "$SYMS"; chmod 644 "$SYMS"
    if [ -f "$RULES" ] && ! ours_rules; then
        gen_rules "$RULES.belgian-azerty"; chmod 644 "$RULES.belgian-azerty"
        echo "$RULES was already there and is kept. Our rules are in $RULES.belgian-azerty:"
        echo "copy its lines (from '! option') into your file, or our options stay unknown."
        selinux_label; exit 2
    fi
    gen_rules "$RULES.new"; chmod 644 "$RULES.new"; mv "$RULES.new" "$RULES"
    selinux_label
    echo "installed: $RULES and $SYMS"
    echo "switch the options on, for the whole system: localectl set-x11-keymap be pc105 \"\" caps:be_windows,be_azerty:accents"
    echo "(or in your system's own keyboard settings file; see packaging/OTHER-DISTRIBUTIONS.md)"
    ;;
remove)
    need_root
    if ours_rules; then rm -f "$RULES"; echo "removed $RULES"; else echo "$RULES: not ours, left alone"; fi
    rm -f "$RULES.belgian-azerty"
    if ours_syms; then rm -f "$SYMS"; echo "removed $SYMS"; elif [ -f "$SYMS" ]; then echo "$SYMS: changed or not ours, left alone"; fi
    rmdir "$ETC/rules" "$ETC/symbols" "$ETC" 2>/dev/null || true
    [ -e "$ETC" ] || selinux_unlabel   # only when /etc/xkb is gone: files of the user's own there keep the label
    echo "switch the options off in your keyboard settings too (caps:be_windows, be_azerty:accents, be_azerty:mac)"
    ;;
status)
    if ours_rules; then echo "rules: ours ($RULES)"; elif [ -f "$RULES" ]; then echo "rules: $RULES is not ours"; else echo "rules: none"; fi
    if ours_syms; then echo "symbols: ours ($SYMS)"; elif [ -f "$SYMS" ]; then echo "symbols: $SYMS differs from this repository"; else echo "symbols: none"; fi
    if command -v semodule >/dev/null 2>&1; then
        if semodule -l 2>/dev/null | grep -qx belgian_azerty_xkb; then echo "SELinux label: ours (usr_t)"; else echo "SELinux label: not added"; fi
    fi
    if command -v xkbcli >/dev/null 2>&1; then
        if xkbcli compile-keymap --layout be --options caps:be_windows,be_azerty:accents 2>&1 | grep -q Unrecognized
        then echo "options: unknown to libxkbcommon"; else echo "options: known to libxkbcommon"; fi
    fi
    ;;
*) echo "usage: $0 install|remove|status" >&2; exit 1 ;;
esac
