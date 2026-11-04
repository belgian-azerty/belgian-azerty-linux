#!/bin/bash
# Full system upgrade Ubuntu 24.04 -> 26.04 (xkb-data 2.41 -> 2.46+, the keyboard folder becomes a link) with both
# world-keyboard-windows and belgian-azerty-windows installed, on a DISPOSABLE container or VM. Run as root:
#   world/tests/upgrade-2604.sh BELGIAN_DEB WORLD_DEB REPO_DIR [world-only]
# Checks that the upgrade goes through (our files step aside and come back), that both packages still work on the
# new folder, and that purge leaves nothing. world-only: without the Belgian package. No systemd needed.
set -u; export DEBIAN_FRONTEND=noninteractive; FAIL=0
BE=$(realpath "$1"); WO=$(realpath "$2"); REPO=$(realpath "$3"); MODE=${4:-both}
pass() { echo "PASS  $*"; }; fail() { echo "FAIL  $*"; FAIL=1; }
t() { local d=$1; shift; if "$@" >/dev/null 2>&1; then pass "$d"; else fail "$d"; fi; }
O="-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"
[ "$MODE" = world-only ] || apt-get install -y --no-install-recommends "$BE" >/dev/null 2>&1
apt-get install -y "$WO" >/dev/null 2>&1
echo "== mode $MODE, xkb-data $(dpkg-query -W -f='${Version}' xkb-data)"
t "world package installed" sh -c 'dpkg-query -W -f="\${db:Status-Abbrev}" world-keyboard-windows | grep -q ^ii'
sed -i 's/noble/resolute/g' /etc/apt/sources.list.d/ubuntu.sources
apt-get update -qq >/dev/null 2>&1
apt-get -y $O dist-upgrade > /tmp/up.log 2>&1; rc=$?
t "full upgrade succeeds (rc 0)" test $rc = 0
[ $rc = 0 ] || tail -20 /tmp/up.log
grep -h "world-keyboard-windows:\|belgian-azerty-windows:" /tmp/up.log | sort -u | sed 's/^/      /'
t "no package left half-installed" test -z "$(dpkg -l | awk 'NR>5 && $1!="ii" && $1!="rc"')"
t "xkb-data 2.46+ installed, folder is now a link" sh -c 'dpkg --compare-versions "$(dpkg-query -W -f="\${Version}" xkb-data)" ge 2.46~ && [ -L /usr/share/X11/xkb ]'
echo "      xkb-data now $(dpkg-query -W -f='${Version}' xkb-data); /usr/share/X11/xkb -> $(readlink /usr/share/X11/xkb)"
SYM=$(readlink -f /usr/share/X11/xkb/symbols)
t "no mark left" test ! -e /var/lib/world-keyboard-windows/xkb-move-pending
for f in de_windows ch_windows pl_windows; do t "$f back in the new folder ($SYM)" sh -c "head -1 $SYM/$f | grep -q gen_windows_symbols"; done
XML=$(readlink -f /usr/share/X11/xkb/rules/evdev.xml)
t "system list on the real name diverted by us, our 3 layouts in it once" sh -c "dpkg-divert --list '$XML' | grep -q world-keyboard-windows && [ \$(dpkg-divert --list | grep -c world-keyboard-windows) = 1 ] && [ \$(grep -c '<name>de_windows</name>' '$XML') = 1 ] && grep -q '<name>pl_windows</name>' '$XML'"
t "evdev.xml.distrib = the new xkb-data's own list" sh -c "(cd /tmp && apt-get download -qq xkb-data) && [ \"\$(dpkg-deb --fsys-tarfile /tmp/xkb-data_*_all.deb | tar -xOf - ./usr/share/xkeyboard-config-2/rules/evdev.xml | md5sum)\" = \"\$(md5sum < '$XML.distrib')\" ]"
t "our layouts compile on the new system" sh -c 'xkbcli compile-keymap --layout de_windows >/dev/null && xkbcli compile-keymap --layout ch_windows --variant fr >/dev/null && xkbcli compile-keymap --layout pl_windows >/dev/null'
if [ "$MODE" != world-only ]; then
  t "Belgian package still installed (ii)" sh -c 'dpkg-query -W -f="\${db:Status-Abbrev}" belgian-azerty-windows | grep -q "^ii"'
  t "Belgian options still known" sh -c '! xkbcli compile-keymap --layout be --options caps:be_windows,be_azerty:accents 2>&1 >/dev/null | grep -q .'
  t "Belgian + ours together" xkbcli compile-keymap --layout be,de_windows --options caps:be_windows
fi
t "dpkg -V xkb-data clean" test -z "$(dpkg -V xkb-data | grep -v '/usr/share/\(doc\|man\)/')"
if command -v python3 >/dev/null; then
  python3 -I "$REPO/world/tools/check_windows_symbols.py" "$REPO/world/pilot.tsv" "$REPO/world/cldr-43" /usr/share/X11/xkb > /tmp/check-2604.txt 2>&1
  t "machine check on xkb-data 2.46+: no key differs from Windows, nothing lost" test $? = 0
  grep -v '^    left' /tmp/check-2604.txt | sed 's/^/      /'
fi
apt-get purge -y world-keyboard-windows >/dev/null 2>&1
t "purge: system list back to xkb-data's file, no diversion" sh -c "! dpkg-divert --list | grep -q world-keyboard-windows && [ ! -e '$XML.distrib' ] && ! grep -q _windows '$XML'"
t "purge: nothing of ours left" sh -c "! ls $SYM/*_windows && [ ! -e /etc/apt/apt.conf.d/50world-keyboard-windows-xkb-move ] && [ ! -d /var/lib/world-keyboard-windows ]"
[ "$MODE" = world-only ] || t "Belgian options still known after our purge" sh -c '! xkbcli compile-keymap --layout be --options caps:be_windows 2>&1 >/dev/null | grep -q .'
apt-get install -y -qq less >/tmp/other2.log 2>&1; t "apt still works after purge" test $? = 0
[ "$FAIL" = 0 ] && echo "ALL PASS" || echo "SOME FAILED"; exit $FAIL
