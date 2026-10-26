#!/bin/bash
# st.sh LABEL: state snapshot (packages, keyd, failed units, /etc/keyd, check with the kit script) uploaded as LABEL-state.txt
L=$1
{ echo "== $L $(date -u +%FT%TZ)"
  echo "== dpkg -l | grep -E 'keyd|belgian'"; dpkg -l | grep -E "keyd|belgian"; echo "(grep exit $?)"
  echo "== dpkg-query"; dpkg-query -W keyd keyd-belgian-windows belgian-azerty-windows 2>&1
  echo "== keyd exe (sudo)"; sudo ls -l /proc/$(pidof keyd.rvaiya)/exe 2>&1
  echo "== systemctl is-active keyd"; systemctl is-active keyd; echo "== is-enabled"; systemctl is-enabled keyd 2>&1
  echo "== systemctl --failed"; systemctl --failed --no-pager
  echo "== /etc/keyd"; ls -la /etc/keyd 2>&1
  echo "== /etc/default/keyboard"; cat /etc/default/keyboard
  echo "== choices"; cat /var/lib/belgian-azerty-windows/choices 2>&1
  echo "== setxkbmap"; setxkbmap -query 2>&1
  echo "== gsettings"; gsettings get org.gnome.desktop.input-sources xkb-options 2>&1; gsettings get org.cinnamon.desktop.input-sources xkb-options 2>&1
  echo "== check (kit script)"; bash /tmp/k/be-azerty-fix.sh check 2>&1 | sed 's/\x1b\[[0-9;]*m//g'
  echo "== check (installed)"; be-azerty-fix check 2>&1 | sed 's/\x1b\[[0-9;]*m//g'
} > /tmp/k/$L-state.txt 2>&1
wget -q --post-file=/tmp/k/$L-state.txt http://10.0.2.2:8011/$L-state.txt -O /dev/null
clear; echo "st done $L"
