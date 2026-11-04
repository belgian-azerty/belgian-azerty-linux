#!/bin/bash
# Download ubuntu-26.04.1-desktop-amd64.iso from releases.ubuntu.com and check it against SHA256SUMS.
set -e
cd /root/be-rig/iso
F=ubuntu-26.04.1-desktop-amd64.iso
curl -sSL -C - -o "$F" "https://releases.ubuntu.com/26.04/$F"
curl -sSL -o SHA256SUMS-ubuntu-26.04 https://releases.ubuntu.com/26.04/SHA256SUMS
ls -l "$F"
grep " \*$F\$" SHA256SUMS-ubuntu-26.04 | sed 's/ \*/  /' | sha256sum -c -
