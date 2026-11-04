#!/bin/bash
# gfeddiag3.sh: SELinux or sandbox? Tries localectl with SELinux permissive for a moment, then localed run by hand
# with debug logging (throwaway live VM). Ends with SELinux enforcing again and the X11 layout back to us.
U=http://10.0.2.2:8001; O=/tmp/gfed-diag3.txt
exec > $O 2>&1
try() { echo "== localectl set-x11-keymap $*"; sudo localectl set-x11-keymap "$@"; echo "exit $?: $(localectl status | grep -E 'X11 (Layout|Options)' | tr -s ' ' | tr '\n' ';')"; }
echo "--- diag3 $(date -u +%H:%M:%SZ) selinux=$(getenforce)"
sudo setenforce 0; echo "== selinux=$(getenforce)"
try be pc105 "" caps:be_windows,be_azerty:accents
sudo setenforce 1; echo "== selinux=$(getenforce)"
try us pc105
echo "== AVC denials for localed (journal)"
sudo journalctl -b --no-pager | grep -iE 'avc.*(localed|xkb)' | tail -8
sudo journalctl -b --no-pager -t audit | grep -iE 'denied' | grep -iE 'localed|xkb' | tail -8
echo "== file contexts expected for /etc/xkb"; matchpathcon /etc/xkb /etc/xkb/rules/evdev /usr/share/xkeyboard-config-2/rules/evdev 2>&1; ls -Z /usr/share/X11/xkb/rules/evdev 2>&1
echo "== localed by hand, debug, no sandbox, SELinux enforcing (process domain differs)"
sudo systemctl stop systemd-localed
sudo SYSTEMD_LOG_LEVEL=debug timeout 20 /usr/lib/systemd/systemd-localed > /tmp/ld.log 2>&1 &
sleep 2; try be pc105 "" caps:be_windows,be_azerty:accents; sleep 1
grep -iE 'xkb|keymap|compile|include|error' /tmp/ld.log | tail -15
wait; try us pc105
wget -q -T 5 --post-file=$O $U/gfed-diag3.txt -O /dev/null
