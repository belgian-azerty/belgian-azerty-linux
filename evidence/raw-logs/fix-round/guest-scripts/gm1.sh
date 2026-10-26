#!/bin/bash
# Mint live: md5 check result, install packages, system mode with Comma, prepare a brand-new user
cd /tmp; H=http://10.0.2.2:8000
for f in be-azerty-fix.sh kbstate.sh keyd_2.5.0-5~ubuntu24.04.1_amd64.deb keyd-belgian-windows_0.9.0_all.deb belgian-azerty-windows_0.9.0_all.deb gm2.sh; do wget -q "$H/$f"; done
gsettings set org.cinnamon.desktop.session idle-delay 0; gsettings set org.cinnamon.desktop.screensaver lock-enabled false
up() { wget -q --post-file="$1" "http://10.0.2.2:8001/$2" -O /dev/null; }
for i in $(seq 120); do [ -f /run/casper-md5check.json ] && break; sleep 10; done
{ date -u; cat /proc/cmdline; systemctl status casper-md5check --no-pager 2>&1 | head -6; cat /run/casper-md5check.json; } > m-md5check.txt 2>&1; up m-md5check.txt m-md5check.txt
{ bash kbstate.sh base; bash be-azerty-fix.sh check; } > m-base.txt 2>&1; up m-base.txt m-base.txt
{ sudo apt-get install -y ./keyd_2.5.0-5~ubuntu24.04.1_amd64.deb ./keyd-belgian-windows_0.9.0_all.deb ./belgian-azerty-windows_0.9.0_all.deb; echo "apt rc=$?"
  dpkg-divert --list | grep evdev; echo "keyd: $(systemctl is-active keyd) $(systemctl is-enabled keyd)"; systemctl show keyd -p Restart -p DropInPaths
  tail -4 /usr/share/X11/xkb/rules/evdev; } > m-inst.txt 2>&1; up m-inst.txt m-inst.txt
{ sudo DECIMAL=comma bash be-azerty-fix.sh system; echo "rc=$?"; } > m-sys.txt 2>&1; up m-sys.txt m-sys.txt
{ bash be-azerty-fix.sh check; echo "--- override:"; cat /usr/share/glib-2.0/schemas/zz_belgian-azerty-windows.gschema.override; } > m-check.txt 2>&1; up m-check.txt m-check.txt
sudo useradd -m -s /bin/bash newbe; echo 'newbe:belgie' | sudo chpasswd; echo 'newbe ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/newbe >/dev/null
grep -rh autologin /etc/lightdm/ > m-lightdm.txt 2>&1
sudo sed -i 's/^autologin-user=.*/autologin-user=newbe/' /etc/lightdm/lightdm.conf
grep -rh autologin /etc/lightdm/ >> m-lightdm.txt 2>&1; up m-lightdm.txt m-lightdm.txt
echo GM1DONE
