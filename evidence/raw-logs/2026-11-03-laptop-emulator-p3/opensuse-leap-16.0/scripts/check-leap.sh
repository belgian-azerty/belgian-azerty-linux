#!/bin/bash
# Check the downloaded Leap 16.0 ISO against openSUSE's .sha512 file (Leap 16.0 publishes SHA-512, not SHA-256).
cd /root/be-rig/iso
rm -f leap16.sha256
U=https://download.opensuse.org/distribution/leap/16.0/offline
curl -sSL -o leap16.sha512 $U/Leap-16.0-offline-installer-x86_64.install.iso.sha512
cat leap16.sha512
want=$(awk '{print $1}' leap16.sha512 | head -1); got=$(sha512sum Leap-16.0-offline-installer-x86_64.install.iso | awk '{print $1}')
echo "want $want"; echo "got  $got"; [ "$want" = "$got" ] && echo "SHA512 OK" || echo "SHA512 MISMATCH"
