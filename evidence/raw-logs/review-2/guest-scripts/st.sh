#!/bin/bash
# state of the current session ($1 = label)
for d in cinnamon gnome; do gsettings set org.$d.desktop.session idle-delay 0 2>/dev/null; gsettings set org.$d.desktop.screensaver lock-enabled false 2>/dev/null; done
{ id; echo "dconf user db: $(ls -la ~/.config/dconf/ 2>&1 | tail -n +2)"; echo "dconf dump cinnamon input-sources: [$(dconf dump /org/cinnamon/desktop/input-sources/ 2>&1)]"; echo "dconf dump gnome input-sources: [$(dconf dump /org/gnome/desktop/input-sources/ 2>&1)]"; echo "dconf libgnomekbd: [$(dconf dump /org/gnome/libgnomekbd/ 2>&1)]"
  bash /tmp/kbstate.sh "$1"; setxkbmap -query; gsettings get org.cinnamon.desktop.input-sources xkb-options 2>&1; gsettings get org.gnome.desktop.input-sources xkb-options; } > /tmp/st-$1.txt 2>&1
wget -q --post-file=/tmp/st-$1.txt http://10.0.2.2:8001/st-$1.txt -O /dev/null; echo STDONE
