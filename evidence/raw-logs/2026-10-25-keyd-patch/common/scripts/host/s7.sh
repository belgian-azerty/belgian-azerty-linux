# s7.sh VM LABEL TX TY
bash /mnt/c/Users/<you>/AppData/Local/Temp/claude/C--Users-x-zorin-and-Mint-keyboard-driver-resolution/a09be6af-3262-42b7-ba53-eb0280916bff/scratchpad/inst.sh > /dev/null
K=/root/be-rig/k94; cd $K/rig
python3 qemu_rig.py click $1 $3 $4 > /dev/null; sleep 1
bash $K/krun.sh $1 $2
bash $K/sh.sh $1 $2
cat $K/uploads/journal-$2.txt
