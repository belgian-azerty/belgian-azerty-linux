#!/bin/bash
# Candidate 0.9.6 on the live Zorin bench: default Windows profile on GNOME, then the CAPS=windows opt-in.
exec > >(tee /tmp/t96.log) 2>&1
curl -s 10.0.2.2:8002/bf96.sh > /tmp/bf96.sh
echo "== saved choices before"; cat /var/lib/belgian-azerty-windows/choices; sudo rm -f /var/lib/belgian-azerty-windows/choices
echo "== A: sudo be-azerty-fix system (candidate, no settings given)"
sudo bash /tmp/bf96.sh system 2>&1 | sed 's/\x1b\[[0-9;]*m//g'
echo "== after A"; grep XKBOPTIONS /etc/default/keyboard; gsettings get org.gnome.desktop.input-sources xkb-options; cat /var/lib/belgian-azerty-windows/choices
bash /tmp/bf96.sh check 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -i "caps\|profile"
echo "== B: sudo be-azerty-fix system CAPS=windows (opt-in)"
sudo bash /tmp/bf96.sh system CAPS=windows 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -i "choices\|caps\|options\|✘"
echo "== after B"; grep XKBOPTIONS /etc/default/keyboard; gsettings get org.gnome.desktop.input-sources xkb-options; cat /var/lib/belgian-azerty-windows/choices
bash /tmp/bf96.sh check 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -i "caps\|GNOME:"
echo "== C: rerun without settings keeps the opt-in"
sudo bash /tmp/bf96.sh system 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -i "choices"
echo "== D: back to the candidate default: sudo be-azerty-fix system PROFILE=windows"
sudo bash /tmp/bf96.sh system PROFILE=windows 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -i "choices\|✘"
grep XKBOPTIONS /etc/default/keyboard; gsettings get org.gnome.desktop.input-sources xkb-options
sudo systemctl stop keyd; systemctl is-active keyd
curl -s -T /tmp/t96.log 10.0.2.2:8001/t96.log
