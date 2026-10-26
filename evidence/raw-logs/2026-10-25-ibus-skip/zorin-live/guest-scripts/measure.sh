#!/bin/bash
# measure.sh VM LABEL N MENUKEY: terminal block, then Typebox (opened from the desktop menu) block, then info upload.
# Blocks: N lines Ctrl+Alt held and N lines AltGr held (keys 30 ms apart, overlapping), 10 + 10 at 60 ms, 3 dead-key lines.
VM=$1; L=$2; N=${3:-100}; MK=${4:-meta_l}
R="python3 qemu_rig.py"
bursts() {
  python3 burst.py $VM ctrlalt --lines $N --gap 0.03 --overlap
  python3 burst.py $VM altgr --lines $N --gap 0.03 --overlap
  python3 burst.py $VM ctrlalt --lines 10 --gap 0.06
  python3 burst.py $VM altgr --lines 10 --gap 0.06
  python3 burst.py $VM dead --lines 3
}
$R click $VM 640 300 >/dev/null; sleep 2
$R type $VM --as be "clear; cat > /tmp/term.txt
"; sleep 3
bursts >/dev/null
$R keys $VM "ctrl-d"; sleep 3
$R keys $VM "$MK"; sleep 20
$R type $VM --as be "typebox"; sleep 15
$R keys $VM "ret"; sleep 100
$R shot $VM <workdir>/w/$VM-$L-typebox.png >/dev/null
bursts >/dev/null
sleep 5; $R keys $VM "alt-f4"; sleep 240
$R click $VM 640 300 >/dev/null; sleep 2
$R type $VM --delay 0.2 --as be "bash /tmp/g.sh info $L
"
timeout 120 bash -c "until [ -f <workdir>/up/info-$L.txt ]; do sleep 3; done"; sleep 5
S="$N:ctrlalt-o30,$N:altgr-o30,10:ctrlalt-60,10:altgr-60,3:dead"
for f in term tb; do echo "$f-$L"; [ -f <workdir>/up/$f-$L.txt ] && python3 blockscore.py <workdir>/up/$f-$L.txt "$S"; done
grep -E 'pid|typebox|context' <workdir>/up/info-$L.txt
