#!/bin/bash
# Update from an older belgian-azerty-windows to the new one, then removal, on a DISPOSABLE system (container or VM):
# it installs and purges packages and reinstalls xkb-data. Run as root:
#   tests/xkb-link-upgrade.sh OLD_DIST_DIR NEW_DIST_DIR [xkbupdate]
# Written for xkb-data 2.46+ (Ubuntu 26.04, Debian 14), where /usr/share/X11/xkb is a link to
# /usr/share/xkeyboard-config-2 and versions up to 0.9.10 diverted a name dpkg does not know; it also runs where there is
# no link. "xkbupdate" reinstalls xkb-data between the two versions (under 0.9.10 that removed the rules on 26.04).
# Checks: one diversion of ours, on the real name; each rule once; evdev.distrib = xkb-data's own file; dpkg -V xkb-data
# clean; the rules survive another xkb-data reinstall; after purge the rules file is xkb-data's original.
set -u; export DEBIAN_FRONTEND=noninteractive; FAIL=0
OLDD=$(realpath "${1:?usage: xkb-link-upgrade.sh OLD_DIST_DIR NEW_DIST_DIR [xkbupdate]}"); NEWD=$(realpath "${2:?}")
pass() { echo "PASS  $*"; }; fail() { echo "FAIL  $*"; FAIL=1; }
t() { local d=$1; shift; if "$@" >/dev/null 2>&1; then pass "$d"; else fail "$d"; fi; }
dv() { dpkg -V xkb-data | grep -v '^missing .*/usr/share/\(doc\|man\)/'; }   # containers often leave out docs and man pages
OLD=/usr/share/X11/xkb/rules/evdev; R=$(readlink -f $OLD)
echo "== rules file: $OLD -> $R"
STOCK=$(md5sum < "$R"); echo "xkb-data $(dpkg-query -W -f='${Version}' xkb-data), md5 ${STOCK%% *}"
apt-get install -y "$OLDD"/belgian-azerty-windows_*_all.deb >/dev/null 2>&1; t "old version installed" dpkg-query -W belgian-azerty-windows
OV=$(dpkg-query -W -f='${Version}' belgian-azerty-windows); echo "      $OV: rules count $(grep -c caps:be_windows "$R")"
if [ "${3:-}" = xkbupdate ]; then
  apt-get install -y --reinstall xkb-data >/dev/null 2>&1; echo "      after an xkb-data reinstall: rules count $(grep -c caps:be_windows "$R")"
fi
apt-get install -y "$NEWD"/belgian-azerty-windows_*_all.deb >/dev/null 2>&1
NV=$(dpkg-query -W -f='${Version}' belgian-azerty-windows); echo "      now $NV"; dpkg-divert --list | grep evdev | sed 's/^/      /'
t "new version installed over the old one" test "$NV" != "$OV"
t "exactly one diversion of ours" sh -c "[ \$(dpkg-divert --list | grep -c belgian-azerty-windows) = 1 ]"
t "the diversion is on the real name" sh -c "dpkg-divert --list '$R' | grep -q belgian-azerty-windows"
t "Caps rule present exactly once" sh -c "[ \$(grep -c 'caps:be_windows' '$R') = 1 ]"
t "our two rule blocks present once each" sh -c "[ \$(grep -c '^// belgian-azerty-windows: ' '$R') = 2 ]"
t "evdev.distrib holds none of our rules" sh -c "! grep -q 'belgian-azerty-windows\|caps:be_windows\|be_azerty:' '$R.distrib'"
t "evdev.distrib equals xkb-data's own file" sh -c "[ \"\$(md5sum < '$R.distrib')\" = '$STOCK' ]"
t "dpkg -V xkb-data clean" test -z "$(dv)"
t "keymap with our options compiles" xkbcli compile-keymap --layout be --options caps:be_windows,be_azerty:accents
apt-get install -y --reinstall xkb-data >/dev/null 2>&1
t "after an xkb-data reinstall: Caps rule still once" sh -c "[ \$(grep -c 'caps:be_windows' '$R') = 1 ]"
t "after an xkb-data reinstall: dpkg -V xkb-data clean" test -z "$(dv)"
apt-get purge -y belgian-azerty-windows >/dev/null 2>&1
t "after purge: no diversion of ours" sh -c "! dpkg-divert --list | grep -q belgian-azerty-windows"
t "after purge: rules file identical to xkb-data's original" sh -c "[ \"\$(md5sum < '$R')\" = '$STOCK' ]"
t "after purge: no evdev.distrib" test ! -e "$R.distrib"
[ $FAIL = 0 ] && echo "ALL PASS" || echo "SOME FAILED"; exit $FAIL
