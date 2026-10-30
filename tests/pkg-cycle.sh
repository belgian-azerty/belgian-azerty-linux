#!/bin/bash
# Install / upgrade / trigger / remove cycle of the packages on a DISPOSABLE Ubuntu 24.04 system (container or VM):
# it installs and purges packages and changes xkb-data's rules file. Run as root:  tests/pkg-cycle.sh DIST_DIR
# Checks: the Caps Lock rule is added once (also over a hand-installed older version), survives xkb-data reinstalls by
# apt and by plain dpkg, dpkg -V xkb-data stays clean, the option gives Windows Caps Lock (0 mismatches), and purging
# gives back xkb-data's original file byte for byte. keyd-belgian-windows on top of the keyd-team PPA's keyd (or
# KEYD_DEB=path), and purge.
set -u
D=$(realpath "${1:?usage: pkg-cycle.sh DIST_DIR}"); HERE=$(cd "$(dirname "$0")/.." && pwd)
R=/usr/share/X11/xkb/rules/evdev; FAIL=0
pass() { echo "PASS  $*"; }
fail() { echo "FAIL  $*"; FAIL=1; }
t() { local d=$1; shift; if "$@" >/dev/null 2>&1; then pass "$d"; else fail "$d"; fi; }
rules_count() { grep -c 'caps:be_windows' "$R"; }
# Caps and Caps+Shift rows: 0 mismatches vs Windows. Caps+AltGr row: identical to stock Linux (the one stock
# difference, Caps+AltGr+Z = S instead of the long s, is a letter key the option does not touch).
captest() {
  local out; out=$(python3 "$HERE/tools/captest.py" none caps:be_windows 2>/dev/null)
  local n; n=$(echo "$out" | grep 'caps:be_windows' | grep -c 'mismatches=0')
  local a b; a=$(echo "$out" | sed -n '/caps+altgr/,$p' | grep '  none ' | sed 's/^ *none *//')
  b=$(echo "$out" | sed -n '/caps+altgr/,$p' | grep 'caps:be_windows' | sed 's/^ *caps:be_windows *//')
  [ "$n" = 2 ] && [ "$a" = "$b" ] && echo 3 || echo 0
}
dv() { dpkg -V "$1" | grep -v '^missing .*/usr/share/\(doc\|man\)/'; }   # containers often leave out docs and man pages
export DEBIAN_FRONTEND=noninteractive
STOCK=$(md5sum < "$R")
echo "== start: xkb-data $(dpkg-query -W -f='${Version}' xkb-data), rules md5 ${STOCK%% *}"
t "dpkg -V xkb-data clean before" test -z "$(dv xkb-data)"

echo "== simulate an older be-azerty-fix.sh install (hand-written rule, apt hook, helper, symbols file)"
cp "$HERE/xkb/symbols/be_capslock" /usr/share/X11/xkb/symbols/be_capslock
printf '\n// be-azerty-fix.sh: Caps Lock as on Windows Belgian\n! option\t=\tsymbols\n  caps:be_windows\t=\t+be_capslock(windows)\n' >> "$R"
printf '#!/bin/sh\n# Installed by be-azerty-fix.sh\n' > /usr/local/sbin/be-azerty-xkb-ensure; chmod 755 /usr/local/sbin/be-azerty-xkb-ensure
echo 'DPkg::Post-Invoke { "if [ -x /usr/local/sbin/be-azerty-xkb-ensure ]; then /usr/local/sbin/be-azerty-xkb-ensure || true; fi"; }; // be-azerty' > /etc/apt/apt.conf.d/99be-azerty-xkb

