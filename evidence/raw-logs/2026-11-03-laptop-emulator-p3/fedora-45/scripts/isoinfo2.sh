#!/bin/bash
# Read-only: Fedora release ISO names, sizes and checksum files.
B=https://dl.fedoraproject.org/pub/fedora/linux/releases
curl -sL $B/ | grep -oE 'href="[0-9]+/"' | tail -4
for v in 45 44; do
  for e in Workstation KDE; do
    u=$B/$v/$e/x86_64/iso/
    for f in $(curl -sL $u | grep -oE 'href="[^"]+\.(iso|CHECKSUM)"' | sed 's/href="//;s/"$//'); do
      echo "$v $e $f $(curl -sIL $u$f | grep -i '^content-length' | tail -1 | tr -d '\r')"
    done
  done
done
