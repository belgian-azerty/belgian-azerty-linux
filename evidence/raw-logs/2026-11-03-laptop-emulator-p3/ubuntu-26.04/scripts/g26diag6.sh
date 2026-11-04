#!/bin/bash
# g26diag6.sh: does GNOME pick up xkb-options after a layout switch / a fresh rebuild? Which keys does the schema have?
U=http://10.0.2.2:8001; O=/tmp/g26-diag6.txt
exec > $O 2>&1
up() { wget -q -T 5 --post-file=$O $U/g26-diag6.txt -O /dev/null; }
wl() { sleep 3; timeout --foreground -k 2 8 xkbcli dump-keymap-wayland > /tmp/wl.xkb 2>/tmp/wl.err < /dev/null; echo "  dump exit $?: $(grep -m1 -E 'xkb_symbols' /tmp/wl.xkb) be_capslock=$(grep -c be_capslock /tmp/wl.xkb)"; up; }
G=org.gnome.desktop.input-sources
echo "--- diag6 $(date -u +%H:%M:%SZ)"
echo "== schema keys"; gsettings list-recursively $G
echo "== dconf user db"; dconf dump /org/gnome/desktop/input-sources/
echo "== locks"; ls /etc/dconf/db/ 2>&1; cat /etc/dconf/db/*.d/locks/* 2>/dev/null
echo "== 1) two sources be,us"; gsettings set $G sources "[('xkb', 'be'), ('xkb', 'us')]"; wl
echo "== 2) back to be only"; gsettings set $G sources "[('xkb', 'be')]"; wl
echo "== 3) options reset then set again"; gsettings reset $G xkb-options; sleep 2; gsettings set $G xkb-options "['caps:be_windows', 'be_azerty:accents']"; wl
echo "== 4) gnome-shell version and keyboard code hints"
gnome-shell --version
strings /usr/lib/x86_64-linux-gnu/mutter-18/libmutter-18.so.0 2>/dev/null | grep -iE 'xkb-options|xkb_options' | head -5
ls /usr/lib/x86_64-linux-gnu/ | grep -i mutter
gresource list /usr/lib/gnome-shell/libshell-18.so 2>/dev/null | grep -i keyboard | head -5
for r in $(gresource list /usr/lib/gnome-shell/libshell-18.so 2>/dev/null | grep -E 'misc/keyboardManager.js|ui/status/keyboard.js'); do echo "-- $r"; gresource extract /usr/lib/gnome-shell/libshell-18.so $r | grep -nE 'xkb-options|xkbOptions|XKB_OPTIONS|set_keymap|setKeymap' | head -20; done
echo "== done"; up
