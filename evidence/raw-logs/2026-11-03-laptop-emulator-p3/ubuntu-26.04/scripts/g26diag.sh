#!/bin/bash
# g26diag.sh: why does Caps Lock not act as on Windows in the GNOME Wayland session? Read-only except installing
# libxkbcommon-tools (xkbcli). Writes /tmp/g26-diag.txt and uploads it.
U=http://10.0.2.2:8001; O=/tmp/g26-diag.txt
{
echo "--- diag $(date -u +%H:%M:%SZ)"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q libxkbcommon-tools 2>&1 | tail -1
dpkg-query -W -f '${Package} ${Version}\n' libxkbcommon0 libxkbcommon-x11-0 mutter-common gnome-shell libmutter-18-0 2>/dev/null
ls -ld /usr/share/X11/xkb /usr/share/xkeyboard-config-2 /etc/xkb 2>&1
ls -l /usr/share/X11/xkb/symbols/be_capslock /usr/share/xkeyboard-config-2/symbols/be_capslock 2>&1
echo "== tail of real rules file"; tail -n 25 /usr/share/xkeyboard-config-2/rules/evdev
echo "== xkbcli list paths"; xkbcli --help 2>&1 | head -5
echo "== compile caps only, verbose"
xkbcli compile-keymap --verbose --layout be --options caps:be_windows 2>&1 | grep -iE 'warn|error|include|path|caps|be_capslock' | head -30
echo "== keymap with caps option: symbols line"
xkbcli compile-keymap --layout be --options caps:be_windows,be_azerty:accents 2>/dev/null | grep -E 'xkb_symbols|include' | head -5
xkbcli compile-keymap --kccgst --layout be --options caps:be_windows,be_azerty:accents 2>&1 | head -10
echo "== same with rules evdev explicit and base"
xkbcli compile-keymap --kccgst --rules evdev --layout be --options caps:be_windows 2>&1 | grep symbols
xkbcli compile-keymap --kccgst --rules base --layout be --options caps:be_windows 2>&1 | grep symbols
echo "== key AE01 in compiled keymap (with option)"
xkbcli compile-keymap --layout be --options caps:be_windows 2>/dev/null | grep -A4 'key <AE01>' | head -8
echo "== gnome-shell / mutter xkb messages"
journalctl --user -b --no-pager 2>/dev/null | grep -iE 'xkb|keymap|be_capslock|caps' | tail -20
journalctl -b --no-pager 2>/dev/null | grep -iE 'xkbcommon|keymap' | tail -10
echo "== gsettings"; gsettings get org.gnome.desktop.input-sources xkb-options; gsettings get org.gnome.desktop.input-sources sources
echo "== env"; env | grep -iE 'XKB|XDG_CONFIG'
echo "== keyd conf"; cat /etc/keyd/*.conf | grep -v '^#' | grep -v '^$' | head -30
} > $O 2>&1
wget -q --post-file=$O $U/g26-diag.txt -O /dev/null; echo "uploaded $O"
