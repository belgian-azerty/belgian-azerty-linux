#!/bin/bash
# short-probe.sh VM LABEL: in a focused terminal: plain, AltGr 2 e, Ctrl+Alt 2 e, Caps row, numpad 1 dec 5 -> up/typed-LABEL.txt (+ kbstate)
cd "$(dirname "$0")"; VM=$1; L=$2; R="python3 qemu_rig.py"
TOP="grave_accent 1 2 3 minus equal apostrophe m comma q"   # be: ² 1 2 3 ) - ù , ; a
$R type $VM --as be "clear; cat > /tmp/typed-$L.txt
"; timeout 2 tail -f /dev/null
$R type $VM --as be "$L plain: azerty é | AltGr 2 e: "; $R keys $VM "alt_r-2 alt_r-e" --delay 0.3
$R type $VM --as be " | CtrlAlt 2 e: "; $R keys $VM "ctrl-alt-2 ctrl-alt-e" --delay 0.3
$R type $VM --as be " | Caps ² 1 2 3 ) - ù , ; a: "; $R keys $VM caps_lock; $R keys $VM "$TOP" --delay 0.3; $R keys $VM caps_lock
$R type $VM --as be " | numpad 1 dec 5: "; $R keys $VM "kp_1 kp_decimal kp_5" --delay 0.3; $R keys $VM ret
$R keys $VM ctrl-d; timeout 2 tail -f /dev/null
$R type $VM --as be 'bash /tmp/kbstate.sh '"$L"' >> /tmp/typed-'"$L"'.txt 2>&1; { setxkbmap -query | grep options; gsettings get org.cinnamon.desktop.input-sources xkb-options; } >> /tmp/typed-'"$L"'.txt 2>&1; wget -q --post-file=/tmp/typed-'"$L"'.txt http://10.0.2.2:8001/typed-'"$L"'.txt -O /dev/null
'
