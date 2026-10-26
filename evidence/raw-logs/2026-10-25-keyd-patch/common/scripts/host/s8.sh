# s8.sh VM PFX: system with PROFILE=linux, state + typing (seq8), then PROFILE=windows, state + typing
K=/root/be-rig/k94; HS=/mnt/c/Users/<you>/AppData/Local/Temp/claude/C--Users-x-zorin-and-Mint-keyboard-driver-resolution/a09be6af-3262-42b7-ba53-eb0280916bff/scratchpad/hs
C=/mnt/c/Users/<you>/AppData/Local/Temp/claude/C--Users-x-zorin-and-Mint-keyboard-driver-resolution/a09be6af-3262-42b7-ba53-eb0280916bff/scratchpad/cmd
VM=$1; P=$2
for v in linux windows; do
  sed "s/PFX/$P/" $C/sys-$v > $C/$P-sys-$v
  bash $K/ty.sh $VM $P-sys-$v be; bash $HS/wf.sh $P-sys-$v.txt 240; sleep 3
  sed "s/\x1b\[[0-9;]*m//g" $K/uploads/$P-sys-$v.txt
  printf '%s' "bash /tmp/k/st.sh $P-$v" > $C/$P-st-$v; bash $K/ty.sh $VM $P-st-$v be; bash $HS/wf.sh $P-$v-state.txt 60
  sed -n '/== systemctl is-active/,/== systemctl --failed/p' $K/uploads/$P-$v-state.txt
  printf '%s' "bash /tmp/t.sh $P-$v-typed" > $C/$P-t-$v
  bash $HS/seq.sh $VM - $P-t-$v $P-$v-typed seq8.txt
done