echo "== install belgian-azerty-windows"
apt-get install -y "$D"/belgian-azerty-windows_*_all.deb >/dev/null 2>&1; t "installed" dpkg-query -W belgian-azerty-windows
dpkg-divert --list "$R"
t "rules file diverted to evdev.distrib" sh -c "dpkg-divert --list $R | grep -q belgian-azerty-windows"
[ "$(rules_count)" = 1 ] && pass "rule present exactly once (legacy block dropped)" || fail "rule count $(rules_count)"
t "accents and Apple rules: one per layout position (single, 1-4)" sh -c "[ \$(grep -c 'be_azerty:accents' $R) = 5 ] && [ \$(grep -c 'be_azerty:mac' $R) = 5 ]"
t "keymap with the accents option: Shift+AltGr+ù is dead_acute" sh -c "xkbcli compile-keymap --layout be --options be_azerty:accents | grep -A1 'key <AC11>' | grep -q 'dead_acute, *dead_acute'"
t "console keymap (ckbcomp) with be_azerty:accents and be_azerty:mac" sh -c "! command -v ckbcomp || { ckbcomp -layout be -option be_azerty:accents >/dev/null && ckbcomp -layout be -option be_azerty:mac >/dev/null; }"
t "evdev.distrib has no hand-written block" sh -c "! grep -q caps:be_windows $R.distrib"
t "legacy apt hook and helper removed" sh -c "[ ! -e /etc/apt/apt.conf.d/99be-azerty-xkb ] && [ ! -e /usr/local/sbin/be-azerty-xkb-ensure ]"
t "symbols file owned by the package" sh -c "dpkg -S /usr/share/X11/xkb/symbols/be_capslock | grep -q belgian-azerty-windows"
t "dpkg -V xkb-data clean while installed" test -z "$(dv xkb-data)"
t "dpkg -V belgian-azerty-windows clean" test -z "$(dv belgian-azerty-windows)"
[ "$(captest)" = 3 ] && pass "captest: Caps and Caps+Shift 0 mismatches vs Windows; Caps+AltGr identical to stock Linux" || fail "captest"
python3 "$HERE/tools/captest.py" none caps:be_windows 2>&1 | sed 's/^/      /'

echo "== xkb-data reinstalled by apt"
echo "# marker" >> "$R"; sleep 1   # a stale line: the trigger must regenerate evdev from xkb-data's new file
apt-get install -y --reinstall xkb-data >/dev/null 2>&1
t "trigger ran and regenerated evdev (stale line gone)" sh -c "! grep -q '^# marker' $R"
[ "$(rules_count)" = 1 ] && pass "rule still present once after apt reinstall" || fail "after apt reinstall: $(rules_count)"
echo "== xkb-data installed by plain dpkg -i (no apt hooks run)"
echo "# marker" >> "$R"
(cd /tmp && apt-get download xkb-data >/dev/null 2>&1 && dpkg -i /tmp/xkb-data_*.deb >/dev/null 2>&1)
t "trigger ran under plain dpkg too (stale line gone)" sh -c "! grep -q '^# marker' $R"
[ "$(rules_count)" = 1 ] && pass "rule still present once after dpkg -i" || fail "after dpkg -i: $(rules_count)"
t "dpkg -V xkb-data clean after both" test -z "$(dv xkb-data)"
[ "$(captest)" = 3 ] && pass "captest still 0 mismatches" || fail "captest after reinstall"

echo "== be-azerty-fix keeps the saved choices when run without DECIMAL/CAPS"
mkdir -p /var/lib/belgian-azerty-windows; printf 'DECIMAL=comma\nCAPS=linux\n' > /var/lib/belgian-azerty-windows/choices
t "rerun without DECIMAL/CAPS keeps comma and linux" sh -c "be-azerty-fix live 2>/dev/null | head -1 | grep -q 'decimal comma (kept from the last run), Caps Lock linux (kept'"
t "DECIMAL=period given beats the saved choice" sh -c "DECIMAL=period be-azerty-fix live 2>/dev/null | head -1 | grep -q 'decimal period (given)'"

