#!/bin/bash
# In a fresh session: no screensaver, record state
for d in cinnamon gnome; do gsettings set org.$d.desktop.session idle-delay 0 2>/dev/null; gsettings set org.$d.desktop.screensaver lock-enabled false 2>/dev/null; done
{ id; echo "dconf user db: $(ls -la ~/.config/dconf/ 2>&1 | tail -n +2)"; bash /tmp/kbstate.sh "$1"; setxkbmap -query; gsettings get org.cinnamon.desktop.input-sources xkb-options 2>&1; gsettings get org.gnome.desktop.input-sources xkb-options; } > /tmp/st-$1.txt 2>&1
wget -q --post-file=/tmp/st-$1.txt http://10.0.2.2:8001/st-$1.txt -O /dev/null; echo GM2DONE
