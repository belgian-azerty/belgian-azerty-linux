#!/bin/bash
# keyd-build-guest.sh: in a guest terminal (test VM only). Builds keyd from /tmp/keyd-patched.tgz (keyd 2.5.0 + the
# hold-AltGr test patch), runs keyd's own test suite (make test-io), uploads the binary and the logs to the host.
D=/tmp/swap; U=http://10.0.2.2:8001; mkdir -p $D
up() { wget -q --post-file="$1" "$U/$2" -O /dev/null; }
command -v gcc >/dev/null && command -v make >/dev/null ||
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential > $D/kb-apt.log 2>&1
cd /tmp && rm -rf keyd-2.5.0-patched && tar -xzf keyd-patched.tgz && cd keyd-2.5.0-patched || exit 1
{ make PREFIX=/usr 2>&1 | tail -5; echo "make rc=${PIPESTATUS[0]}"
  make test-io 2>&1 | tail -15; echo "test-io rc=${PIPESTATUS[0]}"
  ls -la bin/; sha256sum bin/keyd; } > $D/kb-build.txt 2>&1
up $D/kb-build.txt kb-build.txt
[ -f bin/keyd ] && up bin/keyd keyd-patched.bin
up $D/kb-build.txt done-kb
clear; tail -4 $D/kb-build.txt
