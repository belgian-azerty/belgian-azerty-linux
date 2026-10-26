#!/bin/bash
# ty.sh VM CMDFILE [be|us]: type the one-line command in scratchpad/cmd/CMDFILE + Enter
SP=/mnt/c/Users/<you>/AppData/Local/Temp/claude/C--Users-x-zorin-and-Mint-keyboard-driver-resolution/a09be6af-3262-42b7-ba53-eb0280916bff/scratchpad
line=$(tr -d '\r\n' < "$SP/cmd/$2")
echo "$(date -u +%T)Z $1 [${3:-be}] $line" | tee -a /root/be-rig/k94/logs/typed-commands.log
cd /root/be-rig/k94/rig && python3 qemu_rig.py type "$1" --as "${3:-be}" --delay 0.08 "$line
"
