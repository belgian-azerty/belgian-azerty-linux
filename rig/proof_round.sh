#!/bin/bash
# Record the same key presses with keyd OFF then ON, on the stock Belgian layout, into xev logs and typed-text files.
set -u
cd "$(dirname "$0")/.."
R="python3 rig/qemu_rig.py"; VM=mint3
w() { timeout "$1" tail -f /dev/null; }
K="ctrl-alt-1 ctrl-alt-2 ctrl-alt-3 ctrl-alt-4 ctrl-alt-5 ctrl-alt-6 ctrl-alt-9 ctrl-alt-0 ctrl-alt-e ctrl-alt-bracket_left ctrl-alt-bracket_right ctrl-alt-apostrophe spc ctrl-alt-backslash spc ctrl-alt-slash spc ctrl-alt-less"
A="alt_r-1 alt_r-2 alt_r-3 alt_r-4 alt_r-5 alt_r-6 alt_r-9 alt_r-0 alt_r-e alt_r-bracket_left alt_r-bracket_right alt_r-apostrophe spc alt_r-backslash spc alt_r-slash spc alt_r-less"
S="shift-ctrl-alt-1 shift-ctrl-alt-2 shift-ctrl-alt-3 shift-ctrl-alt-4 shift-ctrl-alt-5 shift-ctrl-alt-6 shift-ctrl-alt-9 shift-ctrl-alt-0 shift-ctrl-alt-e"
SA="shift-alt_r-1 shift-alt_r-2 shift-alt_r-3 shift-alt_r-4 shift-alt_r-5 shift-alt_r-6 shift-alt_r-9 shift-alt_r-0 shift-alt_r-e"
round() {  # $1 = on|off
  $R click $VM 400 300 >/dev/null; w 2
  $R type $VM "clear; setxkbmap be -option ''; setxkbmap -query | tr '\n' ' '; systemctl is-active keyd; xev -event keyboard -geometry 300x200+800+80 > /tmp/xev-$1.txt 2>&1 &
"; w 6
  $R click $VM 950 220 >/dev/null; w 2
  $R keys $VM 'ctrl-alt-2 ctrl-alt-e ctrl-alt-t alt_r-2 2 caps_lock ctrl-alt-2 caps_lock' --delay 0.8; w 2
  $R click $VM 400 300 >/dev/null; w 2
  $R type $VM "kill %1; cat > /tmp/typed-$1.txt
"; w 2
  $R type $VM "keyd $1. LCtrl+LAlt+ 1 2 3 4 5 6 9 0 e ^ \$ ù µ = < : "; $R keys $VM "$K" --delay 0.3; $R keys $VM ret
  $R type $VM "keyd $1. AltGr+ 1 2 3 4 5 6 9 0 e ^ \$ ù µ = < : "; $R keys $VM "$A" --delay 0.3; $R keys $VM ret
  $R type $VM "keyd $1. CapsLock ON, LCtrl+LAlt+ same keys : "; $R keys $VM caps_lock; $R keys $VM "$K" --delay 0.3; $R keys $VM caps_lock; $R keys $VM ret
  $R type $VM "keyd $1. Shift+LCtrl+LAlt+ 1 2 3 4 5 6 9 0 e : "; $R keys $VM "$S" --delay 0.3; $R keys $VM ret
  $R type $VM "keyd $1. Shift+AltGr+ 1 2 3 4 5 6 9 0 e : "; $R keys $VM "$SA" --delay 0.3; $R keys $VM ret
  $R type $VM "keyd $1. RCtrl+LAlt+ 2 e : "; $R keys $VM "ctrl_r-alt-2 ctrl_r-alt-e" --delay 0.3; $R keys $VM ret
  $R type $VM "keyd $1. plain: azerty AZERTY 1234567890 é è ç à ù µ , ; : = ( )
" --delay 0.25
  $R keys $VM caps_lock; $R type $VM "keyd $1. caps: azerty 1234567890 " --delay 0.25; $R keys $VM caps_lock; $R keys $VM ret
  $R keys $VM ctrl-d; w 2
  $R shot $VM shots/proof-$1.png >/dev/null
  $R type $VM "wget -q --post-file=/tmp/typed-$1.txt http://10.0.2.2:8001/typed-$1.txt -O /dev/null; wget -q --post-file=/tmp/xev-$1.txt http://10.0.2.2:8001/xev-$1.txt -O /dev/null; echo up
"; w 5
}
$R click $VM 400 300 >/dev/null; w 2
$R type $VM "sudo systemctl stop keyd
"; w 4
round off
$R type $VM "sudo systemctl start keyd
"; w 6
round on
