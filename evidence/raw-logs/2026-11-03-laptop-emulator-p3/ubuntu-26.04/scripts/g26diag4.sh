#!/bin/bash
# g26diag4.sh: the keymap the GNOME compositor really sends to Wayland programs (xkbcli dump-keymap-wayland),
# with our options, with a standard option only, and back.
U=http://10.0.2.2:8001; O=/tmp/g26-diag4.txt
wl() { sleep 3; timeout 10 xkbcli dump-keymap-wayland 2>&1 > /tmp/wl.xkb | head -3; grep -m1 -E 'xkb_symbols' /tmp/wl.xkb; grep -A3 -E 'key <AE01>' /tmp/wl.xkb | grep -E 'type|symbols' | head -3; echo "be_capslock mentions: $(grep -c be_capslock /tmp/wl.xkb)"; }
{
echo "--- diag4 $(date -u +%H:%M:%SZ) WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
xkbcli --help 2>&1 | grep -iE 'wayland|dump'
echo "== now: $(gsettings get org.gnome.desktop.input-sources xkb-options)"; wl
cp /tmp/wl.xkb /tmp/wl-ours.xkb
gsettings set org.gnome.desktop.input-sources xkb-options "['kpdl:comma']"
echo "== only kpdl:comma"; wl; echo "kpdl in keymap: $(grep -c -i 'kpdl\|KPDL' /tmp/wl.xkb)"; grep -A2 'key <KPDL>' /tmp/wl.xkb | head -3
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:be_windows', 'be_azerty:accents']"
echo "== back to ours"; wl
echo "== mutter/gnome-shell messages, whole boot"
journalctl --user -b --no-pager 2>/dev/null | grep -iE 'gnome-shell|mutter' | grep -iE 'xkb|keymap|layout|option|input' | tail -20
} > $O 2>&1
wget -q --post-file=$O $U/g26-diag4.txt -O /dev/null; wget -q --post-file=/tmp/wl-ours.xkb $U/g26-wl-ours.xkb -O /dev/null; echo "uploaded $O"
