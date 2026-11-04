#!/bin/bash
# g26fresh.sh: after a new login, which keymap does GNOME send (options stored in dconf before the login)?
U=http://10.0.2.2:8001; O=/tmp/g26-fresh.txt
exec > $O 2>&1
echo "--- fresh $(date -u +%H:%M:%SZ) session=$XDG_SESSION_TYPE"
gsettings get org.gnome.desktop.input-sources sources; gsettings get org.gnome.desktop.input-sources xkb-options
timeout --foreground -k 2 8 xkbcli dump-keymap-wayland > /tmp/wl.xkb 2>/tmp/wl.err < /dev/null
echo "dump exit $?: $(grep -m1 -E 'xkb_symbols' /tmp/wl.xkb) be_capslock=$(grep -c be_capslock /tmp/wl.xkb)"
echo "keyd: $(systemctl is-active keyd) virtual devices: $(grep -c 'keyd virtual' /proc/bus/input/devices)"
wget -q -T 5 --post-file=$O $U/g26-fresh.txt -O /dev/null
