K=/root/be-rig/k94; cd $K/rig
bash $K/sh.sh k94-zorin zorin-final
python3 qemu_rig.py stop k94-zorin; sleep 2; pgrep -a qemu | cut -c1-60
ls $K/uploads | tr '\n' ' '; echo; ls $K/shots | tr '\n' ' '; echo; ls $K/logs; du -sh $K/*.qcow2 $K/uploads $K/shots
