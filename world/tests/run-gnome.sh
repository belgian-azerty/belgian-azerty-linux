#!/bin/bash
# Inside a container with headless GNOME Shell, as an ordinary user: input source $1 (GNOME id, e.g. ch_windows+fr),
# type the plan $2 through Mutter's RemoteDesktop interface into a GTK 4 text box, save the text to $3.
#   world/tests/run-gnome.sh SOURCE PLAN.json OUT.txt [seconds per key event, default 0.02]
export XDG_RUNTIME_DIR=/tmp/xdg-$(id -u); mkdir -p $XDG_RUNTIME_DIR; chmod 700 $XDG_RUNTIME_DIR
export DBUS_SESSION_BUS_ADDRESS=$(dbus-daemon --session --fork --print-address)
HERE=$(cd "$(dirname "$0")" && pwd)
gsettings set org.gnome.desktop.input-sources sources "[('xkb','$1')]"
gsettings set org.gnome.desktop.input-sources xkb-options "[]"
echo "sources: $(gsettings get org.gnome.desktop.input-sources sources)"
if [ "${ACCENT_SPACE:-0}" = 1 ]; then      # the real command, as this user, before the desktop and the apps start
  world-keyboard-windows accent-space on; [ -e ~/.XCompose ] && cp ~/.XCompose "$3.XCompose"
fi
gnome-shell --headless --wayland --virtual-monitor 1024x768 --no-x11 --unsafe-mode > /tmp/shell-$1.log 2>&1 &
for i in $(seq 1 120); do gdbus introspect --session --dest org.gnome.Mutter.RemoteDesktop --object-path /org/gnome/Mutter/RemoteDesktop >/dev/null 2>&1 && break; sleep 0.5; done
rm -f /tmp/typed.txt
WAYLAND_DISPLAY=wayland-0 GDK_BACKEND=wayland python3 "$HERE/textview.py" > /tmp/entry.log 2>&1 &
sleep 3
E(){ gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "$1" >/dev/null; }
E 'Main.overview.hide(); "ok"'; sleep 1
E 'global.get_window_actors().map(a=>a.meta_window).filter(m=>m.get_wm_class()).forEach(m=>m.activate(global.get_current_time())); "ok"'
sleep 0.5
python3 "$HERE/typeall.py" "$2" "${4:-0.02}"
cp /tmp/typed.txt "$3"
pkill -u "$(id -u)" -f textview.py; pkill -u "$(id -u)" gnome-shell; sleep 1
[ "${ACCENT_SPACE:-0}" = 1 ] && world-keyboard-windows accent-space off >/dev/null
