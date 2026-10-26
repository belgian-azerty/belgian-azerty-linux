#!/bin/bash
# order-probe.sh VM LABEL N: N order lines each for AltGr and Ctrl+Alt (2 e x8) at 0.15 s, plus 0.08 s, into /tmp/ord-LABEL.txt
cd "$(dirname "$0")"; VM=$1; L=$2; N=${3:-5}; R="python3 qemu_rig.py"
[ -z "$EDITOR_MODE" ] && { $R type $VM --as be "clear; cat > /tmp/ord-$L.txt
"; timeout 2 tail -f /dev/null; }
for i in $(seq $N); do
  $R type $VM --as be "AltGr015-$i: "; for j in 1 2 3 4 5 6 7 8; do $R keys $VM "alt_r-2 alt_r-e" --delay 0.15; done; $R keys $VM ret
  $R type $VM --as be "CtrlAlt015-$i: "; for j in 1 2 3 4 5 6 7 8; do $R keys $VM "ctrl-alt-2 ctrl-alt-e" --delay 0.15; done; $R keys $VM ret
done
$R type $VM --as be "AltGr008: "; $R keys $VM "$(for j in 1 2 3 4 5 6 7 8; do printf 'alt_r-2 alt_r-e '; done)" --delay 0.08; $R keys $VM ret
$R type $VM --as be "CtrlAlt008: "; $R keys $VM "$(for j in 1 2 3 4 5 6 7 8; do printf 'ctrl-alt-2 ctrl-alt-e '; done)" --delay 0.08; $R keys $VM ret
$R type $VM --as be "plain008: "; $R keys $VM "$(for j in 1 2 3 4 5 6 7 8; do printf 'q w '; done)" --delay 0.08; $R keys $VM ret
[ -n "$EDITOR_MODE" ] && exit 0   # editor: caller saves the file
$R keys $VM ctrl-d; timeout 2 tail -f /dev/null
$R type $VM --as be "wget -q --post-file=/tmp/ord-$L.txt http://10.0.2.2:8001/ord-$L.txt -O /dev/null
"
