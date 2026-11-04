#!/bin/bash
# gtwkde2.sh: get Plasma to apply kxkbrc without a new login; dumps the compositor keymap after each try.
U=http://10.0.2.2:8001; O=/tmp/gtw-kde2.txt
exec > $O 2>&1
wl() { sleep 3; timeout --foreground -k 2 8 xkbcli dump-keymap-wayland > /tmp/wl.xkb 2>/tmp/wl.err < /dev/null; echo "  keymap: $(grep -m1 xkb_symbols /tmp/wl.xkb) be_capslock=$(grep -c be_capslock /tmp/wl.xkb)"; }
echo "--- kde2 $(date -u +%H:%M:%SZ)"; cat ~/.config/kxkbrc
echo "== now"; wl
echo "== dbus-send reloadConfig: $(dbus-send --session --type=signal /Layouts org.kde.keyboard.reloadConfig; echo exit $?)"; wl
Q=$(command -v qdbus6 || command -v qdbus-qt6 || command -v qdbus); echo "qdbus: $Q"
echo "== KWin reconfigure"; $Q org.kde.KWin /KWin reconfigure 2>&1; wl
echo "== keyboard layouts dbus"; $Q org.kde.keyboard /Layouts 2>&1 | head -10; $Q org.kde.keyboard /Layouts getLayoutsList 2>&1 | head -5
curl -s -m 5 -T $O $U/gtw-kde2.txt >/dev/null
