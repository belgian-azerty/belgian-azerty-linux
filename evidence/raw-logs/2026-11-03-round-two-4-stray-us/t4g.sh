#!/bin/bash
# As tester. $1 label, $2 LANG. Headless GNOME Shell 46, sources [be]; print the layouts GNOME Shell put in its keymap.
L=$1; O=/out/$L; mkdir -p $O
export XDG_RUNTIME_DIR=/tmp/xdg-$L; mkdir -p $XDG_RUNTIME_DIR; chmod 700 $XDG_RUNTIME_DIR
export XDG_CURRENT_DESKTOP=GNOME LANG=$2 LANGUAGE=
export DBUS_SESSION_BUS_ADDRESS=$(dbus-daemon --session --fork --print-address)
gsettings set org.gnome.desktop.input-sources sources "[('xkb','be')]"
gnome-shell --headless --wayland --virtual-monitor 1024x768 --no-x11 --unsafe-mode > $O/shell.log 2>&1 &
E(){ gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "$1"; }
for i in $(seq 1 120); do E '1' 2>/dev/null | grep -q true && break; sleep 0.5; done; sleep 3
echo "LANG=$LANG keymap: $(E 'const k = Main.inputMethod._inputSourceManager._keyboardManager; JSON.stringify(k._currentKeymap && k._currentKeymap.layouts) + " locale layout " + JSON.stringify(k._localeLayoutInfo)')" | tee $O/result.txt
pkill -u $(id -u) -f gnome-shell; true
