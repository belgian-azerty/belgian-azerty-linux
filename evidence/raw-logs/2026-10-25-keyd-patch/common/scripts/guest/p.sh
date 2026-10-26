#!/bin/bash
# p.sh NAME: probe facts (stick-probe.sh) + versions of the parts an update could touch, sent to the host as NAME.txt
{ bash /tmp/stick-probe.sh
  echo "== versions"; dpkg-query -W xkb-data keyboard-configuration libxkbcommon0 ibus systemd udev mutter gnome-shell cinnamon muffin firefox linux-image-generic 2>/dev/null
  uname -r
  echo "== keyd.service"; systemctl status keyd --no-pager 2>&1 | head -5
  echo "== xkb option file"; ls -la /usr/share/X11/xkb/symbols/ 2>/dev/null | grep -i -E "belg|be$|be_" ; grep -rl "be-windows\|belgian" /usr/share/X11/xkb/rules/evdev.lst 2>/dev/null
  echo "== sleep"; cat /sys/power/state /sys/power/mem_sleep 2>&1
  echo "== journal suspend"; journalctl -b --no-pager 2>/dev/null | grep -i -E "PM: suspend|suspend exit|ACPI: PM: Waking|keyd" | tail -15
} > /tmp/$1.txt 2>&1
wget -q --post-file=/tmp/$1.txt http://10.0.2.2:8011/$1.txt -O /dev/null && echo "uploaded $1"
