#!/bin/bash
# swap-guest.sh LABEL KEYD IBUS [box3|box4 [VAR=VALUE ...]]: in a focused terminal of the guest. Puts keyd (on|off) and ibus (on|off) in the
# asked state, logs every kernel key event (keylog.py, as root), captures the typed lines until Ctrl+D, uploads
# out-LABEL.txt, keylog-LABEL.txt, state-LABEL.txt to the host and signals ready-LABEL / done-LABEL.
# Without box3/box4 the lines are typed into this terminal (cat); with it into typebox.py (GTK 3 or 4) started with
# the given environment, e.g. box4 GTK_IM_MODULE=simple. Needs /tmp/keylog.py (+ /tmp/typebox.py) and
# passwordless sudo (test VM only).
L=$1; K=$2; I=$3; APP=${4:-}; shift 4 2>/dev/null || shift $#
D=/tmp/swap; U=http://10.0.2.2:8001; mkdir -p $D
up() { wget -q --post-file="$1" "$U/$2" -O /dev/null; }
if [ "$K" = on ]; then sudo systemctl start keyd; else sudo systemctl stop keyd; fi
if [ "$I" = off ]; then
  ibus exit >/dev/null 2>&1; sleep 2
else
  pgrep -x ibus-daemon >/dev/null || { (setsid ibus-daemon -drx >/dev/null 2>&1 &); sleep 3; }
fi
sleep 1
lag0=$(sudo journalctl -b --no-pager -q 2>/dev/null | grep -c 'lagging behind')
sudo python3 /tmp/keylog.py > $D/keylog-$L.txt 2>&1 &
sleep 1
st() { echo "$1 app=${APP:-terminal} env=[$*] $(date -u +%T.%N | cut -c1-12)Z keyd=$(systemctl is-active keyd) ibus=$(pgrep -x ibus-daemon >/dev/null && echo on || echo off) session=${XDG_SESSION_TYPE:-?} desktop=${XDG_CURRENT_DESKTOP:-?} gtk_im=${GTK_IM_MODULE:-unset} sync=${IBUS_ENABLE_SYNC_MODE:-unset} engine=$(ibus engine 2>/dev/null) load=$(cut -d' ' -f1-3 /proc/loadavg)"; }
ENVS="$*"
st start $ENVS > $D/state-$L.txt
if [ -n "$APP" ]; then
  : > $D/out-$L.txt
  env "$@" python3 /tmp/typebox.py $D/out-$L.txt "${APP#box}" 2> $D/app-$L.err & AP=$!
  sleep 3
  up $D/state-$L.txt ready-$L
  wait $AP
else
  up $D/state-$L.txt ready-$L
  clear
  cat > $D/out-$L.txt
fi
sleep 0.5; sudo pkill -f keylog.py
st end $ENVS >> $D/state-$L.txt
echo "lagging-behind messages during block: $(( $(sudo journalctl -b --no-pager -q 2>/dev/null | grep -c 'lagging behind') - lag0 ))" >> $D/state-$L.txt
up $D/out-$L.txt out-$L.txt; up $D/keylog-$L.txt keylog-$L.txt; up $D/state-$L.txt state-$L.txt
up $D/state-$L.txt done-$L
clear
