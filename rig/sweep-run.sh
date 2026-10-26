#!/bin/bash
# sweep-run.sh VM LABEL: send the matrix, then end the guest recorder and wait for up/mon-LABEL.txt.
cd "$(dirname "$0")"
python3 sweep.py send "$1"
for i in 1 2 3; do
  timeout 5 tail -f /dev/null
  [ -s "../up/mon-$2.txt" ] && [ "$(stat -c %Y ../up/mon-$2.txt)" -gt "$(( $(date +%s) - 60 ))" ] && break
  python3 qemu_rig.py type "$1" --as be 'stopstop'
  timeout 10 tail -f /dev/null
done
ls -la ../up/mon-$2.txt
