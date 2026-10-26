#!/bin/bash
# sh.sh VM NAME: screenshot into k94/shots/NAME.png + a viewing copy in the scratchpad
cd /root/be-rig/k94/rig && python3 qemu_rig.py shot "$1" /root/be-rig/k94/shots/$2.png >/dev/null
SP=/mnt/c/Users/<you>/AppData/Local/Temp/claude/C--Users-x-zorin-and-Mint-keyboard-driver-resolution/a09be6af-3262-42b7-ba53-eb0280916bff/scratchpad
cp /root/be-rig/k94/shots/$2.png $SP/shots/ && echo "$(date -u +%T)Z shot $2"
