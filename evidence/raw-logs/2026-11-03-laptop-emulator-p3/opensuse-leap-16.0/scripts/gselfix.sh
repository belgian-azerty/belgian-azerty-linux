#!/bin/bash
# gselfix.sh DIST STEP: SELinux route A step 2 (LAPTOP-TEST-STEPS.md), 0.9.12-2 with the belgian_azerty_xkb module.
# DIST = f45 | leap16 (folder under :8000/sel/). STEP = up (steps 1-5) | after-reboot (step 6 facts) | remove (step 8).
U=http://10.0.2.2:8001; S=http://10.0.2.2:8000/sel; D=$1; STEP=$2; O=/tmp/selfix-$D-$STEP.txt
exec > $O 2>&1
up() { curl -s -m 5 -T $O $U/selfix-$D-$STEP.txt >/dev/null; }
try() { echo "== localectl set-x11-keymap $*"; sudo localectl set-x11-keymap "$@"; echo "exit $?"; localectl status | sed 's/^/   /'; }
labels() { ls -Z /etc/xkb/rules/evdev /etc/xkb/symbols/be_capslock 2>&1; }
avc() { echo "== AVC (ausearch, xkb)"; sudo ausearch -m avc -ts recent 2>&1 | grep -i xkb; echo "== AVC (journal since step start, xkb|localed)"; sudo journalctl --since "$T0" --no-pager | grep -iE 'avc.*denied' | grep -iE 'xkb|localed'; echo "== end AVC"; }
T0=$(date '+%Y-%m-%d %H:%M:%S')
echo "--- selfix $D $STEP $(date -u +%H:%M:%SZ)"
echo "1) getenforce: $(getenforce 2>/dev/null || cat /sys/fs/selinux/enforce)"
case $STEP in
  up)
    mkdir -p /tmp/sel-$D && cd /tmp/sel-$D
    curl -s -O $S/$D/SHA256SUMS; for f in $(awk '{print $2}' SHA256SUMS); do curl -s -O $S/$D/$f; done; sha256sum -c SHA256SUMS
    echo "before: $(rpm -q belgian-azerty-windows keyd-belgian-windows keyd | tr '\n' ' ')"; labels
    echo "2) install"
    if command -v dnf >/dev/null; then sudo dnf install -y ./*.rpm 2>&1 | tail -8
    else sudo zypper -n install --allow-unsigned-rpm ./*.rpm 2>&1 | tail -8; fi
    echo "after: $(rpm -q belgian-azerty-windows keyd-belgian-windows keyd | tr '\n' ' ')"
    echo "3) module: [$(sudo semodule -l | grep belgian_azerty_xkb)]"; labels
    echo "4)"; try be pc105 "" caps:be_windows,be_azerty:accents; echo "vconsole.conf:"; cat /etc/vconsole.conf
    echo "5)"; avc ;;
  after-reboot)
    echo "module: [$(sudo semodule -l | grep belgian_azerty_xkb)]"; labels; localectl status
    echo "5b) AVC this boot:"; sudo journalctl -b --no-pager | grep -iE 'avc.*denied' | grep -iE 'xkb|localed' | tail -5; echo "== end" ;;
  remove)
    echo "8) remove"
    if command -v dnf >/dev/null; then sudo dnf remove -y belgian-azerty-windows 2>&1 | tail -6
    else sudo zypper -n remove belgian-azerty-windows 2>&1 | tail -6; fi
    echo "rpm: $(rpm -q belgian-azerty-windows)"; echo "module: [$(sudo semodule -l | grep belgian_azerty_xkb)]"
    echo "/etc/xkb now: $(find /etc/xkb -type f 2>/dev/null | tr '\n' ' ')"
    try be pc105; avc ;;
esac
up
