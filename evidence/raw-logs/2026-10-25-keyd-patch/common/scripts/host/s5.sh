# s5.sh VM PREFIX TERMX TERMY MENUX MENUY: shortcut checks (a) Ctrl+Alt+T (b) held Ctrl+Alt 2 T (c) held 2 Right, then Left; then pointer click
K=/root/be-rig/k94; HS=/mnt/c/Users/<you>/AppData/Local/Temp/claude/C--Users-x-zorin-and-Mint-keyboard-driver-resolution/a09be6af-3262-42b7-ba53-eb0280916bff/scratchpad/hs
VM=$1; P=$2; TX=$3; TY=$4
cd $K/rig
python3 qemu_rig.py type $VM --as be "bash /tmp/k/sc.sh $P
" --delay 0.08
bash $HS/wf.sh ready-sc-$P 60
bash $K/sh.sh $VM $P-sc0
echo "$(date -u +%T.%N | cut -c1-12)Z (a) ctrl-alt-t"; python3 qemu_rig.py keys $VM ctrl-alt-t; sleep 5; bash $K/sh.sh $VM $P-sc-a
python3 qemu_rig.py type $VM --as be "exit
"; sleep 3; python3 qemu_rig.py click $VM $TX $TY >/dev/null; sleep 1; bash $K/sh.sh $VM $P-sc-a-closed
echo "$(date -u +%T.%N | cut -c1-12)Z (b) held 2 t"; python3 held.py $VM 2 t; sleep 5; bash $K/sh.sh $VM $P-sc-b
python3 qemu_rig.py type $VM --as be "exit
"; sleep 3; python3 qemu_rig.py click $VM $TX $TY >/dev/null; sleep 1; bash $K/sh.sh $VM $P-sc-b-closed
echo "$(date -u +%T.%N | cut -c1-12)Z (c) held 2 right"; python3 held.py $VM 2 right; sleep 3; bash $K/sh.sh $VM $P-sc-c-right
echo "$(date -u +%T.%N | cut -c1-12)Z (c) held left"; python3 held.py $VM left; sleep 3; bash $K/sh.sh $VM $P-sc-c-left
python3 qemu_rig.py click $VM $TX $TY >/dev/null; sleep 1
python3 qemu_rig.py keys $VM "ret ctrl-d"
bash $HS/wf.sh done-sc-$P 60
echo "typed: [$(tr '\n' '|' < $K/uploads/sc-typed-$P.txt)]"
grep 'keyd virtual' $K/uploads/keylog-sc-$P.txt | awk '{print $1, $(NF-1), $NF}' | tr '\n' ';' ; echo
awk '/^==/{if (h!="") print h" windows="n; h=$0; n=0; next} {n++} END{print h" windows="n}' $K/uploads/win-sc-$P.txt | uniq -f2 -c | head -40
echo "(6) pointer"; python3 qemu_rig.py click $VM $5 $6; sleep 2; bash $K/sh.sh $VM $P-pointer; python3 qemu_rig.py keys $VM esc
