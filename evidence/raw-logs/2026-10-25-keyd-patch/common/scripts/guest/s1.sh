#!/bin/bash
# s1.sh LABEL DIR [live]: install the three debs of /tmp/k/DIR with apt, optionally run be-azerty-fix.sh live,
# then record versions, keyd binary, service state and be-azerty-fix check; upload LABEL-install.txt, LABEL-check.txt
L=$1; D=$2; U=http://10.0.2.2:8011
{
  echo "== $L $(date -u +%FT%TZ) dir=$D"
  cd /tmp/k/$D && sha256sum ./*.deb
  sudo apt install -y ./keyd_*.deb ./keyd-belgian-windows_*.deb ./belgian-azerty-windows_*.deb
  echo "apt install exit $?"
  if [ "${3:-}" = live ]; then
    echo "== sudo bash be-azerty-fix.sh live"
    sudo bash /tmp/k/be-azerty-fix.sh live
    echo "be-azerty-fix.sh live exit $?"
  fi
  sleep 2
  echo "== dpkg-query"; dpkg-query -W keyd keyd-belgian-windows belgian-azerty-windows
  echo "== keyd exe (sudo)"; sudo ls -l /proc/$(pidof keyd.rvaiya)/exe
  echo "== keyd binary"; sha256sum /usr/bin/keyd.rvaiya
  echo "== systemctl is-active keyd"; systemctl is-active keyd
  echo "== systemctl --failed"; systemctl --failed --no-pager
  echo "== session"; echo "type=$XDG_SESSION_TYPE desktop=$XDG_CURRENT_DESKTOP"; setxkbmap -query 2>&1
} > /tmp/k/$L-install.txt 2>&1
be-azerty-fix check > /tmp/k/$L-check.txt 2>&1; echo "check exit $?" >> /tmp/k/$L-check.txt
for f in $L-install.txt $L-check.txt; do wget -q --post-file=/tmp/k/$f $U/$f -O /dev/null; done
clear; tail -8 /tmp/k/$L-install.txt; sed 's/\x1b\[[0-9;]*m//g' /tmp/k/$L-check.txt | grep -E "✘|exit"
echo "s1 done $L"
