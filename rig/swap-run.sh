#!/bin/bash
# swap-run.sh VM LABEL KEYD IBUS PATTERN N GAP_MS [--roll]: one block of the fast-typing order test (host, in WSL).
# The guest terminal must be focused at a shell prompt, with /tmp/swap-guest.sh and /tmp/keylog.py present.
# APP="box4 VAR=VALUE" types into typebox.py instead of the terminal (the window is clicked first).
# Results land in $UP (default /root/be-rig/up): out-, keylog-, state- files per LABEL.
cd "$(dirname "$0")"
VM=$1; L=$2; K=$3; I=$4; P=$5; N=$6; G=$7; R=${8:-}
UP=${UP:-/root/be-rig/up}
waitfor() { for _ in $(seq "$2"); do [ -e "$UP/$1" ] && return 0; sleep 1; done; echo "timeout waiting for $1" >&2; return 1; }
rm -f "$UP/ready-$L" "$UP/done-$L"
python3 qemu_rig.py click "$VM" ${TERMXY:-640 400} > /dev/null; sleep 0.5   # make sure the terminal has the focus
python3 qemu_rig.py type "$VM" --as be "bash /tmp/swap-guest.sh $L $K $I $APP
" --delay 0.2
waitfor "ready-$L" 60 || exit 1
[ -n "${APP:-}" ] && python3 qemu_rig.py click "$VM" 640 420 > /dev/null
sleep 1.5
python3 swaptest.py lines "$VM" "$P" "$N" "$G" $R
sleep 1.5
python3 qemu_rig.py keys "$VM" "ctrl-d"
waitfor "done-$L" 60 || exit 1
echo "$(date -u +%T) $L $K $I $P n=$N gap=$G $R app=[${APP:-terminal}]" >> "$UP/swap-runs.log"
python3 swapscore.py "$UP" "$L" "$P"
