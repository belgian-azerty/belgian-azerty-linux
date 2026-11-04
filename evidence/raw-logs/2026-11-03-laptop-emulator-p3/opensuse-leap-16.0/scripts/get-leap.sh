#!/bin/bash
# Download Leap-16.0-offline-installer-x86_64.install.iso and check it against openSUSE's .sha256 file.
set -e
cd /root/be-rig/iso
U=https://download.opensuse.org/distribution/leap/16.0/offline
F=Leap-16.0-offline-installer-x86_64.install.iso
curl -sSL -o leap16.sha256 "$U/$F.sha256"; cat leap16.sha256
curl -sSL -o "$F" "$U/$F"
ls -l "$F"
want=$(awk '{print $1}' leap16.sha256 | head -1); got=$(sha256sum "$F" | awk '{print $1}')
echo "want $want"; echo "got  $got"; [ "$want" = "$got" ] && echo "SHA256 OK" || { echo "SHA256 MISMATCH"; exit 1; }
