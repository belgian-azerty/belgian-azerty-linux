#!/bin/bash
# Zorin live: md5 check result, install packages, system mode with Comma (no Cinnamon: no override expected)
cd /tmp; H=http://10.0.2.2:8000
for f in be-azerty-fix.sh kbstate.sh keyd_2.5.0-5~ubuntu24.04.1_amd64.deb keyd-belgian-windows_0.9.0_all.deb belgian-azerty-windows_0.9.0_all.deb gm2.sh gun.sh; do wget -q "$H/$f"; done
gsettings set org.gnome.desktop.session idle-delay 0; gsettings set org.gnome.desktop.screensaver lock-enabled false
up() { wget -q --post-file="$1" "http://10.0.2.2:8001/$2" -O /dev/null; }
for i in $(seq 120); do [ -f /run/casper-md5check.json ] && break; sleep 10; done
{ date -u; cat /proc/cmdline; systemctl status casper-md5check --no-pager 2>&1 | head -6; cat /run/casper-md5check.json; } > z-md5check.txt 2>&1; up z-md5check.txt z-md5check.txt
{ bash kbstate.sh base; bash be-azerty-fix.sh check; } > z-base.txt 2>&1; up z-base.txt z-base.txt
{ sudo apt-get install -y ./keyd_2.5.0-5~ubuntu24.04.1_amd64.deb ./keyd-belgian-windows_0.9.0_all.deb ./belgian-azerty-windows_0.9.0_all.deb; echo "apt rc=$?"
  dpkg-divert --list | grep evdev; echo "keyd: $(systemctl is-active keyd) $(systemctl is-enabled keyd)"; systemctl show keyd -p Restart -p DropInPaths
  tail -4 /usr/share/X11/xkb/rules/evdev; } > z-inst.txt 2>&1; up z-inst.txt z-inst.txt
{ sudo DECIMAL=comma bash be-azerty-fix.sh system; echo "rc=$?"; } > z-sys.txt 2>&1; up z-sys.txt z-sys.txt
{ bash be-azerty-fix.sh check; echo "--- overrides: $(ls /usr/share/glib-2.0/schemas/*belgian* 2>&1)"; echo "GNOME default xkb-options: $(GSETTINGS_BACKEND=memory gsettings get org.gnome.desktop.input-sources xkb-options)"; } > z-check.txt 2>&1; up z-check.txt z-check.txt
echo GZ1DONE
