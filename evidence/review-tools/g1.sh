#!/bin/bash
# review guest setup: fetch files, record state, install keyd + VS Code
cd /tmp; H=http://10.0.2.2:8000
for f in be-azerty-fix.sh kbstate.sh keyd_2.5.0-0beazerty2_amd64.deb code.deb sweep-guest.sh; do wget -q $H/$f; done
gsettings set org.cinnamon.desktop.session idle-delay 0 2>/dev/null; gsettings set org.cinnamon.desktop.screensaver lock-enabled false 2>/dev/null
up() { wget -q --post-file="$1" "http://10.0.2.2:8001/$2" -O /dev/null; }
{ bash kbstate.sh base; bash be-azerty-fix.sh check; cat /proc/cmdline; systemctl status casper-md5check --no-pager 2>&1 | head -12; cat /run/casper-md5check.json 2>&1; } > /tmp/m-base.txt 2>&1
up /tmp/m-base.txt m-base.txt
sudo dpkg -i keyd_2.5.0-0beazerty2_amd64.deb > /tmp/m-inst.txt 2>&1
sudo apt-get install -y ./code.deb >> /tmp/m-inst.txt 2>&1; echo "code rc=$?" >> /tmp/m-inst.txt
systemctl is-active keyd >> /tmp/m-inst.txt; up /tmp/m-inst.txt m-inst.txt
echo G1DONE
