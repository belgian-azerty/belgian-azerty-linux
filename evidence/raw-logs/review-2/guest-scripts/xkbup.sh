#!/bin/bash
# Simulate an xkb-data upgrade inside the guest (plain dpkg -i of xkb-data from the archive) and check the rule survives
T=$1; cd /tmp; up() { wget -q --post-file="$1" "http://10.0.2.2:8001/$2" -O /dev/null; }
{ echo "before: $(grep -c caps:be_windows /usr/share/X11/xkb/rules/evdev) rule line(s)"; echo "# stale" | sudo tee -a /usr/share/X11/xkb/rules/evdev >/dev/null
  apt-get download xkb-data 2>&1 | tail -1; sudo dpkg -i xkb-data_*.deb 2>&1 | tail -3; echo "dpkg rc=$?"
  echo "after: $(grep -c caps:be_windows /usr/share/X11/xkb/rules/evdev) rule line(s), stale line: $(grep -c '^# stale' /usr/share/X11/xkb/rules/evdev)"
  echo "dpkg -V xkb-data: [$(dpkg -V xkb-data)]"; xkbcli compile-keymap --layout be --options caps:be_windows,kpdl:comma >/dev/null 2>/tmp/xe; echo "compile rc=$? $(cat /tmp/xe)"
  setxkbmap -query | grep options; } > $T-xkbup.txt 2>&1; up $T-xkbup.txt $T-xkbup.txt; echo XKBUPDONE
