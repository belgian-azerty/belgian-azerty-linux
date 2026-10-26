#!/bin/bash
# Rerun of the keyd-off half of the desktop sweep recorder: 420 s with keyd stopped, then keyd started again.
up() { wget -q --post-file="$1" "http://10.0.2.2:8001/$2" -O /dev/null; }
sudo systemctl stop keyd; sleep 2; echo "keyd $(systemctl is-active keyd)" > /tmp/zsw2-state.txt
sudo setsid sh -c "exec timeout 420 keyd.rvaiya -m -t > /tmp/mon-z-off2.txt 2>&1" < /dev/null &
sleep 3; pgrep -af 'keyd.rvaiya -m' >> /tmp/zsw2-state.txt; up /tmp/zsw2-state.txt zsw2-off-started
sleep 425
sudo systemctl start keyd; sleep 3; echo "keyd $(systemctl is-active keyd)" >> /tmp/zsw2-state.txt
up /tmp/mon-z-off2.txt mon-z-off2.txt; sudo loginctl unlock-sessions; up /tmp/zsw2-state.txt zsw2-done
