K=/root/be-rig/k94; HS=/mnt/c/Users/<you>/AppData/Local/Temp/claude/C--Users-x-zorin-and-Mint-keyboard-driver-resolution/a09be6af-3262-42b7-ba53-eb0280916bff/scratchpad/hs
bash /mnt/c/Users/<you>/AppData/Local/Temp/claude/C--Users-x-zorin-and-Mint-keyboard-driver-resolution/a09be6af-3262-42b7-ba53-eb0280916bff/scratchpad/inst.sh | head -2
touch $K/stamp; sleep 1
bash $K/ty.sh k94-mint reget be; bash $HS/wn.sh mint-get-check.txt 60 $K/stamp; grep -vc ": OK" $K/uploads/mint-get-check.txt
bash $K/ty.sh k94-mint st093 be; bash $HS/wf.sh mint-093-state.txt 60
sed -n '1,/== systemctl --failed/p' $K/uploads/mint-093-state.txt
bash $K/sh.sh k94-mint m-093-state
