#!/bin/bash
# hrun.sh VM LABEL PATTERN N: guest terminal focused at a prompt; starts hl.sh LABEL, types N swaptest lines (120 ms),
# Ctrl+D, then scores (swapscore.py) and checks the key log (kcheck.py). Results in /root/be-rig/k94/uploads.
VM=$1; L=$2; P=$3; N=$4; UP=/root/be-rig/k94/uploads
cd /root/be-rig/k94/rig
waitfor() { for _ in $(seq $(( $2 * 5 ))); do [ -e "$UP/$1" ] && return 0; sleep 0.2; done; echo "timeout waiting for $1" >&2; return 1; }
python3 qemu_rig.py type "$VM" --as be "bash /tmp/k/hl.sh $L
" --delay 0.08
waitfor "ready-$L" 60 || exit 1
sleep 1.5
python3 swaptest.py lines "$VM" "$P" "$N" 120
sleep 1.5
python3 qemu_rig.py keys "$VM" "ctrl-d"
waitfor "done-$L" 60 || exit 1
echo "$(date -u +%T)Z $VM $L $P n=$N gap=120" >> /root/be-rig/k94/logs/runs.log
python3 swapscore.py "$UP" "$L" "$P"
python3 /root/be-rig/k94/rig/kcheck.py "$UP/keylog-$L.txt" | tee "$UP/kcheck-$L.txt"
