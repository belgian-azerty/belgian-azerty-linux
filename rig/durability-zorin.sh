#!/bin/bash
# Durability on the installed Zorin 18.1 (VM zi, user test / azerty): keyd stop/kill/broken config, unrelated apps and
# settings, layout-store changes, package reinstall. Needs a focused gnome-terminal on the desktop. Probes go to /tmp/$2.
cd "$(dirname "$0")/.."
R="python3 rig/qemu_rig.py"; VM=${VM:-zi}
w() { timeout "$1" tail -f /dev/null; }
probe() {  # $1 = label, $2 = file; types a line that shows plain, AltGr and Ctrl+Alt behaviour
  $R type $VM --as be "head -n 1 >> /tmp/$2
"; w 2
  $R type $VM --as be "$1 | plain: azerty é | AltGr+2 e: "; $R keys $VM 'alt_r-2 alt_r-e' --delay 0.3; $R type $VM --as be ' | LCtrl+LAlt+2 e: '; $R keys $VM 'ctrl-alt-2 ctrl-alt-e' --delay 0.3; $R keys $VM ret; w 2
}
cmd() { $R type $VM --as be "$1
"; w "${2:-3}"; }
F=zdur.txt
cmd "clear; echo azerty | sudo -S true; rm -f /tmp/$F; bash /tmp/kbstate.sh start >> /tmp/$F" 6
probe 'A0 baseline keyd on' $F
cmd 'sudo systemctl stop keyd; systemctl is-active keyd'
probe 'C1 after systemctl stop keyd' $F
cmd 'sudo systemctl start keyd; systemctl is-active keyd' 4
probe 'C2 after systemctl start keyd' $F
cmd 'sudo kill -9 $(pidof keyd.rvaiya keyd); sleep 4; systemctl is-active keyd' 7
probe 'C3 4 s after kill -9 keyd (service state above)' $F
cmd 'echo "this is not a valid keyd config [[[" | sudo tee /etc/keyd/broken.conf; sudo $(command -v keyd.rvaiya || command -v keyd) reload; sleep 1; systemctl is-active keyd' 5
probe 'C4 with a broken extra config file + keyd reload' $F
cmd 'sudo rm /etc/keyd/broken.conf; sudo $(command -v keyd.rvaiya || command -v keyd) reload' 3
probe 'C5 broken config removed' $F
cmd '(gnome-text-editor &); sleep 15; (gnome-control-center mouse &); sleep 20; gsettings set org.gnome.desktop.interface clock-show-seconds true; sleep 2; gsettings set org.gnome.desktop.interface clock-show-seconds false; (nautilus &); sleep 15' 60
$R shot $VM shots/zdur-b1.png >/dev/null
