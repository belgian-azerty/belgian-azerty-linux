#!/bin/bash
up() { wget -q --post-file="$1" "http://10.0.2.2:8001/$2" -O /dev/null; }
bash /tmp/st.sh z-broken-rules-session >/dev/null
{ tail -3 /usr/share/X11/xkb/rules/evdev; sudo /usr/lib/belgian-azerty-windows/update-xkb-rules; echo "regen rc=$?"; tail -4 /usr/share/X11/xkb/rules/evdev; grep -c '^# stale' /usr/share/X11/xkb/rules/evdev; } > /tmp/z-fixrules.txt 2>&1; up /tmp/z-fixrules.txt z-fixrules.txt
sudo useradd -m -s /bin/bash newbe2; echo 'newbe2:belgie' | sudo chpasswd; echo 'newbe2 ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/newbe2 >/dev/null
sudo sed -i 's/^AutomaticLogin=.*/AutomaticLogin=newbe2/' /etc/gdm3/custom.conf; sudo systemctl restart gdm3
