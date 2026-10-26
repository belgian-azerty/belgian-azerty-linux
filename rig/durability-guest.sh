#!/bin/bash
# durability-guest.sh: durability test of the Belgian fix (live session or installed system). Run it in a terminal on
# the desktop (Cinnamon or GNOME), with kbstate.sh in /tmp, while rig/durability-host.py runs on the host. Each step
# changes one thing that could revert the layout or break the keyboard, then asks the host to type a probe line
# (signal: uploads dur-step-N); the line typed back is appended to /tmp/zdur.txt and shows plain, AltGr and Ctrl+Alt
# typing after that step. No fixed delays: the host waits for each signal.
# 2026-10-24 (second review, R2-3): the Debian keyd binary is keyd.rvaiya. The old version called `keyd`, so with the
# packaged keyd `kill -9 $(pidof keyd)` killed nothing and step C3 passed without testing anything. C3 now checks
# that a new keyd process replaced the killed one. Uses the packaged be-azerty-fix (or /tmp/be-azerty-fix.sh).
F=/tmp/zdur.txt; N=0; HOST=http://10.0.2.2:8001
K=$(command -v keyd.rvaiya || command -v keyd); KN=${K##*/}
BAF=$(command -v be-azerty-fix || echo "bash /tmp/be-azerty-fix.sh")
up()    { wget -q --post-file="$1" "$HOST/$2" -O /dev/null; }
probe() { N=$((N+1)); echo "$1" > /tmp/step; up /tmp/step "dur-step-$N"; IFS= read -r line; echo "$line" >> $F; }
note()  { echo "  $*" >> $F; }
state() { bash /tmp/kbstate.sh "$1" >> $F; }
dec()   { case ",$(. /etc/default/keyboard; echo "$XKBOPTIONS")," in *,kpdl:comma,*) echo comma ;; *) echo period ;; esac; }
sudo -v || exit 1; IFS= read -r -t 15 _pw   # swallow the password line the host types
( while sleep 50; do sudo -n true; done ) & KEEP=$!
if gsettings list-schemas | grep -qx org.cinnamon.desktop.input-sources; then DE=cinnamon; else DE=gnome; fi
rm -f $F; echo "=== durability $(date -u +%FT%TZ) $(lsb_release -ds) $DE live=$(findmnt -no FSTYPE /) keyd=$K ===" > $F
for p in belgian-azerty-windows keyd-belgian-windows keyd; do note "$p $(dpkg-query -W -f='${Version}' $p 2>/dev/null)"; done
state start;                                                     probe "A0 baseline"
sudo systemctl stop keyd;  note "keyd after stop: $(systemctl is-active keyd) (0.9.1 expects inactive, not failed)"; probe "C1 keyd stopped (expected: plain and AltGr fine, Ctrl+Alt not @E)"
sudo systemctl start keyd; sleep 2; note "keyd after start: $(systemctl is-active keyd)"; probe "C2 keyd started again"
P1=$(pidof "$KN"); sudo kill -9 $P1; sleep 4; P2=$(pidof "$KN")
if [ -n "$P1" ] && [ -n "$P2" ] && [ "$P1" != "$P2" ]; then v="restarted"; else v="C3 NOT TESTED OR FAILED"; fi
note "keyd 4 s after kill -9 of pid ${P1:-none}: $(systemctl is-active keyd), new pid ${P2:-none}: $v"; probe "C3 4 s after kill -9 keyd"
P1=$(pidof "$KN"); sudo kill $P1; sleep 4; P2=$(pidof "$KN")
note "keyd 4 s after plain kill (SIGTERM, not systemctl) of pid ${P1:-none}: $(systemctl is-active keyd), new pid ${P2:-none}"; probe "C3b 4 s after kill (SIGTERM) keyd"
echo 'this is not a valid keyd config [[[' | sudo tee /etc/keyd/broken.conf >/dev/null; sudo "$K" reload >/tmp/rl.txt 2>&1; note "reload rc=$? $(head -c 200 /tmp/rl.txt)"; sleep 2
note "keyd with a broken extra config: $(systemctl is-active keyd)";                 probe "C4 broken extra config + keyd reload"
sudo rm -f /etc/keyd/broken.conf; sudo "$K" reload >/dev/null 2>&1; sleep 2;         probe "C5 broken config removed + reload"
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
sudo $BAF system > /tmp/fix-sys.log 2>&1; note "fix system rc=$? (decimal now $(dec))"; sleep 3
state after-fix;                                                  probe "A2b after sudo be-azerty-fix system"
sudo DECIMAL=comma $BAF system > /tmp/fix-comma.log 2>&1; note "fix comma rc=$? (decimal now $(dec))"; state comma
sudo DECIMAL=period $BAF system > /tmp/fix-period.log 2>&1; note "fix period rc=$? (decimal now $(dec))"; state period-again; probe "A4 after Comma then back to Period"
sudo DECIMAL=comma $BAF system > /tmp/fix-comma2.log 2>&1; note "fix comma again rc=$? (decimal now $(dec))"
sudo $BAF system > /tmp/fix-rerun.log 2>&1; note "rerun without DECIMAL rc=$? (decimal now $(dec), expected comma): $(grep Choices /tmp/fix-rerun.log)"
state rerun;                                                      probe "A5 rerun without DECIMAL keeps Comma"
kill $KEEP
for f in zdur.txt reinst.log fix-sys.log fix-comma.log fix-period.log fix-comma2.log fix-rerun.log; do up /tmp/$f "zi-$f"; done
echo done > /tmp/step; up /tmp/step dur-done; echo "durability finished: $F"
