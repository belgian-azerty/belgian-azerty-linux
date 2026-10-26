#!/bin/bash
# wipe the mint user's Cinnamon + keyboard settings (a "reset"), then autologin mint again
{ echo "before:"; sudo -u mint -H dbus-run-session sh -c 'dconf dump /org/cinnamon/desktop/input-sources/; dconf dump /org/gnome/libgnomekbd/' 2>&1
  sudo -u mint -H dbus-run-session sh -c 'dconf reset -f /org/cinnamon/; dconf reset -f /org/gnome/libgnomekbd/; dconf reset -f /org/gnome/desktop/input-sources/' 2>&1; echo "reset rc=$?"
  echo "after:"; sudo -u mint -H dbus-run-session sh -c 'dconf dump /org/cinnamon/ | head -5; dconf dump /org/gnome/libgnomekbd/; dconf dump /org/gnome/desktop/input-sources/' 2>&1; echo "(empty above = wiped)"
} > /tmp/m-wipe.txt 2>&1; wget -q --post-file=/tmp/m-wipe.txt http://10.0.2.2:8001/m-wipe.txt -O /dev/null
sudo sed -i 's/^autologin-user=.*/autologin-user=mint/' /etc/lightdm/lightdm.conf; sudo systemctl restart lightdm
