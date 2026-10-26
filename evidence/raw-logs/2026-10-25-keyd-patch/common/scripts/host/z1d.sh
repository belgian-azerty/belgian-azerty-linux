K=/root/be-rig/k94; HS=/mnt/c/Users/<you>/AppData/Local/Temp/claude/C--Users-x-zorin-and-Mint-keyboard-driver-resolution/a09be6af-3262-42b7-ba53-eb0280916bff/scratchpad/hs
cd $K/rig
cat $K/uploads/zorin-get-check.txt | grep -c ": OK"
python3 qemu_rig.py snap k94-zorin kitready
python3 qemu_rig.py keys k94-zorin ret; sleep 2
bash $K/ty.sh k94-zorin z094 us
bash $HS/wf.sh zorin-094-check.txt 300; sleep 2
bash $K/sh.sh k94-zorin z-094
grep -v -E "^(Get|Selecting|Preparing|Unpacking|Setting|Processing|Reading|Building|\(Reading)" $K/uploads/zorin-094-install.txt
sed "s/\x1b\[[0-9;]*m//g" $K/uploads/zorin-094-check.txt
