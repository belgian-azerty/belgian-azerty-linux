#!/bin/bash
{ echo "before:"; sudo -u zorin -H dbus-run-session sh -c 'dconf dump /org/gnome/desktop/input-sources/' 2>&1 | grep -v dbus-daemon
  sudo -u zorin -H dbus-run-session sh -c 'dconf reset -f /org/gnome/desktop/input-sources/' 2>&1 | grep -v dbus-daemon; echo "reset rc=$?"
  echo "after:"; sudo -u zorin -H dbus-run-session sh -c 'dconf dump /org/gnome/desktop/input-sources/' 2>&1 | grep -v dbus-daemon; echo "(empty above = wiped)"
} > /tmp/z-wipe.txt 2>&1; wget -q --post-file=/tmp/z-wipe.txt http://10.0.2.2:8001/z-wipe.txt -O /dev/null
sudo sed -i 's/^AutomaticLogin=.*/AutomaticLogin=zorin/' /etc/gdm3/custom.conf; sudo systemctl restart gdm3
