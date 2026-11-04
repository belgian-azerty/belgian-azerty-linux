#!/bin/bash
# tw-info.sh: list Tumbleweed install ISOs with sizes, and show qemu_rig start options. Read-only.
U=https://download.opensuse.org/tumbleweed/iso
curl -sSL "$U/" | grep -oE 'openSUSE-Tumbleweed-[A-Za-z]+-x86_64-Current\.iso' | sort -u
for F in openSUSE-Tumbleweed-DVD-x86_64-Current.iso openSUSE-Tumbleweed-NET-x86_64-Current.iso openSUSE-Tumbleweed-Offline-x86_64-Current.iso openSUSE-Tumbleweed-Agama-x86_64-Current.iso; do
  echo "== $F"; curl -sIL -m 20 "$U/$F" | grep -iE '^(HTTP|location|content-length)' | tail -3
done
grep -n 'add_argument\|def start\|qcow\|drive' /root/be-rig/rig/qemu_rig.py | head -40
df -h /root | tail -1
