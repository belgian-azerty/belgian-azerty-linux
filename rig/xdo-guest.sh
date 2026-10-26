#!/bin/bash
# xdo-guest.sh LABEL KEYD N DELAY_MS: in a focused guest terminal of an X11 session. Types N lines of "@€" x8 with
# "xdotool type" (X11 XTEST: works on keysyms, never passes through keyd), N lines of xdotool key ISO_Level3_Shift+2/e
# and N lines of xdotool key ctrl+alt+2/e, then pastes one line from the clipboard (xclip, if present). Uploads
# out-/keylog-/state-LABEL like swap-guest.sh.
L=$1; K=$2; N=${3:-20}; DL=${4:-12}
D=/tmp/swap; U=http://10.0.2.2:8001; mkdir -p $D
up() { wget -q --post-file="$1" "$U/$2" -O /dev/null; }
command -v xdotool >/dev/null && command -v xclip >/dev/null ||
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y xdotool xclip > $D/xdo-apt-$L.log 2>&1
if [ "$K" = on ]; then sudo systemctl start keyd; else sudo systemctl stop keyd; fi
sudo python3 /tmp/keylog.py > $D/keylog-$L.txt 2>&1 &
sleep 1
AG=; CA=; T=
for _ in 1 2 3 4 5 6 7 8; do AG="$AG ISO_Level3_Shift+2 ISO_Level3_Shift+e"; CA="$CA ctrl+alt+2 ctrl+alt+e"; T="$T@€"; done
echo "start $(date -u +%T)Z keyd=$(systemctl is-active keyd) xdotool=$(dpkg-query -W -f='${Version}' xdotool 2>/dev/null) xclip=$(command -v xclip >/dev/null && echo yes || echo no) N=$N delay=${DL}ms session=$XDG_SESSION_TYPE" > $D/state-$L.txt
( sleep 2
  for _ in $(seq "$N"); do xdotool type --delay "$DL" "$T"; xdotool key Return; done
  for _ in $(seq "$N"); do xdotool key --delay "$DL" $AG Return; done
  for _ in $(seq "$N"); do xdotool key --delay "$DL" $CA Return; done
  if command -v xclip >/dev/null; then printf 'paste:%s' "$T" | xclip -selection clipboard; xdotool key ctrl+shift+v Return; fi
  sleep 1; xdotool key ctrl+d ) > $D/xdo-$L.err 2>&1 &
clear
cat > $D/out-$L.txt
sleep 0.5; sudo pkill -f keylog.py
grep -c . $D/out-$L.txt >> $D/state-$L.txt
up $D/out-$L.txt out-$L.txt; up $D/keylog-$L.txt keylog-$L.txt; up $D/state-$L.txt state-$L.txt; up $D/xdo-$L.err xdo-$L.err
up $D/state-$L.txt done-$L
clear
