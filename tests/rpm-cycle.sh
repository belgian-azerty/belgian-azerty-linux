#!/bin/bash
# Fedora or openSUSE package cycle, in a DISPOSABLE container or VM, as root (no systemd needed):
#   tests/rpm-cycle.sh RPM_DIR
# RPM_DIR holds belgian-azerty-windows-*.noarch.rpm, keyd-belgian-windows-*.noarch.rpm and their .src.rpm, plus (Fedora
# only, which has no keyd) keyd-2*.x86_64.rpm. Checks install, the keyboard options, an update of xkeyboard-config, an
# upgrade to a rebuilt release, removal, and that files of the user's own in /etc/xkb and /etc/keyd are kept.
set -u; D=$(realpath "${1:?usage: rpm-cycle.sh RPM_DIR}"); ROOT=$(cd "$(dirname "$0")/.." && pwd); FAIL=0
pass() { echo "PASS  $*"; }; fail() { echo "FAIL  $*"; FAIL=1; }
t() { local d=$1; shift; if "$@" >/dev/null 2>&1; then pass "$d"; else fail "$d"; fi; }
if command -v dnf >/dev/null; then PMN=dnf
  inst() { dnf -y install "$@"; }; reinst() { dnf -y reinstall "$@"; }; rem() { dnf -y remove "$@"; }
  dnf -q -y install libxkbcommon-utils xkeyboard-config python3 python3-cffi libxkbcommon diffutils util-linux \
    shadow-utils rpm-build systemd-rpm-macros >/dev/null 2>&1 || { echo "FAIL  dnf install"; exit 1; }
  OURS=("$D"/keyd-2*.x86_64.rpm "$D"/keyd-belgian-windows-0*.noarch.rpm "$D"/belgian-azerty-windows-0*.noarch.rpm)
else PMN=zypper
  inst() { zypper -n --no-gpg-checks install -y --allow-unsigned-rpm "$@"; }   # no -q: it hides the packages' messages
  reinst() { zypper -n install -y -f "$@"; }; rem() { zypper -n remove -y "$@"; }
  zypper -q -n refresh >/dev/null 2>&1
  zypper -q -n install -y xkeyboard-config libxkbcommon-tools python3 python3-cffi diffutils util-linux shadow gawk \
    rpm-build systemd-rpm-macros >/dev/null 2>&1 || { echo "FAIL  zypper install"; exit 1; }
  OURS=("$D"/keyd-belgian-windows-0*.noarch.rpm "$D"/belgian-azerty-windows-0*.noarch.rpm)   # keyd: openSUSE's own
fi
OPTS=caps:be_windows,be_azerty:accents
known() { ! xkbcli compile-keymap --layout be --options "$OPTS" 2>&1 | grep -q Unrecognized; }
echo "== $(. /etc/os-release; echo "$PRETTY_NAME"), $(rpm -q xkeyboard-config | tr '\n' ' ')"
t "before: our options unknown" sh -c 'xkbcli compile-keymap --layout be --options caps:be_windows 2>&1 | grep -q Unrecognized'
t "xkeyboard-config clean before" test -z "$(rpm -V xkeyboard-config)"
if [ "${SELINUX_POLICY:-0}" = 1 ]; then   # the SELinux policy present (as on a real Fedora/openSUSE), not enforcing here
  if [ $PMN = dnf ]; then dnf -q -y install selinux-policy-targeted policycoreutils libselinux-utils setools-console >/dev/null 2>&1
  else zypper -q -n install -y selinux-policy-targeted policycoreutils libselinux-utils setools-console >/dev/null 2>&1; fi
  t "SELinux policy installed; /etc/xkb is etc_t before" sh -c 'matchpathcon /etc/xkb/rules/evdev | grep -q ":etc_t:"'
fi
inst "${OURS[@]}" >/tmp/i.log 2>&1
if [ "${SELINUX_POLICY:-0}" = 1 ]; then
  t "SELinux: our label module added, /etc/xkb files get usr_t" sh -c 'semodule -l | grep -qx belgian_azerty_xkb && matchpathcon /etc/xkb/rules/evdev /etc/xkb/symbols/be_capslock | grep -c ":usr_t:" | grep -qx 2'
  t "SELinux: the module in the package is the one in packaging/selinux" cmp -s /usr/share/selinux/packages/belgian-azerty-windows/belgian_azerty_xkb.cil "$ROOT"/packaging/selinux/belgian_azerty_xkb.cil
  t "SELinux: localed may map usr_t files (policy rule)" sh -c 'command -v sesearch >/dev/null || exit 0; sesearch -A -s systemd_localed_t -t usr_t -c file -p map | grep -q map'
