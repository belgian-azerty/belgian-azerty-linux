#!/bin/bash
# gtwdm.sh: which login manager draws the Tumbleweed login screen, and how does it get its keyboard?
U=http://10.0.2.2:8001; O=/tmp/gtw-dm.txt
exec > $O 2>&1
echo "--- dm $(date -u +%H:%M:%SZ)"
readlink -f /etc/systemd/system/display-manager.service; systemctl status display-manager --no-pager 2>&1 | head -12
grep -E '^DISPLAYMANAGER' /etc/sysconfig/displaymanager 2>/dev/null
rpm -qa | grep -iE 'sddm|plasma.*login|greet|lightdm|gdm' | sort
ps -eo pid,user,args | grep -iE 'greet|login|sddm|kwin|Xorg|Xwayland' | grep -v grep
echo "== greeter journal lines about keyboard"
sudo journalctl -b --no-pager | grep -iE 'greet|plasmalogin|plasma-login|sddm' | grep -iE 'xkb|keymap|layout|keyboard|kwin|wayland|x11|Xorg' | tail -15
echo "== xorg keyboard conf"; cat /etc/X11/xorg.conf.d/00-keyboard.conf 2>&1
curl -s -m 5 -T $O $U/gtw-dm.txt >/dev/null
