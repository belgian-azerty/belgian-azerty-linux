K=/root/be-rig/k94; HS=/mnt/c/Users/<you>/AppData/Local/Temp/claude/C--Users-x-zorin-and-Mint-keyboard-driver-resolution/a09be6af-3262-42b7-ba53-eb0280916bff/scratchpad/hs
cd $K/rig; python3 qemu_rig.py keys k94-zorin ret; sleep 2
bash $HS/s8.sh k94-zorin zorin
echo "################ STEP 9"
bash $HS/s9.sh k94-zorin zorin
