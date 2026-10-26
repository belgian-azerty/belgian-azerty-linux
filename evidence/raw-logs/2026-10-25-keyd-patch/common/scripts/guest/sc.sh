#!/bin/bash
# sc.sh LABEL: shortcut test. Key log + (X11 only) window/workspace log every 0.3 s while this terminal captures
# what is typed into it until Ctrl+D. Uploads sc-typed-, keylog-sc-, win-sc- LABEL files, signals ready-sc-/done-sc-
L=$1; D=/tmp/swap; U=http://10.0.2.2:8011; mkdir -p $D
up() { wget -q --post-file="$1" "$U/$2" -O /dev/null; }
sudo python3 /tmp/keylog.py > $D/keylog-sc-$L.txt 2>&1 &
WP=
if [ "$XDG_SESSION_TYPE" = x11 ] && command -v wmctrl >/dev/null; then
  ( while :; do echo "== $(date -u +%T.%N | cut -c1-12)Z desktop $(xdotool get_desktop 2>/dev/null) | $(wmctrl -d | grep '\*')"; wmctrl -l; sleep 0.3; done ) > $D/win-sc-$L.txt 2>&1 &
  WP=$!
else
  echo "no X11 window log (session ${XDG_SESSION_TYPE:-?})" > $D/win-sc-$L.txt
fi
sleep 1.5
up $D/win-sc-$L.txt ready-sc-$L
clear
cat > $D/sc-typed-$L.txt
[ -n "$WP" ] && kill $WP
sleep 0.5; sudo pkill -f keylog.py
up $D/sc-typed-$L.txt sc-typed-$L.txt; up $D/keylog-sc-$L.txt keylog-sc-$L.txt; up $D/win-sc-$L.txt win-sc-$L.txt
up $D/win-sc-$L.txt done-sc-$L
clear; echo "sc done $L"; cat $D/sc-typed-$L.txt
