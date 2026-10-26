#!/bin/bash
# ydo-guest.sh LABEL KEYD N DELAY_MS: in a focused guest terminal. Types N lines of AltGr+2/E x8 and N lines of
# Ctrl+Alt+2/E x8 with ydotool 0.1.8 (Ubuntu 24.04's version: a uinput typing tool; each "a+b" sequence presses the
# modifiers, the key, and releases them), then one "ydotool type" line, into this terminal; logs kernel key events.
# Uploads out-/keylog-/state-LABEL like swap-guest.sh. Installs ydotool + ydotoold if missing (test VM only).
L=$1; K=$2; N=${3:-20}; DL=${4:-12}
D=/tmp/swap; U=http://10.0.2.2:8001; mkdir -p $D
up() { wget -q --post-file="$1" "$U/$2" -O /dev/null; }
command -v ydotoold >/dev/null || sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ydotool ydotoold > $D/ydo-apt-$L.log 2>&1
if [ "$K" = on ]; then sudo systemctl start keyd; else sudo systemctl stop keyd; fi
pgrep -x ydotoold >/dev/null || { (sudo setsid ydotoold > $D/ydotoold-$L.log 2>&1 &); sleep 2; }
sudo python3 /tmp/keylog.py > $D/keylog-$L.txt 2>&1 &
sleep 1
AG=; CA=
for _ in 1 2 3 4 5 6 7 8; do AG="$AG rightalt+2 rightalt+e"; CA="$CA ctrl+alt+2 ctrl+alt+e"; done
AG="$AG enter"; CA="$CA enter"
echo "start $(date -u +%T)Z keyd=$(systemctl is-active keyd) ydotool=$(dpkg-query -W -f='${Version}' ydotool 2>/dev/null) ydotoold=$(pgrep -x ydotoold >/dev/null && echo running || echo no) N=$N key-delay=${DL}ms session=$XDG_SESSION_TYPE" > $D/state-$L.txt
( sleep 2
  for _ in $(seq "$N"); do sudo ydotool key --key-delay "$DL" $AG; done
  for _ in $(seq "$N"); do sudo ydotool key --key-delay "$DL" $CA; done
  sudo ydotool type --key-delay "$DL" 'type: @{}|'; sudo ydotool key enter
  sleep 1; sudo ydotool key ctrl+d ) > $D/ydo-$L.err 2>&1 &
clear
cat > $D/out-$L.txt
sleep 0.5; sudo pkill -f keylog.py
grep -c . $D/out-$L.txt >> $D/state-$L.txt
up $D/out-$L.txt out-$L.txt; up $D/keylog-$L.txt keylog-$L.txt; up $D/state-$L.txt state-$L.txt
[ -f $D/ydo-apt-$L.log ] && up $D/ydo-apt-$L.log ydo-apt-$L.log; up $D/ydo-$L.err ydo-$L.err
up $D/state-$L.txt done-$L
clear
