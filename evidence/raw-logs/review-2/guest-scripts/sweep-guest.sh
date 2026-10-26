#!/bin/bash
# sweep-guest.sh LABEL: log every key event (keyd monitor) while the host sends the shortcut matrix.
# The terminal is put in raw mode (no Ctrl+C/Ctrl+Z/Ctrl+D effects); type "stopstop" to end.
L=$1
sudo -v || exit 1
sudo pkill -f 'keyd.rvaiya -m' 2>/dev/null
sudo setsid sh -c "exec keyd.rvaiya -m -t > /tmp/mon-$L.txt 2>&1" < /dev/null &
sleep 2
echo "recording $L (keyd $(systemctl is-active keyd)); type stopstop to end"
python3 -c '
import tty, os, signal, sys, termios
old = termios.tcgetattr(0); signal.alarm(1800); tty.setraw(0)
buf = b""
f = open("/tmp/raw-" + sys.argv[1] + ".bin", "wb")
try:
    while not buf.endswith(b"stopstop"):
        b = os.read(0, 64); buf = (buf + b)[-64:]; f.write(b); f.flush()
finally:
    termios.tcsetattr(0, termios.TCSADRAIN, old)
' "$L"
sudo pkill -f 'keyd.rvaiya -m'
for f in /tmp/mon-$L.txt /tmp/raw-$L.bin; do wget -q --post-file=$f http://10.0.2.2:8001/$(basename $f) -O /dev/null; done
echo "uploaded $L"
