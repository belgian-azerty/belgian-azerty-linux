#!/bin/bash
# Read-only: list ISO names, sizes and checksums from official release pages.
size() { curl -sIL "$1" | grep -i '^content-length' | tail -1; }
echo "== Ubuntu 26.04"
curl -sL https://releases.ubuntu.com/26.04/SHA256SUMS
for f in $(curl -sL https://releases.ubuntu.com/26.04/SHA256SUMS | grep -o 'ubuntu-[^ ]*desktop-amd64.iso'); do
  echo "$f $(size https://releases.ubuntu.com/26.04/$f)"
done
