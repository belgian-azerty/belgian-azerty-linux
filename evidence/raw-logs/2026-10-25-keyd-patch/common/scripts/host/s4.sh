# s4.sh VM PREFIX: held Ctrl+Alt 10 lines, then held AltGr 10 lines
bash /mnt/c/Users/<you>/AppData/Local/Temp/claude/C--Users-x-zorin-and-Mint-keyboard-driver-resolution/a09be6af-3262-42b7-ba53-eb0280916bff/scratchpad/inst.sh > /dev/null
K=/root/be-rig/k94
bash $K/hrun.sh $1 $2-ca ctrlalt 10
bash $K/sh.sh $1 $2-ca
bash $K/hrun.sh $1 $2-ag altgr 10
cat $K/uploads/score-$2-ca.txt $K/uploads/score-$2-ag.txt
