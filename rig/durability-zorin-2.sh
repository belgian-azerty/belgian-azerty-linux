#!/bin/bash
# Part 2, after the terminal is focused again: probes after the apps, then store changes and package reinstall.
cd "$(dirname "$0")/.."
R="python3 rig/qemu_rig.py"; VM=${VM:-zi}
w() { timeout "$1" tail -f /dev/null; }
probe() {
  $R type $VM --as be "head -n 1 >> /tmp/$2
"; w 2
  $R type $VM --as be "$1 | plain: azerty é | AltGr+2 e: "; $R keys $VM 'alt_r-2 alt_r-e' --delay 0.3; $R type $VM --as be ' | LCtrl+LAlt+2 e: '; $R keys $VM 'ctrl-alt-2 ctrl-alt-e' --delay 0.3; $R keys $VM ret; w 2
}
cmd() { $R type $VM --as be "$1
"; w "${2:-3}"; }
F=zdur.txt
probe 'B1 after opening Text Editor, Settings > Mouse, Files and toggling an unrelated setting' $F
cmd "bash /tmp/kbstate.sh after-B1 >> /tmp/$F" 6
cmd "sudo apt-get install -y --reinstall keyboard-configuration console-setup > /tmp/reinst.log 2>&1; echo reinstall rc=\$? >> /tmp/$F; bash /tmp/kbstate.sh after-A3-reinstall >> /tmp/$F" 240
probe 'A3 after apt reinstall of keyboard-configuration + console-setup' $F
cmd "gsettings set org.gnome.desktop.input-sources sources \"[('xkb', 'us'), ('xkb', 'be')]\"; sleep 3; bash /tmp/kbstate.sh planted-us >> /tmp/$F" 8
probe 'A2a GNOME input-sources planted us first (what adding US in Settings and moving it up does)' $F
cmd "sudo bash /tmp/be-azerty-fix.sh system > /tmp/fix-sys.log 2>&1; echo fix rc=\$? >> /tmp/$F; sleep 3; bash /tmp/kbstate.sh after-fix-system >> /tmp/$F" 120
probe 'A2b after sudo be-azerty-fix.sh system' $F
cmd "for f in $F fix-sys.log reinst.log; do wget -q --post-file=/tmp/\$f http://10.0.2.2:8001/zi-\$f -O /dev/null; done; echo up" 8
$R shot $VM shots/zdur-2-end.png >/dev/null
