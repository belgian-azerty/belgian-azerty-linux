#!/bin/bash
# krun.sh VM LABEL: step 7. Starts k7.sh LABEL in the focused guest terminal; after each keyd restart (ready-LABEL-N)
# types one held-Ctrl+Alt line (swaptest ctrlalt, 120 ms). Then checks the 5 key logs.
VM=$1; L=$2; UP=/root/be-rig/k94/uploads
cd /root/be-rig/k94/rig
waitfor() { for _ in $(seq $(( $2 * 20 ))); do [ -e "$UP/$1" ] && return 0; sleep 0.05; done; echo "timeout waiting for $1" >&2; return 1; }
python3 qemu_rig.py type "$VM" --as be "bash /tmp/k/k7.sh $L
" --delay 0.08
for i in 1 2 3 4 5; do
  waitfor "ready-$L-$i" 60 || exit 1
  echo "$(date -u +%T.%N | cut -c1-12)Z ready $i -> typing"
  python3 swaptest.py lines "$VM" ctrlalt 1 120 --pause 0.1
done
waitfor "done-$L" 90 || exit 1
python3 swaptest.py expect ctrlalt; cat "$UP/out-$L.txt"; cat "$UP/state-$L.txt"
python3 /root/be-rig/k94/rig/kcheck.py "$UP"/keylog-$L-[1-5].txt | tee "$UP/kcheck-$L.txt"
