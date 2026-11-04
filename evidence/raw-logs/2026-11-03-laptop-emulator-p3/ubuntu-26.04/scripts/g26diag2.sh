#!/bin/bash
# g26diag2.sh: compare the keymap GNOME really uses with what libxkbcommon compiles. Read-only (installs x11-xkb-utils).
U=http://10.0.2.2:8001; O=/tmp/g26-diag2.txt
{
echo "--- diag2 $(date -u +%H:%M:%SZ)"
echo "== xkbcli, both options: AE01 and AC01"
xkbcli compile-keymap --layout be --options caps:be_windows,be_azerty:accents 2>/dev/null | grep -A3 -E 'key <(AE01|AE02|AC01)>' | grep -E 'key|type|symbols'
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q x11-xkb-utils 2>&1 | tail -1
echo "== Xwayland keymap (set by mutter), DISPLAY=$DISPLAY"
xkbcomp -xkb "$DISPLAY" /tmp/xw.xkb 2>/dev/null; grep -E 'xkb_symbols' /tmp/xw.xkb; grep -A3 -E 'key <(AE01|AE02|AC01)>' /tmp/xw.xkb | grep -E 'key|type|symbols'
setxkbmap -query 2>&1
echo "== mutter keymap via gdbus (layouts/options as mutter got them)"
gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval 'global.backend.get_keymap_layout_group ? "x" : "y"' 2>&1 | head -2
echo "== localed"; localectl status 2>&1
echo "== ibus"; ibus engine 2>&1; ps -eo pid,args | grep -E 'ibus-daemon|ibus-engine' | grep -v grep
} > $O 2>&1
wget -q --post-file=$O $U/g26-diag2.txt -O /dev/null; echo "uploaded $O"
