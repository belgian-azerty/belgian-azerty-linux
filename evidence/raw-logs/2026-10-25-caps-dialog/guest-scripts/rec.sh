#!/bin/bash
# Caps-dialog bench recorder: each typed line is logged with the Caps LED state and uploaded to the host.
# A line "p" (or "P") opens a pkexec password dialog (polkit agent = GNOME Shell) in the background.
L=/tmp/rec.log; : > $L
led() { cat /sys/class/leds/input*::capslock/brightness 2>/dev/null | tr '\n' ' '; }
echo "session=$XDG_SESSION_TYPE keyd=$(systemctl is-active keyd) engine=$(ibus engine 2>&1) sources=$(gsettings get org.gnome.desktop.input-sources sources) opts=$(gsettings get org.gnome.desktop.input-sources xkb-options)" >> $L
n=0
while true; do
  n=$((n+1))
  echo "== round $n LED=$(led)"
  IFS= read -r line || break
  echo "round $n $(date +%T) LED=$(led) line=[$line]" >> $L
  case "$line" in p|P) (pkexec true; echo "pkexec rc=$?" >> $L) & ;; esac
  case "$line" in q|Q) break ;; esac
  curl -s -T $L http://10.0.2.2:8001/rec.log >/dev/null
done
curl -s -T $L http://10.0.2.2:8001/rec.log >/dev/null
