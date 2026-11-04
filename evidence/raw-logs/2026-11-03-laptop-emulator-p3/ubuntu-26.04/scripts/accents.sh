#!/bin/bash
# accents.sh VM LABEL: Shift+AltGr dead accents (be_azerty:accents) typed into a focused terminal -> up/acc-LABEL.txt
# QEMU key names are US positions: "q" is the AZERTY a. Each dead key is followed by one letter and a space, so no compose sequence stays open.
cd /root/be-rig/rig; VM=$1; L=$2; R="python3 qemu_rig.py"
$R keys $VM "esc esc" --delay 0.3
$R type $VM --as be "clear; cat > /tmp/acc-$L.txt
"; sleep 2
$R type $VM --as be "$L acute+e: "; $R keys $VM "shift-alt_r-apostrophe e spc" --delay 0.5
$R type $VM --as be "grave+a: "; $R keys $VM "shift-alt_r-backslash q spc" --delay 0.5
$R type $VM --as be "tilde+n: "; $R keys $VM "shift-alt_r-slash n spc" --delay 0.5
$R type $VM --as be "acute+spc: "; $R keys $VM "shift-alt_r-apostrophe spc spc" --delay 0.5
$R type $VM --as be "end"; $R keys $VM ret; sleep 1; $R keys $VM ctrl-d; sleep 2
$R type $VM --as be "wget -q --post-file=/tmp/acc-$L.txt http://10.0.2.2:8001/acc-$L.txt -O /dev/null; od -c /tmp/acc-$L.txt | head
"; sleep 4
