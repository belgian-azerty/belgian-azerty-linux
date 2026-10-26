#!/bin/bash
cd /tmp; H=http://10.0.2.2:8000; up() { wget -q --post-file="$1" "http://10.0.2.2:8001/$2" -O /dev/null; }
for f in kbstate.sh st.sh xkbup.sh sweep-guest.sh durability-guest.sh gun.sh; do wget -q -O /tmp/$f "$H/$f"; done
{ echo "session: $XDG_SESSION_TYPE"; sha256sum /media/zorin/STICK/t14s-test/*.deb; dpkg-query -W belgian-azerty-windows keyd-belgian-windows keyd
  sudo DECIMAL=comma be-azerty-fix system; echo "rc=$?"; be-azerty-fix check; echo "overrides: $(ls /usr/share/glib-2.0/schemas/*belgian* 2>&1)"
  echo "GNOME default (memory): $(GSETTINGS_BACKEND=memory gsettings get org.gnome.desktop.input-sources xkb-options)"; } > z-sys.txt 2>&1; up z-sys.txt z-sys.txt
bash xkbup.sh z
sudo useradd -m -s /bin/bash newbe; echo 'newbe:belgie' | sudo chpasswd; echo 'newbe ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/newbe >/dev/null
sudo sed -i 's/^AutomaticLogin=.*/AutomaticLogin=newbe/' /etc/gdm3/custom.conf; grep -E 'Wayland|AutomaticLogin' /etc/gdm3/custom.conf > /tmp/z-gdm.txt; up /tmp/z-gdm.txt z-gdm.txt
sudo systemctl restart gdm3
