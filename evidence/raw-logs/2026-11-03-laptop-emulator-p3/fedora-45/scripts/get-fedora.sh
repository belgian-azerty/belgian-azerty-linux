#!/bin/bash
# Download Fedora-Workstation-Live-45-1.4.x86_64.iso from dl.fedoraproject.org and check it against Fedora's CHECKSUM.
set -e
cd /root/be-rig/iso
U=https://dl.fedoraproject.org/pub/fedora/linux/releases/45/Workstation/x86_64/iso/
F=Fedora-Workstation-Live-45-1.4.x86_64.iso
C=$(curl -sL $U | grep -oE 'href="[^"]*CHECKSUM"' | sed 's/href="//;s/"$//' | head -1)
echo "checksum file: $C"
curl -sSL -o "fedora45-$C" "$U$C"
curl -sSL -C - -o "$F" "$U$F"
ls -l "$F"
grep -E "^SHA256 \($F\)" "fedora45-$C" | sed -E 's/^SHA256 \((.*)\) = (.*)$/\2  \1/' | sha256sum -c -
