#!/bin/bash
# Download openSUSE-Tumbleweed-KDE-Live-x86_64-Current.iso and check it against openSUSE's .sha256 file.
set -e
cd /root/be-rig/iso
U=https://download.opensuse.org/tumbleweed/iso
F=openSUSE-Tumbleweed-KDE-Live-x86_64-Current.iso
echo "redirects to: $(curl -sIL $U/$F | grep -i '^location' | tail -1)"
curl -sSL -o tw-kde.sha256 "$U/$F.sha256"; cat tw-kde.sha256
curl -sSL -o "$F" "$U/$F"
ls -l "$F"
want=$(awk '{print $1}' tw-kde.sha256 | head -1); got=$(sha256sum "$F" | awk '{print $1}')
echo "want $want"; echo "got  $got"; [ "$want" = "$got" ] && echo "SHA256 OK" || { echo "SHA256 MISMATCH"; exit 1; }
