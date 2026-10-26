#!/bin/bash
# Re-review copy of rig/durability-guest.sh, adapted: Debian keyd binary is keyd.rvaiya; Cinnamon or GNOME apps;
# the packaged be-azerty-fix command. Same protocol with rig/durability-host.py (probe lines typed by the host).
F=/tmp/zdur.txt; N=0; HOST=http://10.0.2.2:8001
up()    { wget -q --post-file="$1" "$HOST/$2" -O /dev/null; }
probe() { N=$((N+1)); echo "$1" > /tmp/step; up /tmp/step "dur-step-$N"; IFS= read -r line; echo "$line" >> $F; }
note()  { echo "  $*" >> $F; }
state() { bash /tmp/kbstate.sh "$1" >> $F; }
sudo -v || exit 1; IFS= read -r -t 15 _pw   # swallow the password line the host types
( while sleep 50; do sudo -n true; done ) & KEEP=$!
if gsettings list-schemas | grep -qx org.cinnamon.desktop.input-sources; then DE=cinnamon; else DE=gnome; fi
rm -f $F; echo "=== durability $(date -u +%FT%TZ) $(lsb_release -ds) $DE live=$(findmnt -no FSTYPE /) ===" > $F
state start;                                                     probe "A0 baseline"
sudo systemctl stop keyd;  note "keyd after stop: $(systemctl is-active keyd)";      probe "C1 keyd stopped (expected: plain and AltGr fine, Ctrl+Alt not @E)"
sudo systemctl start keyd; sleep 2; note "keyd after start: $(systemctl is-active keyd)"; probe "C2 keyd started again"
P1=$(pidof keyd.rvaiya); sudo kill -9 $P1; sleep 4; note "keyd 4 s after kill -9 of pid $P1: $(systemctl is-active keyd), new pid $(pidof keyd.rvaiya)"; probe "C3 4 s after kill -9 keyd"
echo 'this is not a valid keyd config [[[' | sudo tee /etc/keyd/broken.conf >/dev/null; sudo keyd.rvaiya reload >/tmp/rl.txt 2>&1; note "reload rc=$? $(head -c 200 /tmp/rl.txt)"; sleep 2
note "keyd with a broken extra config: $(systemctl is-active keyd)";                 probe "C4 broken extra config + keyd reload"
sudo rm -f /etc/keyd/broken.conf; sudo keyd.rvaiya reload >/dev/null 2>&1; sleep 2;         probe "C5 broken config removed + reload"
if [ $DE = cinnamon ]; then
  (xed >/dev/null 2>&1 &); sleep 15; (cinnamon-settings keyboard >/dev/null 2>&1 &); sleep 25
  gsettings set org.cinnamon.desktop.interface clock-show-seconds true; sleep 2; gsettings set org.cinnamon.desktop.interface clock-show-seconds false
  (nemo >/dev/null 2>&1 &); sleep 20; state after-apps
  pkill -x xed; pkill -f cinnamon-settings; pkill -x nemo; sleep 5
else
  (gnome-text-editor >/dev/null 2>&1 &); sleep 15; (gnome-control-center keyboard >/dev/null 2>&1 &); sleep 20
  gsettings set org.gnome.desktop.interface clock-show-seconds true; sleep 2; gsettings set org.gnome.desktop.interface clock-show-seconds false
  (nautilus >/dev/null 2>&1 &); sleep 20; state after-apps
  pkill -f gnome-text-editor; pkill -f gnome-control-center; pkill -x nautilus; sleep 5
fi
probe "B1 after opening an editor, keyboard settings, files (closed again) and toggling an unrelated setting"
sudo apt-get install -y --reinstall keyboard-configuration console-setup > /tmp/reinst.log 2>&1; note "apt reinstall rc=$?"
state after-reinstall;                                            probe "A3 after apt reinstall of keyboard-configuration + console-setup"
if [ $DE = cinnamon ]; then
  gsettings set org.cinnamon.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'be')]"; gsettings set org.gnome.libgnomekbd.keyboard layouts "['us', 'be']"; sleep 5
else gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'be')]"; sleep 3; fi
state planted-us;                                                 probe "A2a US planted first in the desktop sources (expected: US typing)"
sudo be-azerty-fix system > /tmp/fix-sys.log 2>&1; note "fix system rc=$?"; sleep 3
state after-fix;                                                  probe "A2b after sudo be-azerty-fix system"
sudo DECIMAL=comma be-azerty-fix system > /tmp/fix-comma.log 2>&1; note "fix comma rc=$?"; state comma
sudo be-azerty-fix system > /tmp/fix-period.log 2>&1; note "fix period rc=$?"; state period-again; probe "A4 after Comma then back to Period"
kill $KEEP
for f in zdur.txt reinst.log fix-sys.log fix-comma.log fix-period.log; do up /tmp/$f "zi-$f"; done
echo done > /tmp/step; up /tmp/step dur-done; echo "durability finished: $F"
