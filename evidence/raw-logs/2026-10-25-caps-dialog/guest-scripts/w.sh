#!/bin/bash
# Live bench: give the live user a password so polkit asks, then switch auto-login to the Wayland session and restart GDM.
exec > >(tee /tmp/w.log) 2>&1
set -x
U=$(id -un)
echo "$U:azerty" | sudo chpasswd
sudo grep -rn . /etc/polkit-1/localauthority /var/lib/polkit-1/localauthority /etc/polkit-1/rules.d 2>/dev/null | head -40
sudo find /var/lib/polkit-1/localauthority /etc/polkit-1/localauthority -name '*.pkla' -path '*casper*' -o -name '*live*.pkla' 2>/dev/null
for f in $(sudo find /var/lib/polkit-1/localauthority /etc/polkit-1/localauthority -name '*.pkla' 2>/dev/null | xargs -r sudo grep -l 'ResultActive=yes' ); do sudo mv "$f" "$f.off"; done
sudo grep -rln "zorin\|live" /etc/polkit-1/rules.d /usr/share/polkit-1/rules.d 2>/dev/null
sudo sed -i -E 's/^WaylandEnable=false/WaylandEnable=true/' /etc/gdm3/custom.conf
sudo sed -i 's/^\[daemon\]/[daemon]\nDefaultSession=zorin-wayland.desktop/' /etc/gdm3/custom.conf
printf '[User]\nSession=zorin-wayland\nSystemAccount=false\n' | sudo tee /var/lib/AccountsService/users/$U
sudo mkdir -p /etc/udev/rules.d; sudo ln -sf /dev/null /etc/udev/rules.d/61-gdm.rules
cat /etc/gdm3/custom.conf
curl -sS -T /tmp/w.log http://10.0.2.2:8001/w.log
sudo systemctl restart gdm3
