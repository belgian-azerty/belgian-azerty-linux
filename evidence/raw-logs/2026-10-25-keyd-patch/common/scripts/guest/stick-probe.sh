#!/bin/bash
# stick-probe.sh: facts of a live session booted from the Belgian stick (same sections as the T1-T6 files of
# evidence/raw-logs/2026-10-24-stick/, rewritten 2026-10-24 evening because the first copy was lost).
# Run as the live user in a terminal: bash stick-probe.sh > /tmp/probe.txt 2>&1
echo "== cmdline"; cat /proc/cmdline
echo "== belgian-stick.log"; sudo cat /var/log/belgian-stick.log
echo "== services"; systemctl is-active belgian-stick-live.service; systemctl is-active keyd; systemctl is-enabled keyd
echo "== /etc/default/keyboard"; cat /etc/default/keyboard
echo "== /etc/default/locale"; cat /etc/default/locale
echo "== session locale"; locale; echo "$(LC_ALL= date '+%c') | $(date +%x) | $(date +%X)"
echo "== gsettings"; gsettings get org.gnome.desktop.input-sources sources; gsettings get org.gnome.desktop.input-sources xkb-options
gsettings get org.cinnamon.desktop.input-sources xkb-options 2>&1; gsettings get org.gnome.libgnomekbd.keyboard layouts 2>&1
echo "== setxkbmap"; setxkbmap -query
echo "== choices"; cat /var/lib/belgian-azerty-windows/choices 2>&1
echo "== packages"; dpkg-query -W belgian-azerty-windows keyd keyd-belgian-windows 2>&1
echo "== layers"; mount | grep -E ' /rofs | / ' 
echo "== check"; be-azerty-fix check 2>&1 | sed 's/\x1b\[[0-9;]*m//g'
