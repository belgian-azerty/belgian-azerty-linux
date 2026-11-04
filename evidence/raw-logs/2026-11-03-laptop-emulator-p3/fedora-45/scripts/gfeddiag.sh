#!/bin/bash
# gfeddiag.sh: why does localectl refuse our options on Fedora 45 live? Tries several keymaps, keeps the last good one.
U=http://10.0.2.2:8001; O=/tmp/gfed-diag.txt
exec > $O 2>&1
try() { echo "== localectl set-x11-keymap $*"; sudo localectl set-x11-keymap "$@"; echo "exit $?: $(localectl status | grep -E 'X11 (Layout|Options)' | tr -s ' ' | tr '\n' ';')"; }
echo "--- diag $(date -u +%H:%M:%SZ)"
try be pc105
try be pc105 "" terminate:ctrl_alt_bksp
try be pc105 "" caps:be_windows
try be pc105 "" be_azerty:accents
try be pc105 "" caps:be_windows,be_azerty:accents
echo "== xkbcli as root, clean environment"
sudo env -i /usr/bin/xkbcli compile-keymap --rules evdev --model pc105 --layout be --options caps:be_windows,be_azerty:accents > /dev/null 2>/tmp/c.err; echo "exit $? $(grep -iE 'error|be_capslock' /tmp/c.err | head -3)"
echo "== localed unit sandboxing"
systemctl cat systemd-localed.service | grep -iE 'Protect|ReadOnly|Inaccessible|Private|RootDir|Bind|TemporaryFileSystem'
echo "== localed journal"
sudo journalctl -b -u systemd-localed --no-pager | tail -15
echo "== /etc/xkb perms and SELinux labels"
ls -lZd /etc/xkb /etc/xkb/rules /etc/xkb/symbols; ls -lZ /etc/xkb/rules/evdev /etc/xkb/symbols/be_capslock
getenforce
sudo ausearch -m avc -ts recent 2>/dev/null | grep -iE 'xkb|localed' | tail -5
wget -q -T 5 --post-file=$O $U/gfed-diag.txt -O /dev/null
