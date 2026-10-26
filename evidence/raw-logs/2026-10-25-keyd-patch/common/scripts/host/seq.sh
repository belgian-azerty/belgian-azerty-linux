# seq.sh VM PROBECMD SEQCMD LABEL SEQFILE: probe, then typing capture of the kit sequence
K=/root/be-rig/k94; HS=/mnt/c/Users/<you>/AppData/Local/Temp/claude/C--Users-x-zorin-and-Mint-keyboard-driver-resolution/a09be6af-3262-42b7-ba53-eb0280916bff/scratchpad/hs
VM=$1
if [ "$2" != - ]; then bash $K/ty.sh $VM $2 be; bash $HS/wf.sh ${4%-seq}-probe.txt 60; fi
bash $K/ty.sh $VM $3 be; sleep 2
cd $K/rig; python3 qemu_rig.py keys $VM "$(cat $K/serve/$5)" --delay 0.3; python3 qemu_rig.py keys $VM "ret"; sleep 1
bash $K/sh.sh $VM $4-typed
python3 qemu_rig.py keys $VM "ctrl-d"
bash $HS/wf.sh $4-od.txt 30
echo "typed: [$(cat $K/uploads/$4.txt)]"; cat $K/uploads/$4-od.txt
