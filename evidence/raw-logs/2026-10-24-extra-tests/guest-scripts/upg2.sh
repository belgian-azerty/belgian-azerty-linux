#!/bin/bash
# Full system update on an INSTALLED system (no scratch disk, no mkfs). Usage: bash upg2.sh NAME
n=${1:-update}; L=/tmp/$n.log
{
date -u; df -h /
sudo apt-get update
apt list --upgradable 2>/dev/null | tee /tmp/$n-upgradable.txt | wc -l
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold full-upgrade
echo "full-upgrade rc $?"
date -u; df -h /
dpkg -l | grep -E '^.. +(keyd|keyd-belgian-windows|belgian-azerty-windows|keyboard-configuration|console-setup|xkb-data) ' 
} > $L 2>&1
for f in $n.log $n-upgradable.txt; do wget -q --post-file=/tmp/$f http://10.0.2.2:8001/$f -O /dev/null; done
echo "uploaded $n"
