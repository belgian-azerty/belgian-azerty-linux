#!/bin/bash
# As tester. $1 = label, $2 = LANG. Cinnamon 6.6 on Xvfb, input sources [be]; print what Cinnamon put into the X keymap.
L=$1; O=/out/$L; mkdir -p $O
export LANG=$2 LANGUAGE= LC_ALL= DISPLAY=:7 XDG_SESSION_TYPE=x11 XDG_CURRENT_DESKTOP=X-Cinnamon
Xvfb :7 -screen 0 1280x800x24 >/dev/null 2>&1 & sleep 2
dbus-run-session -- bash -c '
gsettings set org.cinnamon.desktop.input-sources sources "[(\"xkb\", \"be\")]"
echo "LANG=$LANG sources=$(gsettings get org.cinnamon.desktop.input-sources sources)"
echo "before cinnamon: $(setxkbmap -query | grep -E "layout|variant" | tr -s " " | xargs)"
cinnamon --replace > '"$O"'/cinnamon.log 2>&1 &
for i in $(seq 1 60); do grep -q "Cinnamon took\|Cinnamon started" '"$O"'/cinnamon.log 2>/dev/null && break; sleep 1; done; sleep 4
echo "after cinnamon:  $(setxkbmap -query | grep -E "layout|variant" | tr -s " " | xargs)"
python3 /probe/locale_lookup.py | head -3
' > $O/result.txt 2>&1
cat $O/result.txt
