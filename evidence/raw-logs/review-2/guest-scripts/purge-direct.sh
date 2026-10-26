#!/bin/bash
# README's "without the script" path: install + system, then plain apt purge (caps:be_windows stays in the settings), then re-login
cd /tmp; up() { wget -q --post-file="$1" "http://10.0.2.2:8001/$2" -O /dev/null; }
{ sudo apt-get install -y ./keyd_2.5.0-5~ubuntu24.04.1_amd64.deb ./keyd-belgian-windows_0.9.0_all.deb ./belgian-azerty-windows_0.9.0_all.deb >/dev/null 2>&1; echo "install rc=$?"
  sudo be-azerty-fix system >/dev/null 2>&1; echo "system rc=$?"; grep XKBOPTIONS /etc/default/keyboard
  sudo apt-get purge -y belgian-azerty-windows keyd-belgian-windows keyd 2>&1 | tail -3; echo "purge rc=$?"
  grep XKBOPTIONS /etc/default/keyboard; gsettings get org.cinnamon.desktop.input-sources xkb-options; echo "keyd: $(systemctl show keyd -p LoadState -p ActiveState | tr '\n' ' ')"
  ls /usr/share/glib-2.0/schemas/zz_* 2>&1; echo "Cinnamon default: $(GSETTINGS_BACKEND=memory gsettings get org.cinnamon.desktop.input-sources xkb-options)"
} > /tmp/m-purge-direct.txt 2>&1; up /tmp/m-purge-direct.txt m-purge-direct.txt
sudo systemctl restart lightdm
