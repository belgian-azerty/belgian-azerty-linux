#!/bin/bash
# Bench setup for the Caps-dialog investigation (cloud emulator only). Run in the live session: bash /media/cd/setup.sh
exec > >(tee /tmp/setup.log) 2>&1
set -x
D=$(cd "$(dirname "$0")" && pwd)
U=$(id -un)
sudo dpkg -i "$D"/keyd_*.deb "$D"/keyd-belgian-windows_*.deb "$D"/belgian-azerty-windows_*.deb "$D"/libxkbcommon-tools_*.deb "$D"/wev_*.deb
sudo be-azerty-fix system
sudo systemctl stop keyd
cat /etc/default/keyboard
ls /usr/share/wayland-sessions/ /usr/share/xsessions/
cat /etc/gdm3/custom.conf
ls /lib/udev/rules.d/ | grep -i gdm
cat /var/lib/AccountsService/users/$U
curl -sS -T /tmp/setup.log http://10.0.2.2:8001/setup.log || wget -q --method=PUT --body-file=/tmp/setup.log http://10.0.2.2:8001/setup.log
