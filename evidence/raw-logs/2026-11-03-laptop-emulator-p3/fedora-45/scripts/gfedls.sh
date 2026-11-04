#!/bin/bash
# gfedls.sh: system keyboard state just before logging out (login screen test).
U=http://10.0.2.2:8001; O=/tmp/gfed-ls.txt
exec > $O 2>&1
echo "--- ls $(date -u +%H:%M:%SZ)"
cat /etc/X11/xorg.conf.d/00-keyboard.conf; cat /etc/vconsole.conf
localectl status
wget -q -T 5 --post-file=$O $U/gfed-ls.txt -O /dev/null
