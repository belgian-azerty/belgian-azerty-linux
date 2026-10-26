#!/bin/bash
# Desktop variant of the sweep recorder (text console switching does not work in this Wayland live session):
# record keyd-off for 660 s, then keyd-on for 660 s, upload both, unlock the session. Runs detached.
up() { wget -q --post-file="$1" "http://10.0.2.2:8001/$2" -O /dev/null; }
sudo systemctl stop keyd; sleep 2; echo "keyd $(systemctl is-active keyd)" > /tmp/zsw-state.txt
sudo timeout 660 keyd.rvaiya -m -t > /tmp/mon-z-off.txt 2>&1 & sleep 3; up /tmp/zsw-state.txt zsw-off-started; wait
sudo systemctl start keyd; sleep 3; echo "keyd $(systemctl is-active keyd)" >> /tmp/zsw-state.txt
sudo timeout 660 keyd.rvaiya -m -t > /tmp/mon-z-on.txt 2>&1 & sleep 3; up /tmp/zsw-state.txt zsw-on-started; wait
up /tmp/mon-z-off.txt mon-z-off.txt; up /tmp/mon-z-on.txt mon-z-on.txt; sudo loginctl unlock-sessions; up /tmp/zsw-state.txt zsw-done
