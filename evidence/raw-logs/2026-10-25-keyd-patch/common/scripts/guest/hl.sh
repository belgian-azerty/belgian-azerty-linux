#!/bin/bash
# hl.sh LABEL: kernel key log (keylog.py, root) running while the typed lines are captured until Ctrl+D (like t.sh);
# uploads out-LABEL.txt, keylog-LABEL.txt, state-LABEL.txt and signals ready-LABEL / done-LABEL to the host
L=$1; D=/tmp/swap; U=http://10.0.2.2:8011; mkdir -p $D
up() { wget -q --post-file="$1" "$U/$2" -O /dev/null; }
sudo python3 /tmp/keylog.py > $D/keylog-$L.txt 2>&1 &
sleep 1.5
st() { echo "$1 $(date -u +%T.%N | cut -c1-12)Z keyd=$(systemctl is-active keyd) keyd_pid=$(pidof keyd.rvaiya) ibus=$(pgrep -x ibus-daemon >/dev/null && echo on || echo off) session=${XDG_SESSION_TYPE:-?} desktop=${XDG_CURRENT_DESKTOP:-?} load=$(cut -d' ' -f1-3 /proc/loadavg)"; }
st start > $D/state-$L.txt
up $D/state-$L.txt ready-$L
clear
cat > $D/out-$L.txt
sleep 0.5; sudo pkill -f keylog.py
st end >> $D/state-$L.txt
up $D/out-$L.txt out-$L.txt; up $D/keylog-$L.txt keylog-$L.txt; up $D/state-$L.txt state-$L.txt
up $D/state-$L.txt done-$L
clear; echo "hl done $L"
