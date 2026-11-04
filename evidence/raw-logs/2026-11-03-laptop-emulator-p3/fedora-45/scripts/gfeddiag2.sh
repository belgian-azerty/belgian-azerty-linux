#!/bin/bash
# gfeddiag2.sh: is it our /etc/xkb that makes localed refuse even plain "be"? Moves /etc/xkb aside for a moment
# (throwaway live VM), tries, and puts it back.
U=http://10.0.2.2:8001; O=/tmp/gfed-diag2.txt
exec > $O 2>&1
try() { echo "== localectl set-x11-keymap $*"; sudo localectl set-x11-keymap "$@"; echo "exit $?: $(localectl status | grep -E 'X11 (Layout|Options)' | tr -s ' ' | tr '\n' ';')"; }
echo "--- diag2 $(date -u +%H:%M:%SZ)"
echo "== with our /etc/xkb"; try us pc105
sudo mv /etc/xkb /etc/xkb.rigoff
echo "== /etc/xkb moved aside"; try be pc105; try us pc105
sudo mv /etc/xkb.rigoff /etc/xkb
echo "== /etc/xkb back: $(ls /etc/xkb/rules /etc/xkb/symbols | tr '\n' ' ')"; try be pc105
echo "== head of our rules file"; head -n 12 /etc/xkb/rules/evdev
echo "== localed binary and xkbcommon"; ls -l /usr/lib/systemd/systemd-localed; ldd /usr/lib/systemd/systemd-localed | grep -i xkb; rpm -q systemd
strings /usr/lib/systemd/systemd-localed | grep -iE 'xkb_context|include|/usr/share/X11|xkeyboard' | head -10
echo "== localed journal (last 6)"; sudo journalctl -b -u systemd-localed --no-pager | tail -6
wget -q -T 5 --post-file=$O $U/gfed-diag2.txt -O /dev/null