fi
t "installed (keyd included)" rpm -q keyd keyd-belgian-windows belgian-azerty-windows
rpm -q keyd keyd-belgian-windows belgian-azerty-windows | sed 's/^/      /'
t "rpm -V of ours and of keyd clean, xkeyboard-config still clean" test -z "$(rpm -V keyd keyd-belgian-windows belgian-azerty-windows xkeyboard-config)"
if keyd --version 2>&1 | grep -q 'v2\.[6-9]'; then t "keyd check: our rules have no errors" sh -c 'keyd check /etc/keyd/be-winaltgr.conf 2>&1 | grep -q "No errors found"'
else echo "      $(keyd --version 2>&1 | head -1): no 'keyd check' before 2.6.0 (tests/keyd-rules.sh covers the rules)"; fi
t "keyd service file and our restart drop-in in place" test -f /usr/lib/systemd/system/keyd.service -a -f /usr/lib/systemd/system/keyd.service.d/belgian-windows-restart.conf
t "options known" known
if python3 -c 'import xkbcommon' 2>/dev/null; then   # pip install xkbcommon==1.5.1 (needs the libxkbcommon headers)
  c=$(python3 "$ROOT"/tools/captest.py none caps:be_windows 2>/dev/null)
  t "Caps and Caps+Shift: 0 mismatches vs Windows" test "$(echo "$c" | grep caps:be_windows | head -2 | grep -c mismatches=0)" = 2
  o=$(python3 "$ROOT"/tools/optiontest.py be be_azerty:accents | tail -1); t "accents option: 3 changes" test "$o" = "differences: 3"
  m=$(python3 "$ROOT"/tools/optiontest.py be be_azerty:mac fr:mac ""); t "Apple option: plain/Shift = French (Macintosh)" test -z "$(echo "$m" | grep -E ' (base|shift):')"
else echo "      python module xkbcommon not installed: key-by-key checks skipped"; fi
useradd -m tester 2>/dev/null; u=$(su tester -c "xkbcli compile-keymap --layout be --options $OPTS" 2>&1)
t "a normal user gets the options" sh -c 'echo "$0" | grep -q "^xkb_keymap" && ! echo "$0" | grep -q Unrecognized' "$u"
reinst xkeyboard-config >/dev/null 2>&1
t "xkeyboard-config reinstalled (stands for an update): options still known, ours untouched" sh -c "! xkbcli compile-keymap --layout be --options $OPTS 2>&1 | grep -q Unrecognized && [ -z \"\$(rpm -V belgian-azerty-windows)\" ]"
for p in belgian-azerty-windows keyd-belgian-windows; do rpmbuild --rebuild --define "dist .t2" "$D"/$p-0*.src.rpm >/tmp/rb-$p.log 2>&1; done
inst "$(rpm --eval %_topdir)"/RPMS/noarch/*.t2.noarch.rpm >/tmp/u.log 2>&1
t "upgrade to a rebuilt release: upgraded, options known, rpm -V clean" sh -c "[ \$(rpm -q belgian-azerty-windows keyd-belgian-windows | grep -c t2) = 2 ] && ! xkbcli compile-keymap --layout be --options $OPTS 2>&1 | grep -q Unrecognized && [ -z \"\$(rpm -V belgian-azerty-windows keyd-belgian-windows)\" ]"
rem belgian-azerty-windows keyd-belgian-windows >/dev/null 2>&1
t "removed: our files gone, keyd stays" sh -c '! rpm -q belgian-azerty-windows && ! rpm -q keyd-belgian-windows && [ ! -e /etc/xkb/rules/evdev ] && [ ! -e /etc/xkb/symbols/be_capslock ] && [ ! -e /etc/keyd/be-winaltgr.conf ] && rpm -q keyd'
t "after removal: options unknown, keymap compiles, xkeyboard-config clean" sh -c 'xkbcli compile-keymap --layout be --options caps:be_windows 2>&1 | grep -q Unrecognized && xkbcli compile-keymap --layout be >/dev/null && [ -z "$(rpm -V xkeyboard-config)" ]'
if [ "${SELINUX_POLICY:-0}" = 1 ]; then
  t "SELinux: module removed with the package, /etc/xkb back to etc_t" sh -c '! semodule -l | grep -qx belgian_azerty_xkb && matchpathcon /etc/xkb/rules/evdev | grep -q ":etc_t:"'
fi
# a user with files of their own in /etc/xkb and /etc/keyd
mkdir -p /etc/xkb/symbols /etc/xkb/rules /etc/keyd
printf '// my own layout\nxkb_symbols "x" { include "be" };\n' > /etc/xkb/symbols/mine
printf '! include %%S/evdev\n// my own rules\n' > /etc/xkb/rules/evdev; cp /etc/xkb/rules/evdev /tmp/my-evdev
printf '[ids]\n*\n[main]\ncapslock = esc\n' > /etc/keyd/my.conf
inst "${OURS[@]}" >/tmp/i2.log 2>&1
t "their own symbols file and keyd config kept" test -f /etc/xkb/symbols/mine -a -f /etc/keyd/my.conf
t "their own rules file kept, ours beside it as .rpmnew" sh -c 'cmp -s /etc/xkb/rules/evdev /tmp/my-evdev && grep -q caps:be_windows /etc/xkb/rules/evdev.rpmnew'
t "the packages say so (rules file kept; keyd one config per keyboard)" sh -c 'grep -q "already there and is kept" /tmp/i2.log && grep -q "keyd uses one configuration per keyboard" /tmp/i2.log'
# be-azerty-fix knows Debian/Ubuntu and Fedora only: elsewhere it must stop and change nothing
if ! grep -q '^ID=["]*fedora' /etc/os-release; then
  cp -a /etc/xkb /tmp/xkb-before; bash "$ROOT"/be-azerty-fix.sh check > /tmp/fix.log 2>&1; rc=$?
  t "be-azerty-fix stops on this system (exit $rc) and changes nothing" sh -c "[ $rc != 0 ] && grep -q 'changes' /tmp/fix.log && grep -q 'nothing' /tmp/fix.log && diff -r /tmp/xkb-before /etc/xkb"
fi
[ "$FAIL" = 0 ] && echo "ALL PASS" || echo "SOME FAILED"
