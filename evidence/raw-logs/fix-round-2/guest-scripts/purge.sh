#!/bin/bash
# purge.sh LABEL: plain apt purge (not be-azerty-fix uninstall), what it leaves. Output /tmp/purge-LABEL.txt, uploaded.
L=$1; O=/tmp/purge-$L.txt
{
echo "=== plain purge $L $(date -u +%FT%TZ) $(lsb_release -ds) session=$XDG_SESSION_TYPE"
echo "before: $(grep XKBOPTIONS /etc/default/keyboard) | user: $(gsettings get org.gnome.desktop.input-sources xkb-options 2>/dev/null; gsettings get org.cinnamon.desktop.input-sources xkb-options 2>/dev/null)"
sudo DEBIAN_FRONTEND=noninteractive apt-get purge -y belgian-azerty-windows keyd-belgian-windows keyd 2>&1 | tail -6; echo "purge rc=${PIPESTATUS[0]}"
echo "after: $(grep XKBOPTIONS /etc/default/keyboard)"
echo "debconf optionscode: $(echo 'GET keyboard-configuration/optionscode' | sudo debconf-communicate keyboard-configuration)"
echo "user settings: $(gsettings get org.gnome.desktop.input-sources xkb-options 2>/dev/null; gsettings get org.cinnamon.desktop.input-sources xkb-options 2>/dev/null)"
echo "keyd unit: $(systemctl show keyd -p LoadState -p ActiveState --value | tr '\n' ' ')"
echo "rules: $(grep -c caps:be_windows /usr/share/X11/xkb/rules/evdev) caps lines; diversion: $(dpkg-divert --list /usr/share/X11/xkb/rules/evdev)"
ls -d /var/lib/belgian-azerty-windows /etc/keyd 2>&1
echo "xkbcli with the leftover option: $(xkbcli compile-keymap --layout be --options caps:be_windows 2>&1 >/dev/null | head -2; echo rc=$?)"
} > "$O" 2>&1
wget -q --post-file="$O" "http://10.0.2.2:8001/purge-$L.txt" -O /dev/null; echo "purge done: $O"
