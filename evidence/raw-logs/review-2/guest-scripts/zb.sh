#!/bin/bash
# Re-review, live session, first terminal: boot facts, md5 check, install CURRENT dist packages, packaged be-azerty-fix system (comma)
# $1 = m|z (distro tag)
T=$1; cd /tmp; H=http://10.0.2.2:8000
up() { wget -q --post-file="$1" "http://10.0.2.2:8001/$2" -O /dev/null; }
for f in kbstate.sh st.sh; do wget -q "$H/$f"; done
for d in cinnamon gnome; do gsettings set org.$d.desktop.session idle-delay 0 2>/dev/null; gsettings set org.$d.desktop.screensaver lock-enabled false 2>/dev/null; done
for i in $(seq 120); do [ -f /run/casper-md5check.json ] && break; sleep 10; done
{ date -u; cat /proc/cmdline; echo "--- secure boot:"; mokutil --sb-state 2>&1; od -An -t u1 /sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c 2>&1 | head -1
  echo "--- boot medium:"; findmnt /cdrom 2>&1; lsblk -o NAME,TRAN,SIZE,TYPE,MOUNTPOINT 2>&1 | head -12
  echo "--- md5 check:"; systemctl status casper-md5check --no-pager 2>&1 | head -5; cat /run/casper-md5check.json; } > $T-r1-boot.txt 2>&1; up $T-r1-boot.txt $T-r1-boot.txt
{ bash kbstate.sh base; echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE"; } > $T-r1-base.txt 2>&1; up $T-r1-base.txt $T-r1-base.txt
  echo "--- packaged command: $(command -v be-azerty-fix)"; man -w be-azerty-fix; ls /usr/share/doc/belgian-azerty-windows/ /usr/share/doc/keyd-belgian-windows/
echo ZBDONE
