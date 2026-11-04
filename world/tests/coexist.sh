#!/bin/bash
# world-keyboard-windows next to belgian-azerty-windows, on a DISPOSABLE Ubuntu 24.04 container or VM (installs and
# purges packages, edits /etc/default/keyboard). Run as root:
#   world/tests/coexist.sh BELGIAN_DEB WORLD_DEB REPO_DIR
# Checks: installing, removing and purging the world package leaves every file of the Belgian package, the rules
# file, its diversion and xkb-data's own files exactly as they were; our layouts compile (libxkbcommon and xkbcomp)
# and type like Windows; the Belgian options still compile with them; a system default that names one of our layouts
# gets the Linux layout back on removal; removing the Belgian package leaves ours alone.
set -u; export DEBIAN_FRONTEND=noninteractive; FAIL=0
BE=$(realpath "$1"); WO=$(realpath "$2"); REPO=$(realpath "$3")
TAB=$REPO/world/layouts.tsv; LAYS=$(tail -n +2 "$TAB" | cut -f4 | awk '!s[$0]++'); NL=$(echo $LAYS | wc -w)
pass() { echo "PASS  $*"; }; fail() { echo "FAIL  $*"; FAIL=1; }
t() { local d=$1; shift; if "$@" >/dev/null 2>&1; then pass "$d"; else fail "$d"; fi; }
SYM=$(readlink -f /usr/share/X11/xkb/symbols); RULES=$(readlink -f /usr/share/X11/xkb/rules/evdev)
dv() { dpkg -V xkb-data | grep -v '^missing .*/usr/share/\(doc\|man\)/'; }
snap() {   # everything of the Belgian package and of xkb-data's keyboard folder that must not change
  { dpkg -L belgian-azerty-windows 2>/dev/null | while read -r f; do [ -f "$f" ] && sha256sum "$f"; done
    sha256sum "$RULES" "$RULES.distrib" 2>/dev/null; dpkg-divert --list | grep -v world-keyboard-windows | sort
    find /usr/share/X11/xkb/ "$SYM/" -type f ! -name '*_windows' ! -name 'evdev.xml' ! -name 'evdev.xml.distrib' -exec sha256sum {} + 2>/dev/null | sort
    cat /etc/default/keyboard; dpkg-query -W -f='${Package} ${Version} ${db:Status-Abbrev}\n' belgian-azerty-windows; } | sort
}
cmpx() { xkbcomp -w 0 -I/usr/share/X11/xkb -xkb - /dev/null <<K
xkb_keymap { xkb_keycodes { include "evdev+aliases(qwerty)" }; xkb_types { include "complete" };
xkb_compat { include "complete" }; xkb_symbols { include "$1" }; xkb_geometry { include "pc(pc105)" }; };
K
}
apt-get install -y --no-install-recommends "$BE" >/dev/null 2>&1; t "Belgian package installed" dpkg-query -W belgian-azerty-windows
t "Belgian options compile before" xkbcli compile-keymap --layout be --options caps:be_windows,be_azerty:accents
snap > /tmp/before; XML=$(readlink -f /usr/share/X11/xkb/rules/evdev.xml); XMLSUM=$(sha256sum < "$XML")
apt-get install -y "$WO" >/tmp/world-install.log 2>&1; t "world package installed" dpkg-query -W world-keyboard-windows
snap > /tmp/after-install
t "Belgian package, rules, diversion, xkb-data files unchanged after install" cmp /tmp/before /tmp/after-install
t "dpkg -V xkb-data clean" test -z "$(dv)"
for f in $LAYS; do t "$SYM/$f present, ours" sh -c "head -1 $SYM/$f | grep -q gen_windows_symbols"; done
t "system list diverted by us, xkb-data's file kept as evdev.xml.distrib" sh -c "dpkg-divert --list '$XML' | grep -q world-keyboard-windows && [ \"\$(sha256sum < '$XML.distrib')\" = '$XMLSUM' ]"
t "system list = xkb-data's list plus our $NL layouts (what Cinnamon reads)" python3 -c "
import xml.etree.ElementTree as E
n=lambda p:[l.find('configItem/name').text for l in E.parse(p).getroot().find('layoutList')]
a,b=n('$XML.distrib'),n('$XML'); assert b[:len(a)]==a and b[len(a):]=='$(echo $LAYS)'.split(),b[len(a):]"
t "Belgian rules diversion still there" sh -c "dpkg-divert --list | grep -q 'evdev.distrib.*belgian-azerty-windows'"
xkbcli list > /tmp/list.yaml 2>/dev/null
t "libxkbregistry: each of our layouts and variants listed once" python3 -c "
import collections,re
got=collections.Counter(re.findall(r\"layout: '([a-z]+_windows)'\",open('/tmp/list.yaml').read()))
want=collections.Counter(l.split('\t')[3] for l in open('$TAB').read().splitlines()[1:])
assert got==want,(got,want)"
t "no second list in /etc/xkb (the system list holds ours)" test ! -e /etc/xkb/rules/evdev.xml
t "libxkbregistry lists de_windows, ch_windows(fr), pl_windows next to the system layouts" sh -c "xkbcli list > /tmp/list.yaml && grep -q 'layout: .de_windows' /tmp/list.yaml && grep -q 'layout: .pl_windows' /tmp/list.yaml && grep -A1 'layout: .ch_windows' /tmp/list.yaml | grep -q 'variant: .fr' && grep -q 'layout: .be.' /tmp/list.yaml"
t "our files belong to no package (xkb-data can switch the folder later)" sh -c "! dpkg -S $SYM/de_windows"
tail -n +2 "$TAB" | cut -f4,5 | tr '\t' ' ' > /tmp/rows
while read -r l; do set -- $l
  t "libxkbcommon compiles $1($2)" xkbcli compile-keymap --layout "$1" --variant "$2"
  t "xkbcomp (X11) compiles $1($2)" cmpx "pc+$1($2)+inet(evdev)"
done < /tmp/rows
t "Belgian layout with its options plus de_windows compiles" xkbcli compile-keymap --layout be,de_windows --options caps:be_windows,be_azerty:accents
t "xkbcomp: be(Belgian options)+ch_windows(fr) as second layout" cmpx "pc+be+ch_windows(fr):2+inet(evdev)+be_capslock(windows)"
echo "-- machine check against Windows, files as installed --"
python3 -I "$REPO/world/tools/check_windows_symbols.py" "$REPO/world/layouts.tsv" "$REPO/world/cldr-43" /usr/share/X11/xkb /tmp/check.json
t "machine check on the installed files: no key differs from Windows, nothing lost" test $? = 0
# a system default naming our layouts, then removal
sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="be,ch_windows,ca_windows"/; s/^XKBVARIANT=.*/XKBVARIANT=",fr,"/' /etc/default/keyboard
grep -q '^XKBVARIANT=' /etc/default/keyboard || echo 'XKBVARIANT=",fr,"' >> /etc/default/keyboard
apt-get remove -y world-keyboard-windows >/tmp/world-remove.log 2>&1; t "world package removed" sh -c "! dpkg-query -W -f='\${db:Status-Abbrev}' world-keyboard-windows | grep -q ii"
t "our files gone after remove" sh -c "! ls $SYM/*_windows"
t "our layout list gone after remove" test ! -e /etc/xkb/rules/evdev.xml
t "system list back to xkb-data's own file, no diversion of ours" sh -c "[ \"\$(sha256sum < '$XML')\" = '$XMLSUM' ] && [ ! -e '$XML.distrib' ] && ! dpkg-divert --list | grep -q world-keyboard-windows"
t "/etc/default/keyboard back to Linux layouts (be,ch,ca / ,fr,fr-legacy)" sh -c "grep -qx 'XKBLAYOUT=\"be,ch,ca\"' /etc/default/keyboard && grep -qx 'XKBVARIANT=\",fr,fr-legacy\"' /etc/default/keyboard"
grep '^XKB' /etc/default/keyboard | sed 's/^/      /'
sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="be"/; s/^XKBVARIANT=.*/XKBVARIANT=""/' /etc/default/keyboard
snap > /tmp/after-remove; sed -n '/XKB/p' /tmp/before > /dev/null
if diff <(grep -v "^XKB" /tmp/before) <(grep -v "^XKB" /tmp/after-remove) > /tmp/d-remove; then pass "Belgian package, rules, diversion, xkb-data files unchanged after remove"; else fail "Belgian package, rules, diversion, xkb-data files unchanged after remove"; head -20 /tmp/d-remove; fi
apt-get install -y "$WO" >/dev/null 2>&1; apt-get purge -y world-keyboard-windows >/dev/null 2>&1
t "after purge: no diversion of ours, system list original" sh -c "! dpkg-divert --list | grep -q world-keyboard-windows && [ \"\$(sha256sum < '$XML')\" = '$XMLSUM' ]"
t "after purge: nothing of ours left" sh -c "! ls $SYM/*_windows && [ ! -e /etc/apt/apt.conf.d/50world-keyboard-windows-xkb-move ] && [ ! -d /usr/lib/world-keyboard-windows ] && [ ! -d /var/lib/world-keyboard-windows ] && [ ! -e /etc/xkb/rules/evdev.xml ]"
t "dpkg -V xkb-data clean after purge" test -z "$(dv)"
# the other way round: ours installed, the Belgian package goes
apt-get install -y "$WO" >/dev/null 2>&1; sha256sum $SYM/*_windows > /tmp/ours
apt-get purge -y belgian-azerty-windows >/dev/null 2>&1
t "Belgian package purged with ours installed" sh -c "! dpkg-query -W -f='\${db:Status-Abbrev}' belgian-azerty-windows 2>/dev/null | grep -q ii"
t "our files unchanged after the Belgian purge" sha256sum -c /tmp/ours
t "our layouts still compile without the Belgian package" xkbcli compile-keymap --layout de_windows
apt-get install -y --reinstall xkb-data >/dev/null 2>&1
t "after an xkb-data reinstall: our entries rebuilt into the system list, once" sh -c "[ \$(grep -c '<name>de_windows</name>' '$XML') = 1 ] && [ \"\$(sha256sum < '$XML.distrib')\" = '$XMLSUM' ]"
t "after an xkb-data reinstall: dpkg -V xkb-data clean" test -z "$(dv)"
apt-get install -y -qq less >/tmp/other.log 2>&1
t "an unrelated apt install: our hook silent, no mark" sh -c '! grep -q "world-keyboard-windows:" /tmp/other.log && [ ! -e /var/lib/world-keyboard-windows/xkb-move-pending ]'
echo; [ $FAIL = 0 ] && echo "ALL PASS" || echo "SOME FAILED"; exit $FAIL
