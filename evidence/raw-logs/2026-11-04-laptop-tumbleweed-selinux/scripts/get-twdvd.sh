#!/bin/bash
# get-twdvd.sh: download the Tumbleweed DVD installer (Snapshot20261102) and check it against openSUSE's .sha256 file.
set -e
mkdir -p /root/be-rig/iso && cd /root/be-rig/iso
U=https://download.opensuse.org/tumbleweed/iso
F=openSUSE-Tumbleweed-DVD-x86_64-Snapshot20261102-Media.iso
curl -sSL -o tw-dvd.sha256 "$U/$F.sha256"; cat tw-dvd.sha256
curl -sSL -o "$F" "$U/$F"
ls -l "$F"
want=$(awk '{print $1}' tw-dvd.sha256 | head -1); got=$(sha256sum "$F" | awk '{print $1}')
echo "want $want"; echo "got  $got"; [ "$want" = "$got" ] && echo "SHA256 OK" || { echo "SHA256 MISMATCH"; exit 1; }
