#!/bin/bash
# typed-probe.sh VM LABEL: in a focused terminal, record plain / AltGr / Ctrl+Alt / Caps typing into /tmp/typed-LABEL.txt and upload it.
cd "$(dirname "$0")"
VM=$1; L=$2; R="python3 qemu_rig.py"
w() { timeout "$1" tail -f /dev/null; }
K="ctrl-alt-1 ctrl-alt-2 ctrl-alt-3 ctrl-alt-4 ctrl-alt-5 ctrl-alt-6 ctrl-alt-9 ctrl-alt-0 ctrl-alt-e ctrl-alt-bracket_left ctrl-alt-bracket_right ctrl-alt-apostrophe spc ctrl-alt-backslash spc ctrl-alt-slash spc ctrl-alt-less"
A="alt_r-1 alt_r-2 alt_r-3 alt_r-4 alt_r-5 alt_r-6 alt_r-9 alt_r-0 alt_r-e alt_r-bracket_left alt_r-bracket_right alt_r-apostrophe spc alt_r-backslash spc alt_r-slash spc alt_r-less"
TOP="grave_accent 1 2 3 4 5 6 7 8 9 0 minus equal bracket_left spc bracket_right apostrophe backslash m comma dot slash less q w"   # US key names = be ² 1..0 ) - ^ $ ù µ , ; : = < a z
$R type $VM --as be "clear; cat > /tmp/typed-$L.txt
"; w 2
$R type $VM --as be "$L plain: azerty AZERTY 1234567890 &é\"'(§è!çà ù µ , ; : = ) -
" --delay 0.2
$R type $VM --as be "$L LCtrl+LAlt: "; $R keys $VM "$K" --delay 0.3; $R keys $VM ret
$R type $VM --as be "$L AltGr: "; $R keys $VM "$A" --delay 0.3; $R keys $VM ret
$R type $VM --as be "$L Caps+LCtrl+LAlt: "; $R keys $VM caps_lock; $R keys $VM "$K" --delay 0.3; $R keys $VM caps_lock; $R keys $VM ret
$R type $VM --as be "$L RCtrl+LAlt 2 e: "; $R keys $VM "ctrl_r-alt-2 ctrl_r-alt-e" --delay 0.3; $R keys $VM ret
$R type $VM --as be "$L Caps top/punct keys: "; $R keys $VM caps_lock; $R keys $VM "$TOP" --delay 0.25; $R keys $VM caps_lock; $R keys $VM ret
$R type $VM --as be "$L Caps+Shift same keys: "; $R keys $VM caps_lock; for k in $TOP; do [ "$k" = spc ] && $R keys $VM spc || $R keys $VM "shift-$k"; done; $R keys $VM caps_lock; $R keys $VM ret
$R type $VM --as be "$L Caps+AltGr: "; $R keys $VM caps_lock; $R keys $VM "$A" --delay 0.3; $R keys $VM caps_lock; $R keys $VM ret
$R type $VM --as be "$L order Ctrl+Alt 2 e x8: "; for i in 1 2 3 4 5 6 7 8; do $R keys $VM "ctrl-alt-2 ctrl-alt-e" --delay 0.15; done; $R keys $VM ret
$R keys $VM ctrl-d; w 2
$R type $VM --as be "wget -q --post-file=/tmp/typed-$L.txt http://10.0.2.2:8001/typed-$L.txt -O /dev/null; cat /tmp/typed-$L.txt
"; w 6
