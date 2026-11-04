#!/bin/bash
# gtwisel.sh: installed Tumbleweed with 0.9.12-1, SELinux enforcing: does localectl work, and are there AVC denials?
U=http://10.0.2.2:8001; O=/tmp/gtwi-sel1.txt
exec > $O 2>&1
try() { echo "== localectl set-x11-keymap $*"; sudo localectl set-x11-keymap "$@"; echo "exit $?: $(localectl status | grep -E 'X11 (Layout|Options)' | tr -s ' ' | tr '\n' ';')"; }
echo "--- sel1 $(date -u +%H:%M:%SZ) enforce=$(cat /sys/fs/selinux/enforce)"
rpm -q belgian-azerty-windows selinux-policy-targeted policycoreutils 2>&1
ls -Z /etc/xkb/rules/evdev /etc/xkb/symbols/be_capslock /usr/share/X11/xkb/rules/evdev 2>&1
try be pc105 "" caps:be_windows,be_azerty:accents
try be pc105
echo "== AVC"; sudo ausearch -m avc -ts recent 2>/dev/null | grep -iE 'xkb|localed' | tail -4
sudo journalctl -b --no-pager | grep -iE 'avc.*denied' | grep -iE 'xkb|localed' | tail -4
sudo journalctl -b -u systemd-localed --no-pager | tail -4
curl -s -m 5 -T $O $U/gtwi-sel1.txt >/dev/null
