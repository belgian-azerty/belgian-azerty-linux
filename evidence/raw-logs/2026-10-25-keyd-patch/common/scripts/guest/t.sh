#!/bin/bash
# t.sh NAME: capture what the keyboard types (until Ctrl+D) into /tmp/NAME.txt, then send it and an od dump to the host.
n=$1; echo "== typing capture $n (Ctrl+D ends)"; cat > /tmp/$n.txt
od -c /tmp/$n.txt > /tmp/$n-od.txt
for f in $n.txt $n-od.txt; do wget -q --post-file=/tmp/$f http://10.0.2.2:8011/$f -O /dev/null; done; echo "uploaded $n"
