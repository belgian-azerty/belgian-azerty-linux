#!/bin/bash
# repro: keyd + fix, Wayland session, IBUS_ENABLE_SYNC_MODE=1 in /etc/environment, then re-login
cd /tmp; H=http://10.0.2.2:8000
for f in be-azerty-fix.sh kbstate.sh keyd_2.5.0-0beazerty2_amd64.deb; do wget -q $H/$f; done
gsettings set org.gnome.desktop.session idle-delay 0; gsettings set org.gnome.desktop.screensaver lock-enabled false
sudo dpkg -i keyd_2.5.0-0beazerty2_amd64.deb >/dev/null 2>&1; sudo bash be-azerty-fix.sh live >/dev/null 2>&1
printf '[daemon]\nWaylandEnable=true\nAutomaticLoginEnable=true\nAutomaticLogin=zorin\n' | sudo tee /etc/gdm3/custom.conf >/dev/null
sudo sed -i 's/^Session=.*/Session=zorin-wayland/' /var/lib/AccountsService/users/zorin
[ "$1" = sync ] && echo IBUS_ENABLE_SYNC_MODE=1 | sudo tee -a /etc/environment
{ systemctl is-active keyd; cat /etc/environment; grep Session= /var/lib/AccountsService/users/zorin; } > /tmp/g2z.txt 2>&1
wget -q --post-file=/tmp/g2z.txt http://10.0.2.2:8001/g2z-$1.txt -O /dev/null
sudo systemctl restart gdm3
