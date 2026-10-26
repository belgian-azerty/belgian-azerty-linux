#!/bin/bash
# k7.sh LABEL: 5 x (restart keyd, 2 s, one typed line read from this terminal with the key log running).
# Uploads out-LABEL.txt, keylog-LABEL-N.txt, state-LABEL.txt, journal-LABEL.txt; signals ready-LABEL-N, done-LABEL
L=$1; D=/tmp/swap; U=http://10.0.2.2:8011; mkdir -p $D
up() { wget -q --post-file="$1" "$U/$2" -O /dev/null; }
: > $D/out-$L.txt; : > $D/state-$L.txt
clear
for i in 1 2 3 4 5; do
  sudo systemctl restart keyd
  echo "restart $i done $(date -u +%T.%N | cut -c1-12)Z active=$(systemctl is-active keyd) pid=$(pidof keyd.rvaiya)" >> $D/state-$L.txt
  sleep 0.8
  sudo python3 /tmp/keylog.py > $D/keylog-$L-$i.txt 2>&1 &
  sleep 1.2
  echo "line $i ready $(date -u +%T.%N | cut -c1-12)Z active=$(systemctl is-active keyd)" >> $D/state-$L.txt
  up $D/state-$L.txt ready-$L-$i
  IFS= read -r line
  echo "$line" >> $D/out-$L.txt
  sleep 0.5; sudo pkill -f keylog.py; sleep 0.3
  up $D/keylog-$L-$i.txt keylog-$L-$i.txt
done
echo "== final $(date -u +%T)Z is-active: $(systemctl is-active keyd)" >> $D/state-$L.txt
sudo journalctl -u keyd -b --no-pager | tail -30 > $D/journal-$L.txt
up $D/out-$L.txt out-$L.txt; up $D/state-$L.txt state-$L.txt; up $D/journal-$L.txt journal-$L.txt
up $D/state-$L.txt done-$L
clear; echo "k7 done $L"; cat $D/out-$L.txt
