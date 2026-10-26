# s9.sh VM PFX: uninstall, state, typing seq8
K=/root/be-rig/k94; HS=/mnt/c/Users/<you>/AppData/Local/Temp/claude/C--Users-x-zorin-and-Mint-keyboard-driver-resolution/a09be6af-3262-42b7-ba53-eb0280916bff/scratchpad/hs
C=/mnt/c/Users/<you>/AppData/Local/Temp/claude/C--Users-x-zorin-and-Mint-keyboard-driver-resolution/a09be6af-3262-42b7-ba53-eb0280916bff/scratchpad/cmd
VM=$1; P=$2
sed "s/PFX/$P/" $C/uninst > $C/$P-uninst
bash $K/ty.sh $VM $P-uninst be; bash $HS/wf.sh $P-uninstall.txt 240; sleep 3
sed "s/\x1b\[[0-9;]*m//g" $K/uploads/$P-uninstall.txt
printf '%s' "bash /tmp/k/st.sh $P-purged" > $C/$P-st-purged; bash $K/ty.sh $VM $P-st-purged be; bash $HS/wf.sh $P-purged-state.txt 60
cat $K/uploads/$P-purged-state.txt
printf '%s' "bash /tmp/t.sh $P-purged-typed" > $C/$P-t-purged
bash $HS/seq.sh $VM - $P-t-purged $P-purged-typed seq8.txt
