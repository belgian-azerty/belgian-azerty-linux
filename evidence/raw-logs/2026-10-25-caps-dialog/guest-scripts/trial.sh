#!/bin/bash
# trial HOLD_MS: open the pkexec dialog, one Caps Lock press held HOLD_MS, Esc, then the probe row
H=$1
python3 <workdir>/work/rig/qemu_rig.py type z "p
" >/dev/null; sleep 14
python3 <workdir>/work/rig/qemu_rig.py hmp z "sendkey caps_lock $H" >/dev/null; sleep $(( H/1000 + 3 ))
python3 <workdir>/work/rig/qemu_rig.py keys z "esc" >/dev/null; sleep 6
<workdir>/work/row.sh >/dev/null; sleep 6
echo "hold=$H: $(tail -1 <workdir>/work/uploads/rec.log)"
