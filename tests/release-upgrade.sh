#!/bin/bash
# Full system upgrade with the package installed, on a DISPOSABLE plain Ubuntu 24.04 or Debian 13 container or VM (it
# switches the system's package sources and upgrades everything). Run as root:
#   tests/release-upgrade.sh NEW_DIST_DIR OLD_DIST_DIR SCENARIO TARGET
# SCENARIO: fresh (new version installed), from-old (old version, then the new one), removed (new version installed,
# then removed but not purged), recover-old (old version installed, the upgrade stops, then the way out the README
# gives: dpkg -r the package, finish the upgrade, install the new version). TARGET: resolute (Ubuntu 26.04) or sid (Debian unstable, the base of Debian 14).
# Checks that the upgrade to xkb-data 2.46+ goes through (xkb-move steps our files aside), that our rules come back
# once on the real name, and that purge afterwards leaves nothing. No systemd needed.
export DEBIAN_FRONTEND=noninteractive; NEWD=$(realpath "${1:?usage: release-upgrade.sh NEW_DIST OLD_DIST SCENARIO TARGET}")
OLDD=$(realpath "${2:?}"); SC=${3:?}; T=${4:?}; FAIL=0
pass() { echo "PASS  $*"; }; fail() { echo "FAIL  $*"; FAIL=1; }
t() { local d=$1; shift; if "$@" >/dev/null 2>&1; then pass "$d"; else fail "$d"; fi; }
O="-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"
apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq libxkbcommon-tools >/dev/null 2>&1
case $SC in
  fresh)    apt-get install -y $NEWD/belgian-azerty-windows_*_all.deb >/dev/null 2>&1 ;;
  from-old) apt-get install -y $OLDD/belgian-azerty-windows_*_all.deb >/dev/null 2>&1
            apt-get install -y $NEWD/belgian-azerty-windows_*_all.deb >/dev/null 2>&1 ;;
  recover-old) apt-get install -y $OLDD/belgian-azerty-windows_*_all.deb >/dev/null 2>&1 ;;
  removed)  apt-get install -y $NEWD/belgian-azerty-windows_*_all.deb >/dev/null 2>&1; apt-get remove -y belgian-azerty-windows >/dev/null 2>&1 ;;
esac
echo "== scenario $SC: ours $(dpkg-query -W -f='${Version} ${db:Status-Abbrev}' belgian-azerty-windows 2>/dev/null)"
apt-get install -y -qq less >/tmp/other.log 2>&1
t "an unrelated apt install: hook silent, no mark" sh -c '! grep -q "belgian-azerty-windows:" /tmp/other.log && [ ! -e /var/lib/belgian-azerty-windows/xkb-move-pending ]'
if [ "$T" = resolute ]; then sed -i 's/noble/resolute/g' /etc/apt/sources.list.d/ubuntu.sources
else printf 'Types: deb
URIs: http://deb.debian.org/debian
Suites: sid
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp
' > /etc/apt/sources.list.d/debian.sources; fi
apt-get update -qq >/dev/null 2>&1
apt-get -y $O dist-upgrade > /tmp/up.log 2>&1; rc=$?
if [ "$SC" = recover-old ]; then
  t "old version: the upgrade stops (as known)" test $rc != 0
  # apt refuses every removal while packages are half-installed ("Unmet dependencies"); dpkg -r works (README)
  apt-get remove -y belgian-azerty-windows > /tmp/rm0.log 2>&1; echo "      apt-get remove in the stopped state: rc $?"
  dpkg -r belgian-azerty-windows > /tmp/rm.log 2>&1; t "old version can be removed in the stopped state (dpkg -r)" test $? = 0
  apt-get -y $O -f install > /tmp/up2.log 2>&1; rc=$?
  apt-get -y $O dist-upgrade >> /tmp/up2.log 2>&1 || rc=1
  apt-get install -y $NEWD/belgian-azerty-windows_*_all.deb > /tmp/inst.log 2>&1 || rc=1
