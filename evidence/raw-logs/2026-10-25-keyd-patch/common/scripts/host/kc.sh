# kc.sh LABEL...: re-run kcheck on uploaded key logs
bash /mnt/c/Users/<you>/AppData/Local/Temp/claude/C--Users-x-zorin-and-Mint-keyboard-driver-resolution/a09be6af-3262-42b7-ba53-eb0280916bff/scratchpad/inst.sh > /dev/null
U=/root/be-rig/k94/uploads
for L in "$@"; do python3 /root/be-rig/k94/rig/kcheck.py $U/keylog-$L.txt > $U/kcheck-$L.txt; cat $U/kcheck-$L.txt; done
