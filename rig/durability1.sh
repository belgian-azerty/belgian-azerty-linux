#!/bin/bash
# Durability chunk 1 on the installed Mint (VM inst): keyd stop/kill/broken-config, unrelated apps and settings, layout-store changes.
cd "$(dirname "$0")/.."
R="python3 rig/qemu_rig.py"; VM=inst
w() { timeout "$1" tail -f /dev/null; }
probe() {  # $1 = label, $2 = file; types a line that shows plain, AltGr and Ctrl+Alt behaviour
  $R type $VM "head -n 1 >> /tmp/$2
"; w 2
  $R type $VM "$1 | plain: azerty é | AltGr+2 e: "; $R keys $VM 'alt_r-2 alt_r-e' --delay 0.3; $R type $VM ' | LCtrl+LAlt+2 e: '; $R keys $VM 'ctrl-alt-2 ctrl-alt-e' --delay 0.3; $R keys $VM ret; w 2
}
cmd() { $R type $VM "$1
"; w "${2:-3}"; }
cmd 'clear; echo azerty | sudo -S true; sudo cat /var/lib/AccountsService/users/test | tee /tmp/accounts1.txt; rm -f /tmp/dur1.txt' 4
probe 'A0 baseline keyd on' dur1.txt
cmd 'sudo systemctl stop keyd; systemctl is-active keyd'
probe 'C1 after systemctl stop keyd' dur1.txt
cmd 'sudo systemctl start keyd; systemctl is-active keyd' 4
probe 'C2 after systemctl start keyd' dur1.txt
cmd 'sudo kill -9 $(pidof keyd.rvaiya keyd); sleep 2; systemctl is-active keyd' 5
probe 'C3 after kill -9 keyd (service state above)' dur1.txt
cmd 'systemctl is-active keyd || sudo systemctl start keyd; echo "this is not a valid keyd config [[[" | sudo tee /etc/keyd/broken.conf; sudo $(command -v keyd.rvaiya || command -v keyd) reload; sleep 1; systemctl is-active keyd' 5
probe 'C4 with a broken extra config file + keyd reload' dur1.txt
cmd 'sudo rm /etc/keyd/broken.conf; sudo $(command -v keyd.rvaiya || command -v keyd) reload' 3
probe 'C5 broken config removed' dur1.txt
cmd '(xed /tmp/dur1.txt &); sleep 8; (cinnamon-settings mouse &); sleep 10; gsettings set org.cinnamon.desktop.interface clock-show-seconds true; gsettings set org.cinnamon.desktop.interface clock-show-seconds false' 25
$R shot $VM shots/dur-b1.png >/dev/null
$R click $VM 300 300 >/dev/null; w 2
probe 'B1 after opening xed (GTK), the Mouse settings panel and toggling an unrelated setting' dur1.txt
cmd 'bash /tmp/kbstate.sh after-B1 | tee -a /tmp/dur1.txt' 5
cmd 'gsettings set org.cinnamon.desktop.input-sources sources "[('"'"'xkb'"'"', '"'"'us'"'"')]"; sleep 3; setxkbmap -query | grep layout; grep XKBLAYOUT /etc/default/keyboard' 6
probe 'A2a Cinnamon input-sources set to us (what the Keyboard settings panel does)' dur1.txt
cmd 'gsettings set org.cinnamon.desktop.input-sources sources "[('"'"'xkb'"'"', '"'"'be'"'"')]"; sleep 3; setxkbmap -query | grep layout' 6
probe 'A2b Cinnamon input-sources set back to be' dur1.txt
cmd 'sudo cat /var/lib/AccountsService/users/test > /tmp/accounts2.txt; diff /tmp/accounts1.txt /tmp/accounts2.txt; for f in dur1 accounts1 accounts2; do wget -q --post-file=/tmp/$f.txt http://10.0.2.2:8001/inst-$f.txt -O /dev/null; done; echo up' 8
$R shot $VM shots/dur-1-end.png >/dev/null
