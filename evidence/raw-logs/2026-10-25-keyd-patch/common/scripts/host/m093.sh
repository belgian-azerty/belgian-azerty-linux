K=/root/be-rig/k94; HS=/mnt/c/Users/<you>/AppData/Local/Temp/claude/C--Users-x-zorin-and-Mint-keyboard-driver-resolution/a09be6af-3262-42b7-ba53-eb0280916bff/scratchpad/hs
cd $K/rig && python3 qemu_rig.py snap k94-mint kitready
bash $K/ty.sh k94-mint m093 us
bash $HS/wf.sh mint-093-check.txt 240; sleep 2
bash $K/sh.sh k94-mint m-093
grep -v -E "^(Get|Selecting|Preparing|Unpacking|Setting|Processing|Reading|Building|\(Reading)" $K/uploads/mint-093-install.txt
sed "s/\x1b\[[0-9;]*m//g" $K/uploads/mint-093-check.txt
