#!/bin/bash
# open the pkexec dialog (line "p"), one Caps Lock press held $1 ms, Esc, then the probe row
H=$1
python3 <workdir>/work/rig/qemu_rig.py keys mint "p ret" >/dev/null; sleep 25
python3 <workdir>/work/rig/qemu_rig.py shot mint <workdir>/work/ev/mint-dialog-$H.png >/dev/null
python3 <workdir>/work/rig/qemu_rig.py hmp mint "sendkey caps_lock $H" >/dev/null; sleep $(( H/1000 + 3 ))
python3 <workdir>/work/rig/qemu_rig.py keys mint "esc" >/dev/null; sleep 8
<workdir>/work/mrow.sh; sleep 8
echo "hold=$H: $(tail -2 <workdir>/work/uploads/m96.log | tr '\n' ' ')"
