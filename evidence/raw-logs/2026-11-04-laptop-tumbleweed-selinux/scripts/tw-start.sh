#!/bin/bash
# tw-start.sh [install|disk]: start the installed-Tumbleweed VM "twi" on its own qcow2 in /root/be-rig/p3 (my own dir).
W=/root/be-rig/p3; ISO=/root/be-rig/iso/openSUSE-Tumbleweed-DVD-x86_64-Snapshot20261102-Media.iso
SP=/mnt/c/Users/<you>/AppData/Local/Temp/claude/<session folder>/scratchpad/p3
bash $SP/rig.sh prep >/dev/null 2>&1; ss -ltn | grep -E ':800[01]'
[ -f $W/tw.qcow2 ] || qemu-img create -q -f qcow2 $W/tw.qcow2 30G
ls -l $W/tw.qcow2
if [ "$1" = install ]; then
  bash $SP/rig.sh start twi --uefi --mem 6144 --smp 4 --iso $ISO --disk $W/tw.qcow2
else
  bash $SP/rig.sh start twi --uefi --mem 6144 --smp 4 --disk $W/tw.qcow2
fi
