K=/root/be-rig/k94; cd $K/rig
bash $K/sh.sh k94-mint mint-final
python3 qemu_rig.py stop k94-mint; sleep 3
pgrep -a qemu | cut -c1-80; free -m | head -2
python3 qemu_rig.py start k94-zorin --iso /root/be-rig/iso/Zorin-OS-18.1-Core-64-bit.iso --mem 4096 --smp 4 --cpu host --vga virtio --state $K/k94-zorin-state.qcow2
date -u +%T
