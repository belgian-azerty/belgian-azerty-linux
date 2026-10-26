#!/bin/bash
# keyd-swapin-guest.sh patched|orig: in a guest terminal (test VM only). Puts the hold-AltGr test build
# (/tmp/keyd-patched.bin) or the packaged binary back in place of /usr/bin/keyd.rvaiya and restarts keyd.
# The packaged binary is kept as /usr/bin/keyd.rvaiya.pkg the first time.
D=/tmp/swap; U=http://10.0.2.2:8001; mkdir -p $D
B=/usr/bin/keyd.rvaiya
sudo systemctl stop keyd
[ -f $B.pkg ] || sudo cp -p $B $B.pkg
if [ "$1" = patched ]; then sudo install -m 755 /tmp/keyd-patched.bin $B; else sudo install -m 755 $B.pkg $B; fi
sudo systemctl start keyd; sleep 1
{ echo "keyd binary: $1 $(sha256sum $B | cut -c1-16) pkg=$(sha256sum $B.pkg | cut -c1-16) active=$(systemctl is-active keyd)"
  dpkg -V keyd 2>&1 | head -3; } > $D/kswap-$1.txt
wget -q --post-file=$D/kswap-$1.txt "$U/kswap-$1.txt" -O /dev/null
clear; cat $D/kswap-$1.txt
