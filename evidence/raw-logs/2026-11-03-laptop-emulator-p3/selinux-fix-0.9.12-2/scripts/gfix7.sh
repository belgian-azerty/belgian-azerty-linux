#!/bin/bash
# gfix7.sh: optional step 7, be-azerty-fix.sh system (public repo main) on Fedora 45 with 0.9.12-2, SELinux enforcing.
U=http://10.0.2.2:8001; O=/tmp/selfix-f45-step7.txt
exec > $O 2>&1
T0=$(date '+%Y-%m-%d %H:%M:%S')
echo "--- step7 $(date -u +%H:%M:%SZ) $(getenforce)"
cd /tmp && curl -sSfL -o be-azerty-fix.sh https://raw.githubusercontent.com/belgian-azerty/belgian-azerty-linux/main/be-azerty-fix.sh
curl -sSfL https://api.github.com/repos/belgian-azerty/belgian-azerty-linux/commits/main | grep -m1 '"sha"'
sha256sum be-azerty-fix.sh
sudo timeout 180 bash be-azerty-fix.sh system < /dev/null 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -40
echo "exit ${PIPESTATUS[0]}"
localectl status
echo "== AVC since step start"; sudo journalctl --since "$T0" --no-pager | grep -iE 'avc.*denied' | grep -iE 'xkb|localed'; echo "== end"
curl -s -m 5 -T $O $U/selfix-f45-step7.txt >/dev/null
