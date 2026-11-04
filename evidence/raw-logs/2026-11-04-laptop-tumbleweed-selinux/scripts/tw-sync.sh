#!/bin/bash
# tw-sync.sh: copy the guest scripts and the sel/ rpm folders into the served folder; show what the guest can fetch.
SP=/mnt/c/Users/<you>/AppData/Local/Temp/claude/<session folder>/scratchpad/p3
W=/root/be-rig/p3
cp $SP/serve/*.sh $W/serve/ && cp -r $SP/serve/sel $W/serve/
ls $W/serve | tr '\n' ' '; echo; ls $W/serve/sel/tw
curl -s -o /dev/null -w 'gtwi.sh http %{http_code}\n' http://127.0.0.1:8000/gtwi.sh
