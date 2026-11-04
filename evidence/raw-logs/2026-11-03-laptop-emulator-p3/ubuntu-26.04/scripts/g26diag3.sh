#!/bin/bash
# g26diag3.sh: does GNOME drop only our options, or all options? Adds the standard option kpdl:comma for a moment.
U=http://10.0.2.2:8001; O=/tmp/g26-diag3.txt
sym() { sleep 3; xkbcomp -xkb "$DISPLAY" - 2>/dev/null | grep -E 'xkb_symbols'; }
{
echo "--- diag3 $(date -u +%H:%M:%SZ)"
echo "== our options in the registry (evdev.xml / base.xml)"
for f in /usr/share/xkeyboard-config-2/rules/evdev.xml /usr/share/xkeyboard-config-2/rules/base.xml; do echo "$f: $(grep -c -E 'be_windows|be_azerty' $f)"; done
ls -l /usr/share/xkeyboard-config-2/rules/ | grep -E 'evdev|base'
echo "== now: $(gsettings get org.gnome.desktop.input-sources xkb-options)"; sym
gsettings set org.gnome.desktop.input-sources xkb-options "['kpdl:comma']"
echo "== only kpdl:comma"; sym
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:be_windows', 'kpdl:comma']"
echo "== caps:be_windows + kpdl:comma"; sym
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:be_windows', 'be_azerty:accents']"
echo "== back to ours"; sym
echo "== gnome-shell journal since diag3"
journalctl --user -b --no-pager --since "-1min" 2>/dev/null | grep -iE 'xkb|keymap|option' | tail -15
} > $O 2>&1
wget -q --post-file=$O $U/g26-diag3.txt -O /dev/null; echo "uploaded $O"
