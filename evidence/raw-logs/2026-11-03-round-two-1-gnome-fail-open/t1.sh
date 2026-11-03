#!/bin/bash
# As tester. $1 = stock|patched. Headless GNOME Shell 46 (Ubuntu 24.04), Belgian layout, ibus spawned by the shell itself
# (no systemd user service, as on the GDM login screen). Three phases, each types a word into a GTK 4 text box:
#  A healthy ibus; B the shell's ibus input context points at an object that does not exist (the exact error from the
#  Zorin login screen); C ibus-daemon replaced with "-r --xim", as GNOME Shell itself does when Xwayland starts.
V=$1; O=/out/$V; mkdir -p $O
export XDG_RUNTIME_DIR=/tmp/xdg-$V; rm -rf $XDG_RUNTIME_DIR; mkdir -p $XDG_RUNTIME_DIR; chmod 700 $XDG_RUNTIME_DIR
export XDG_CURRENT_DESKTOP=GNOME LANG=en_US.UTF-8
export DBUS_SESSION_BUS_ADDRESS=$(dbus-daemon --session --fork --print-address)
gsettings set org.gnome.desktop.input-sources sources "[('xkb','be')]"
[ "$V" = patched ] && export G_RESOURCE_OVERLAYS=/org/gnome/shell/misc/inputMethod.js=/probe/inputMethod.patched.js
gnome-shell --headless --wayland --virtual-monitor 1024x768 --no-x11 --unsafe-mode > $O/shell.log 2>&1 &
for i in $(seq 1 120); do gdbus introspect --session --dest org.gnome.Mutter.RemoteDesktop --object-path /org/gnome/Mutter/RemoteDesktop >/dev/null 2>&1 && break; sleep 0.5; done
E(){ gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "$1"; }
for i in $(seq 1 60); do E 'Main.inputMethod._context !== null' | grep -q "'true'" && break; sleep 0.5; done
echo "overlay in use: $(E 'String(Main.inputMethod.vfunc_filter_key_event).includes("Fail open")')" > $O/result.txt
echo "ibus context before A: $(E "String(Main.inputMethod._context !== null)")" >> $O/result.txt
pgrep -a ibus-daemon >> $O/result.txt
WAYLAND_DISPLAY=wayland-0 GDK_BACKEND=wayland GTK_IM_MODULE= python3 /probe/textview.py > $O/textview.log 2>&1 &
sleep 3
E 'Main.overview.hide(); "ok"' >/dev/null; sleep 1
E 'global.get_window_actors().map(a=>a.meta_window).filter(m=>m.get_wm_class()).forEach(m=>m.activate(global.get_current_time())); "ok"' >/dev/null
sleep 0.5
python3 /probe/typekeys.py qw; sleep 0.5    # warm-up line
cnt(){ grep -c "Error processing key on IM" $O/shell.log; }
echo "errors before A: $(cnt)" >> $O/result.txt
python3 /probe/typekeys.py azerty
echo "errors after A: $(cnt)" >> $O/result.txt
E 'const IBus = imports.gi.IBus; const im = Main.inputMethod; im._context = IBus.InputContext.new("/org/freedesktop/IBus/InputContext_999", im._ibus.get_connection(), null); im._context.get_object_path()' >> $O/result.txt
python3 /probe/typekeys.py belgique
echo "errors after B: $(cnt)" >> $O/result.txt
python3 /probe/typekeys.py "BébéBelgique&Liège" 0.005
echo "errors after B2 (fast, Shift, é, &): $(cnt)" >> $O/result.txt
E 'const im = Main.inputMethod; im._clear(); im._onConnected(); "reconnected"' >> $O/result.txt; sleep 2
echo "ibus context before C: $(E 'String(Main.inputMethod._context && Main.inputMethod._context.get_object_path())')" >> $O/result.txt
ibus-daemon --panel disable -r --xim -d; sleep 3
pgrep -a ibus-daemon >> $O/result.txt
echo "ibus context after restart: $(E 'String(Main.inputMethod._context && Main.inputMethod._context.get_object_path())')" >> $O/result.txt
python3 /probe/typekeys.py clavier
echo "errors after C: $(cnt)" >> $O/result.txt
sleep 1; cp /tmp/typed.txt $O/typed.txt 2>/dev/null; echo "--- typed:" >> $O/result.txt; cat $O/typed.txt >> $O/result.txt
pkill -u $(id -u) -f gnome-shell; pkill -u $(id -u) ibus-daemon; true
