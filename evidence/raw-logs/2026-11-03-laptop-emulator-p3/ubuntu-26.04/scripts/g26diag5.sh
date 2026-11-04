#!/bin/bash
# g26diag5.sh: same as diag4 but every step bounded and logged as it goes.
U=http://10.0.2.2:8001; O=/tmp/g26-diag5.txt
exec > $O 2>&1
up() { wget -q -T 5 --post-file=$O $U/g26-diag5.txt -O /dev/null; }
echo "--- diag5 $(date -u +%H:%M:%SZ) WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
xkbcli 2>&1 | grep -iE 'wayland|dump' ; up
wl() { sleep 3; timeout --foreground -k 2 8 xkbcli dump-keymap-wayland > /tmp/wl.xkb 2>/tmp/wl.err < /dev/null; echo "exit $? err: $(head -c 200 /tmp/wl.err)"; grep -m1 -E 'xkb_symbols' /tmp/wl.xkb; grep -A3 -E 'key <AE01>' /tmp/wl.xkb | grep -E 'type|symbols' | head -3; echo "be_capslock mentions: $(grep -c be_capslock /tmp/wl.xkb)"; up; }
echo "== now: $(gsettings get org.gnome.desktop.input-sources xkb-options)"; wl
cp /tmp/wl.xkb /tmp/wl-ours.xkb
gsettings set org.gnome.desktop.input-sources xkb-options "['kpdl:comma']"
echo "== only kpdl:comma"; wl; grep -A2 'key <KPDL>' /tmp/wl.xkb | head -3
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:be_windows', 'be_azerty:accents']"
echo "== back to ours"; wl
echo "== done"; up
wget -q -T 5 --post-file=/tmp/wl-ours.xkb $U/g26-wl-ours.xkb -O /dev/null
