#!/bin/bash
# room.sh: the live overlay (RAM, 4.9 GB) is too small for 590 updates. Pause dpkg, move the two bulkiest
# update targets (firmware, the new kernel's modules) onto the scratch disk with bind mounts, resume dpkg.
# Emulator-environment workaround only; nothing on the keyboard path is touched.
exec >> /tmp/room.log 2>&1; set -x
P=$(pgrep -x dpkg); sudo kill -STOP $P
B=/var/cache/apt/archives/big; sudo mkdir -p $B/fw $B/mod
sudo cp -a /usr/lib/firmware/. $B/fw/ && sudo mount --bind $B/fw /usr/lib/firmware
sudo mkdir -p /usr/lib/modules/7.0.0-38-generic && sudo mount --bind $B/mod /usr/lib/modules/7.0.0-38-generic
sudo kill -CONT $P
findmnt /usr/lib/firmware /usr/lib/modules/7.0.0-38-generic; df -h / $B
wget -q --post-file=/tmp/room.log http://10.0.2.2:8001/mint-room.log -O /dev/null
