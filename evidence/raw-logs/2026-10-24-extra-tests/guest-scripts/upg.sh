#!/bin/bash
# upg.sh NAME: full system update in the live session (downloads on the scratch disk), log sent to the host
exec > /tmp/$1.log 2>&1
set -x
date -u
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
sudo mkfs.ext4 -q -F /dev/vda && sudo mount /dev/vda /var/cache/apt/archives && sudo mkdir -p /var/cache/apt/archives/partial
df -h / /var/cache/apt/archives
sudo apt-get update
apt list --upgradable 2>/dev/null | wc -l
apt list --upgradable 2>/dev/null | grep -i -E "xkb|keyboard|keyd|ibus|systemd|udev|mutter|gnome-shell|cinnamon|muffin|libinput|linux-image|xserver|xwayland|firefox|console-setup" 
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold full-upgrade
echo "full-upgrade exit $?"
apt list --upgradable 2>/dev/null | wc -l
date -u
set +x
wget -q --post-file=/tmp/$1.log http://10.0.2.2:8001/$1.log -O /dev/null