echo "== be-azerty-fix uninstall-relevant part: override file removed by package removal"
mkdir -p /usr/share/glib-2.0/schemas; echo '# test' > /usr/share/glib-2.0/schemas/zz_belgian-azerty-windows.gschema.override
cp /etc/default/keyboard /tmp/keyboard.before 2>/dev/null
sed -i '/^XKBOPTIONS=/d' /etc/default/keyboard 2>/dev/null; echo 'XKBOPTIONS="lv3:ralt_switch,kpdl:comma,caps:be_windows,be_azerty:accents"' >> /etc/default/keyboard
mkdir -p /etc/modprobe.d; printf 'options hid_apple iso_layout=1\n' > /etc/modprobe.d/belgian-azerty-apple.conf
echo "== purge belgian-azerty-windows"
apt-get purge -y belgian-azerty-windows >/dev/null 2>&1
t "diversion gone" sh -c "! dpkg-divert --list $R | grep -q ."
[ "$(md5sum < "$R")" = "$STOCK" ] && pass "rules file identical to xkb-data's original" || fail "rules file differs from original"
t "no evdev.distrib left" test ! -e "$R.distrib"
t "symbols file gone" test ! -e /usr/share/X11/xkb/symbols/be_capslock
t "Cinnamon override gone" test ! -e /usr/share/glib-2.0/schemas/zz_belgian-azerty-windows.gschema.override
t "caps:be_windows and be_azerty:accents taken out of /etc/default/keyboard, other options kept" grep -qx 'XKBOPTIONS="lv3:ralt_switch,kpdl:comma"' /etc/default/keyboard
t "Apple key setting removed" test ! -e /etc/modprobe.d/belgian-azerty-apple.conf
t "saved choices removed by purge" test ! -e /var/lib/belgian-azerty-windows
[ -f /tmp/keyboard.before ] && cp /tmp/keyboard.before /etc/default/keyboard
t "dpkg -V xkb-data clean after purge" test -z "$(dv xkb-data)"
xkbcli compile-keymap --layout be --options caps:be_windows,be_azerty:accents,be_azerty:mac >/dev/null 2>/tmp/xkbcli.err; t "leftover options of ours in a setting are ignored, keymap still compiles" test $? -eq 0
sed 's/^/      /' /tmp/xkbcli.err

echo "== keyd packages"
# keyd itself comes from the keyd-team PPA (or a .deb given as KEYD_DEB=path); OLD_KEYD=path installs an older keyd first.
if [ -n "${OLD_KEYD:-}" ]; then
  dpkg -i "$OLD_KEYD" >/dev/null 2>&1; echo "older keyd installed first: $(dpkg-query -W keyd)"
fi
apt-get install -y ${KEYD_DEB:-keyd} "$D"/keyd-belgian-windows_*_all.deb > /tmp/keyd-inst.log 2>&1; t "keyd + keyd-belgian-windows installed" sh -c "dpkg-query -W keyd-belgian-windows"
echo "      keyd $(dpkg-query -W -f='${Version}' keyd); conffile owner: $(dpkg -S /etc/keyd/be-winaltgr.conf)"
t "be-winaltgr.conf is a conffile of keyd-belgian-windows" sh -c "dpkg-query -W -f='\${Conffiles}' keyd-belgian-windows | grep -q be-winaltgr.conf"
t "restart drop-in installed" test -f /usr/lib/systemd/system/keyd.service.d/belgian-windows-restart.conf
t "drop-in: Restart=always, exit status 15 (SIGTERM) counts as a clean stop" sh -c "grep -qx 'Restart=always' /usr/lib/systemd/system/keyd.service.d/belgian-windows-restart.conf && grep -q '^SuccessExitStatus=.*15' /usr/lib/systemd/system/keyd.service.d/belgian-windows-restart.conf"
t "keyd parses the rules (keyd.rvaiya check)" sh -c "keyd.rvaiya check /etc/keyd/be-winaltgr.conf 2>&1 | grep -qv -i error || keyd.rvaiya check /etc/keyd/be-winaltgr.conf"
apt-get purge -y keyd-belgian-windows keyd >/dev/null 2>&1
t "after purge: no be-winaltgr.conf, no drop-in, no keyd" sh -c "[ ! -e /etc/keyd/be-winaltgr.conf ] && [ ! -e /usr/lib/systemd/system/keyd.service.d/belgian-windows-restart.conf ] && ! dpkg-query -W keyd 2>/dev/null | grep -q ."
echo; [ "$FAIL" = 0 ] && echo "ALL PASS" || echo "SOME FAILED"; exit $FAIL
