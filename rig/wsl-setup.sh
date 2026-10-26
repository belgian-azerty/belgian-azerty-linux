#!/bin/bash
# Prepare the fast test rig inside WSL 2 Ubuntu on a Windows PC (hardware virtualisation through /dev/kvm).
# Safe to run again: it only installs what is missing and only downloads ISOs that are absent or wrong.
#
#   wsl -d Ubuntu-24.04 -u root -- bash "/mnt/c/<folder with this rig>/wsl-setup.sh" [mint] [zorin]
#
# Everything lands in $BE_RIG (default /root/be-rig): rig/ (these scripts), iso/ (checked ISOs).
# Memory: a 4 GB live VM fits in WSL's default cap; installs (5-6 GB) want memory=12GB in %USERPROFILE%\.wslconfig.
# Undo: apt-get remove -y qemu-system-x86 qemu-utils python3-pil xorriso imagemagick; rm -rf $BE_RIG
set -euo pipefail
BASE=${BE_RIG:-/root/be-rig}
HERE=$(cd "$(dirname "$0")" && pwd)

if [ ! -e /dev/kvm ]; then
    echo "No /dev/kvm: WSL has no nested virtualisation here (needs Windows 11 and nestedVirtualization=true in .wslconfig)." >&2
    echo "The rig would still run, but as slowly as the cloud (software emulation)." >&2
    exit 1
fi

PKGS="qemu-system-x86 qemu-utils python3-pil xorriso imagemagick"
missing=$(for p in $PKGS; do dpkg -s "$p" >/dev/null 2>&1 || echo "$p"; done)
if [ -n "$missing" ]; then
    apt-get update -qq
    apt-get install -y -qq $missing
fi

mkdir -p "$BASE/iso" "$BASE/rig"
if [ "$HERE" != "$BASE/rig" ]; then
    cp "$HERE"/*.py "$HERE"/*.sh "$BASE/rig/"
fi

# name -> ISO URL, checksum list URL
fetch() {
    local url=$1 sums=$2 file
    file=$(basename "$url")
    cd "$BASE/iso"
    if [ -f "$file" ] && curl -fsSL "$sums" | grep " \*\?$file\$" | sha256sum -c --status 2>/dev/null; then
        echo "$file: present, checksum OK"; return
    fi
    for i in 1 2 3 4 5 6; do
        curl -fL -C - --retry 5 -o "$file" "$url" && break
        echo "download interrupted, resuming ($i)"
    done
    curl -fsSL "$sums" | grep " \*\?$file\$" | sha256sum -c
}

for want in "${@:-mint}"; do
    case $want in
        mint)  fetch https://mirrors.edge.kernel.org/linuxmint/stable/22.3/linuxmint-22.3-cinnamon-64bit.iso \
                     https://mirrors.edge.kernel.org/linuxmint/stable/22.3/sha256sum.txt ;;
        zorin) fetch https://ftp.halifax.rwth-aachen.de/zorinos/18/Zorin-OS-18.1-Core-64-bit.iso \
                     https://ftp.halifax.rwth-aachen.de/zorinos/18/SHA256SUMS.txt ;;
        *) echo "unknown ISO '$want' (mint, zorin)" >&2; exit 1 ;;
    esac
done

echo
echo "Ready. Example (boots with KVM automatically):"
echo "  cd $BASE/rig && python3 qemu_rig.py start mint --iso $BASE/iso/linuxmint-22.3-cinnamon-64bit.iso \\"
echo "      --mem 4096 --smp 4 --cpu host --vga virtio --state $BASE/mint-live-state.qcow2"
