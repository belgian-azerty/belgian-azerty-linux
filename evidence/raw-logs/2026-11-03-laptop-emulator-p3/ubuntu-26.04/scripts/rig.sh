#!/bin/bash
# rig.sh CMD ...: host helper for point 3 in WSL. Own work dir /root/be-rig/p3 only.
W=/root/be-rig/p3; SP=/mnt/c/Users/<you>/AppData/Local/Temp/claude/<session folder>/scratchpad/p3
REPO="/mnt/c/Users/<you>/zorin and Mint keyboard driver resolution"
R="python3 /root/be-rig/rig/qemu_rig.py"
mkdir -p $W/serve $W/up $W/shots
case $1 in
  prep)   # copy guest scripts and the release debs into the serve folder, start file and upload servers
    cp $SP/serve/* $W/serve/
    cp "$REPO"/rig/typed-probe.sh "$REPO"/rig/kbstate.sh $W/serve/ 2>/dev/null
    for v in 0.9.11 0.9.12; do cp "$REPO"/github-release-$v/*_all.deb $W/serve/; grep '_all.deb' "$REPO"/github-release-$v/SHA256SUMS; done > $W/serve/SHA256SUMS-debs
    (cd $W/serve && sha256sum -c SHA256SUMS-debs)
    pgrep -f 'http.server 8000' >/dev/null || (cd $W/serve && setsid nohup python3 -m http.server 8000 --bind 127.0.0.1 > $W/http8000.log 2>&1 &)
    pgrep -f 'upload_server.py' >/dev/null || (cd $W && setsid nohup python3 /root/be-rig/rig/upload_server.py $W/up > $W/up8001.log 2>&1 &)
    sleep 1; ss -ltn | grep -E ':800[01]' ;;
  start)  shift; $R start "$@" ;;
  shot)   $R shot $2 $W/shots/$3.png && mkdir -p $SP/shots && cp $W/shots/$3.png $SP/shots/ && echo "$SP/shots/$3.png" ;;
  keys)   $R keys $2 "$3" ${4:+--delay $4} ;;
  type)   $R type $2 --as $3 "$4" ;;
  typef)  $R type $2 --as $3 "$(cat $SP/$4)" ;;
  click)  $R click $2 $3 $4 ;;
  hmp)    $R hmp $2 "$3" ;;
  probe)  (cd /root/be-rig/rig && bash typed-probe.sh $2 $3) ; cp $W/up/* $SP/up/ 2>/dev/null; true ;;
  up)     mkdir -p $SP/up; cp $W/up/* $SP/up/ 2>/dev/null; ls -l $SP/up ;;
  stop)   $R stop $2 ;;
  ps)     pgrep -af 'qemu-system|http.server|upload_server' ;;
  *) echo "unknown $1" ;;
esac
