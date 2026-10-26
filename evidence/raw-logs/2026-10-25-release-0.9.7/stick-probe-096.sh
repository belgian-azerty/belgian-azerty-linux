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
echo "== session"; echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP"
echo "== caps in xkb"; setxkbmap -query | grep options; grep -c be_windows /etc/default/keyboard
echo "== ibus skip list"; be-azerty-fix ibus-skip list 2>&1 | sed 's/\x1b\[[0-9;]*m//g'
echo "== ibus skip files"; ls -la ~/.config/systemd/user/gnome-terminal-server.service.d/ 2>&1; cat ~/.config/systemd/user/gnome-terminal-server.service.d/*.conf 2>&1
ls -la ~/.local/share/applications/ 2>&1; grep -l X-BelgianAzerty-IbusSkip ~/.local/share/applications/*.desktop 2>&1
echo "== autostart"; ls -la /etc/xdg/autostart/be-azerty-ibus-skip.desktop; cat /etc/xdg/autostart/be-azerty-ibus-skip.desktop
echo "== running terminal env"; for p in $(pgrep -f gnome-terminal-server); do echo "pid $p"; tr '\0' '\n' < /proc/$p/environ | grep -E '^GTK_IM_MODULE' || echo "(no GTK_IM_MODULE)"; done
echo "== this shell GTK_IM_MODULE=${GTK_IM_MODULE:-unset}"
echo "== end"
