#!/bin/bash
# inst.sh: automated install from the live session onto /dev/vda with the stick's own installer (its Belgian
# install hook runs as in a normal install); log and the stick hook's log sent to the host.
exec > /tmp/mint-install.log 2>&1; set -x; date -u
wget -q -O /tmp/mint.preseed http://10.0.2.2:8000/mint.preseed
sudo debconf-set-selections /tmp/mint.preseed
sudo -E ubiquity --automatic gtk_ui
echo "ubiquity exit $?"; date -u
sudo cat /var/log/belgian-stick.log; sudo tail -50 /var/log/installer/syslog 2>/dev/null
ls -la /target 2>/dev/null | head -3
set +x
wget -q --post-file=/tmp/mint-install.log http://10.0.2.2:8001/mint-install.log -O /dev/null
