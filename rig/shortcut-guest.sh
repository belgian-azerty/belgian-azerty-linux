#!/bin/bash
# shortcut-guest.sh LABEL: in a focused guest terminal, for shortcut-check.py. Logs kernel key events and captures what
# is typed into this terminal until Ctrl+D, then uploads sc-LABEL.txt (typed text + keyd's output events).
L=$1; D=/tmp/swap; U=http://10.0.2.2:8001; mkdir -p $D
sudo python3 /tmp/keylog.py > $D/keylog-sc-$L.txt 2>&1 &
sleep 1
wget -q --post-file=/dev/null "$U/ready-sc-$L" -O /dev/null
clear
cat > $D/sc-typed-$L.txt
sleep 0.5; sudo pkill -f keylog.py
{ echo "keyd: $(sha256sum /usr/bin/keyd.rvaiya | cut -c1-16) typed: [$(tr '\n' '|' < $D/sc-typed-$L.txt)]"
  grep 'keyd virtual keyboard' $D/keylog-sc-$L.txt; } > $D/sc-$L.txt
wget -q --post-file=$D/sc-$L.txt "$U/sc-$L.txt" -O /dev/null
wget -q --post-file=$D/sc-$L.txt "$U/done-sc-$L" -O /dev/null
