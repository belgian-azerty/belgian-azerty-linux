#!/bin/bash
# gtwigreet.sh: why AltGr+e gives nothing at the Tumbleweed SDDM login screen (X11 greeter) while Ctrl+Alt+e (keyd) gives a euro sign.
U=http://10.0.2.2:8001; O=/tmp/gtwi-greet.txt
exec > $O 2>&1
echo "--- greet $(date -u +%H:%M:%SZ)"
echo "== 00-keyboard.conf"; cat /etc/X11/xorg.conf.d/00-keyboard.conf 2>&1
echo "== sddm DisplayServer settings"; grep -rh -i 'DisplayServer' /etc/sddm.conf /etc/sddm.conf.d /usr/lib/sddm/sddm.conf.d /usr/share/sddm 2>/dev/null | sort -u
echo "== Xorg logs"; ls -l /var/log/Xorg.*.log /var/lib/sddm/.local/share/xorg/*.log 2>&1
for f in /var/log/Xorg.0.log /var/lib/sddm/.local/share/xorg/Xorg.0.log; do [ -f $f ] && { echo "-- $f"; sudo grep -iE 'xkb|keyboard|keyd|Option|warn|error|EE' $f | head -60; }; done
echo "== journal sddm/xkbcomp (this boot)"; sudo journalctl -b --no-pager | grep -iE 'xkbcomp|xkb|sddm-greeter|X\.Org' | head -40
echo "== keyd devices"; grep -A4 -i 'keyd virtual' /proc/bus/input/devices | grep -E 'Name|Handlers'
echo "== keyd conf"; cat /etc/keyd/*.conf
echo "== X server xkb dir has our option?"; grep -c be_windows /usr/share/X11/xkb/rules/evdev
curl -s -m 5 -T $O $U/gtwi-greet.txt >/dev/null