fi
t "full upgrade succeeds (rc 0)" test $rc = 0
grep -h "belgian-azerty-windows:" /tmp/up.log | sort -u | sed 's/^/      /'
t "no package left half-installed" test -z "$(dpkg -l | awk 'NR>5 && $1!="ii" && $1!="rc"')"
t "xkb-data 2.46+ installed, folder is now a link" sh -c 'dpkg --compare-versions "$(dpkg-query -W -f="\${Version}" xkb-data)" ge 2.46~ && [ -L /usr/share/X11/xkb ]'
R=$(readlink -f /usr/share/X11/xkb/rules/evdev)
t "no mark left" test ! -e /var/lib/belgian-azerty-windows/xkb-move-pending
if [ "$SC" = removed ]; then
  t "removed package: nothing of ours in the rules" sh -c "! grep -q 'belgian-azerty-windows\|caps:be_windows' '$R'"
  t "removed package: no diversion" sh -c '! dpkg-divert --list | grep -q belgian-azerty-windows'
else
  t "ours still installed (ii)" sh -c 'dpkg-query -W -f="\${db:Status-Abbrev}" belgian-azerty-windows | grep -q "^ii"'
  t "one diversion, on the real name" sh -c "[ \$(dpkg-divert --list | grep -c belgian-azerty-windows) = 1 ] && dpkg-divert --list '$R' | grep -q belgian-azerty-windows"
  t "Caps rule once, two blocks" sh -c "[ \$(grep -c caps:be_windows '$R') = 1 ] && [ \$(grep -c '^// belgian-azerty-windows: ' '$R') = 2 ]"
  t "evdev.distrib holds none of ours" sh -c "! grep -q 'belgian-azerty-windows\|caps:be_windows\|be_azerty:' '$R.distrib'"
  (cd /tmp && apt-get download -qq xkb-data >/dev/null 2>&1)
  STOCK=$(dpkg-deb --fsys-tarfile /tmp/xkb-data_*_all.deb | tar -xOf - ./usr/share/xkeyboard-config-2/rules/evdev | md5sum)
  t "evdev.distrib = the new xkb-data's own file" test "$(md5sum < "$R.distrib")" = "$STOCK"
  t "dpkg -V xkb-data clean" test -z "$(dpkg -V xkb-data | grep -v '/usr/share/\(doc\|man\)/')"
  t "dpkg -V belgian-azerty-windows clean" test -z "$(dpkg -V belgian-azerty-windows | grep -v '/usr/share/\(doc\|man\)/')"
  t "options known, keymap compiles" sh -c '! xkbcli compile-keymap --layout be --options caps:be_windows,be_azerty:accents,be_azerty:mac 2>&1 >/dev/null | grep -q . && xkbcli compile-keymap --layout be --options caps:be_windows >/dev/null'
  apt-get install -y --reinstall xkb-data >/dev/null 2>&1
  t "after another xkb-data reinstall: rule still once" sh -c "[ \$(grep -c caps:be_windows '$R') = 1 ]"
  apt-get purge -y belgian-azerty-windows >/dev/null 2>&1
  t "purge: no diversion, no distrib, no symbols file, no mark" sh -c "! dpkg-divert --list | grep -q belgian-azerty-windows && [ ! -e '$R.distrib' ] && [ ! -e \$(readlink -f /usr/share/X11/xkb/symbols)/be_capslock ] && [ ! -e /var/lib/belgian-azerty-windows ]"
  t "purge: rules file free of ours, dpkg -V xkb-data clean" sh -c "! grep -q 'caps:be_windows' '$R' && [ -z \"\$(dpkg -V xkb-data | grep -v '/usr/share/\(doc\|man\)/')\" ]"
  t "purge: apt hook file gone" test ! -e /etc/apt/apt.conf.d/50belgian-azerty-windows-xkb-move
  apt-get install -y -qq less >/tmp/other2.log 2>&1; t "apt still works after purge" test $? = 0
fi
[ "$FAIL" = 0 ] && echo "ALL PASS" || echo "SOME FAILED"
