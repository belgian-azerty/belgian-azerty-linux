#!/bin/bash
# Candidate 0.9.6 on the live Mint bench (X11, Cinnamon): install 0.9.4.1, run the candidate script with no settings,
# then a recorder: each typed line logged with the Caps LED; "p" opens a pkexec dialog. Cloud emulator only.
up() { curl -s -T "$1" "http://10.0.2.2:8001/$2" >/dev/null 2>&1 || wget -q --method=PUT --body-file="$1" "http://10.0.2.2:8001/$2" -O /dev/null; }
get() { curl -s "http://10.0.2.2:8002/$1" -o "/tmp/$1" 2>/dev/null || wget -q "http://10.0.2.2:8002/$1" -O "/tmp/$1"; }
L=/tmp/m96.log; : > $L
{
for f in keyd_2.5.0-5~ubuntu24.04.2_amd64.deb keyd-belgian-windows_0.9.4.1_all.deb belgian-azerty-windows_0.9.4.1_all.deb bf96.sh; do get "$f"; done
cd /tmp && sha256sum *.deb bf96.sh
echo "== install 0.9.4.1 debs"; sudo dpkg -i /tmp/keyd_*.deb /tmp/keyd-belgian-windows_*.deb /tmp/belgian-azerty-windows_*.deb 2>&1 | tail -3
sudo rm -f /var/lib/belgian-azerty-windows/choices
echo "== candidate: sudo be-azerty-fix system (no settings)"
sudo bash /tmp/bf96.sh system 2>&1 | sed 's/\x1b\[[0-9;]*m//g'
echo "== after"; grep XKBOPTIONS /etc/default/keyboard; cat /var/lib/belgian-azerty-windows/choices; setxkbmap -query
bash /tmp/bf96.sh check 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -i "caps\|profile\|GNOME:\|desktop"
sudo systemctl stop keyd; echo "keyd=$(systemctl is-active keyd) session=$XDG_SESSION_TYPE desktop=$XDG_CURRENT_DESKTOP"
} >> $L 2>&1
up $L m96.log
led() { cat /sys/class/leds/input*::capslock/brightness 2>/dev/null | tr '\n' ' '; }
n=0
while true; do
  n=$((n+1)); echo "== round $n LED=$(led)"
  IFS= read -r line || break
  echo "round $n $(date +%T) LED=$(led) line=[$line]" >> $L
  case "$line" in p|P) (pkexec true; echo "pkexec rc=$?" >> $L) & ;; esac
  case "$line" in q|Q) break ;; esac
  up $L m96.log
done
up $L m96.log
