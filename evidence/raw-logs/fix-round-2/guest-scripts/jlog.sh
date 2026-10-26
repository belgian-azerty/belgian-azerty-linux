#!/bin/bash
# jlog.sh: every 30 s upload the journal of this boot plus the session state, so a session that no longer takes input
# can still be diagnosed from the host. Runs as root, detached.
while sleep 30; do
  { date -u; loginctl list-sessions --no-legend; for s in $(loginctl list-sessions --no-legend | awk '{print $1}'); do
      loginctl show-session "$s" -p Name -p Type -p Class -p State -p Active -p VTNr -p Remote 2>/dev/null | tr '\n' ' '; echo; done
    echo "--- journal (gnome-shell, gdm, mutter, xkb)"; journalctl -b --no-pager -o short-precise 2>/dev/null | grep -iE 'gnome-shell|gdm|mutter|xkb|keymap|libinput|session' | tail -150
  } > /tmp/jlog.txt 2>&1
  wget -q --post-file=/tmp/jlog.txt http://10.0.2.2:8001/jlog.txt -O /dev/null
done
