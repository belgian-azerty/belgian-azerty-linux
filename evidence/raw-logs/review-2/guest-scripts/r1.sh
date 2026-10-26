#!/bin/bash
# Re-review, live session, first terminal: boot facts, md5 check, install CURRENT dist packages, packaged be-azerty-fix system (comma)
# $1 = m|z (distro tag)
T=$1; cd /tmp; H=http://10.0.2.2:8000
up() { wget -q --post-file="$1" "http://10.0.2.2:8001/$2" -O /dev/null; }
for f in kbstate.sh keyd_2.5.0-5~ubuntu24.04.1_amd64.deb keyd-belgian-windows_0.9.0_all.deb belgian-azerty-windows_0.9.0_all.deb sweep-guest.sh; do wget -q "$H/$f"; done
for d in cinnamon gnome; do gsettings set org.$d.desktop.session idle-delay 0 2>/dev/null; gsettings set org.$d.desktop.screensaver lock-enabled false 2>/dev/null; done
for i in $(seq 120); do [ -f /run/casper-md5check.json ] && break; sleep 10; done
{ date -u; cat /proc/cmdline; echo "--- secure boot:"; mokutil --sb-state 2>&1; od -An -t u1 /sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c 2>&1 | head -1
  echo "--- boot medium:"; findmnt /cdrom 2>&1; lsblk -o NAME,TRAN,SIZE,TYPE,MOUNTPOINT 2>&1 | head -12
  echo "--- md5 check:"; systemctl status casper-md5check --no-pager 2>&1 | head -5; cat /run/casper-md5check.json; } > $T-r1-boot.txt 2>&1; up $T-r1-boot.txt $T-r1-boot.txt
{ bash kbstate.sh base; echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE"; } > $T-r1-base.txt 2>&1; up $T-r1-base.txt $T-r1-base.txt
{ sha256sum *.deb; sudo apt-get install -y ./keyd_2.5.0-5~ubuntu24.04.1_amd64.deb ./keyd-belgian-windows_0.9.0_all.deb ./belgian-azerty-windows_0.9.0_all.deb; echo "apt rc=$?"
  echo "--- packaged command: $(command -v be-azerty-fix)"; man -w be-azerty-fix; ls /usr/share/doc/belgian-azerty-windows/ /usr/share/doc/keyd-belgian-windows/
  dpkg-divert --list | grep evdev; echo "keyd: $(systemctl is-active keyd) $(systemctl is-enabled keyd)"; systemctl show keyd -p Restart -p DropInPaths -p ExecStart
  tail -4 /usr/share/X11/xkb/rules/evdev; echo "dpkg -V xkb-data: [$(dpkg -V xkb-data)]"; echo "dpkg -V ours: [$(dpkg -V belgian-azerty-windows keyd-belgian-windows keyd)]"
  echo "--- copyright files:"; head -4 /usr/share/doc/belgian-azerty-windows/copyright; grep -m1 Maintainer /var/lib/dpkg/status -A0 >/dev/null; dpkg-query -W -f='${Package} ${Maintainer}\n' belgian-azerty-windows keyd-belgian-windows keyd
} > $T-r1-inst.txt 2>&1; up $T-r1-inst.txt $T-r1-inst.txt
{ sudo DECIMAL=comma be-azerty-fix system; echo "rc=$?"; } > $T-r1-sys.txt 2>&1; up $T-r1-sys.txt $T-r1-sys.txt
{ be-azerty-fix check; echo "--- override:"; cat /usr/share/glib-2.0/schemas/zz_belgian-azerty-windows.gschema.override 2>&1; ls /usr/share/glib-2.0/schemas/*.override;
  echo "--- Cinnamon default (memory backend): $(GSETTINGS_BACKEND=memory gsettings get org.cinnamon.desktop.input-sources xkb-options 2>&1)"
  echo "--- who sets terminate:ctrl_alt_bksp:"; grep -l 'ctrl_alt_bksp' /usr/share/glib-2.0/schemas/* 2>/dev/null; } > $T-r1-check.txt 2>&1; up $T-r1-check.txt $T-r1-check.txt
echo R1DONE
