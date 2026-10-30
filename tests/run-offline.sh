#!/bin/bash
# One command for every test that needs no virtual machine. Run from anywhere on Ubuntu 24.04:
#   tests/run-offline.sh [ISO...]            static checks, package build + lintian, Caps Lock table check,
#                                            and for each ISO given: full checksum check of its md5sum.txt
#   sudo DISPOSABLE=1 tests/run-offline.sh   additionally the install/upgrade/purge cycle (tests/pkg-cycle.sh), which
#                                            changes this system's packages: only in a throwaway container or VM
# Needs: shellcheck debhelper devscripts lintian xorriso python3 libxkbcommon-tools, python3 module xkbcommon
# (pip install xkbcommon).
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd); FAIL=0
step() { echo; echo "### $*"; }
res() { if [ "$1" = 0 ]; then echo "PASS  $2"; else echo "FAIL  $2"; FAIL=1; fi; }

step "shellcheck (warnings and errors)"
shellcheck -S warning "$ROOT"/be-azerty-fix.sh "$ROOT"/tools/make_belgian_iso.sh "$ROOT"/packaging/*.sh \
  "$ROOT"/packaging/belgian-azerty-windows/update-xkb-rules "$ROOT"/packaging/belgian-azerty-windows/be-azerty-settings \
  "$ROOT"/packaging/*/debian/postinst "$ROOT"/packaging/*/debian/postrm "$ROOT"/packaging/belgian-azerty-windows/debian/prerm "$ROOT"/tests/*.sh "$ROOT"/t14s-test/*.sh
res $? "shellcheck"

step "settings logic (layout lists, options, saved choices, ibus skip default): tests/settings-logic.sh"
bash "$ROOT/tests/settings-logic.sh" | grep -E '^(FAIL|ALL|SOME)'; res "${PIPESTATUS[0]}" "settings logic"

step "build both packages from source, lintian"
out=$(bash "$ROOT/packaging/build-all.sh" 2>&1); rc=$?; echo "$out" | tail -8
res $rc "build"
echo "$out" | grep -E '^  [EW]: ' | grep -v 'wrong-name-for-upstream-changelog' > /tmp/lintian-issues.txt
[ ! -s /tmp/lintian-issues.txt ]; res $? "lintian: no errors or warnings in our packages"

step "Caps Lock option vs the Windows table (libxkbcommon, files from the package source)"
inc=$(mktemp -d); mkdir -p "$inc/rules" "$inc/symbols"
cp "$ROOT/xkb/symbols/be_capslock" "$inc/symbols/"
# the rules file exactly as the package's update-xkb-rules writes it
cp /usr/share/X11/xkb/rules/evdev "$inc/rules/evdev.distrib"
sed "s|^RULES=.*|RULES=$inc/rules/evdev|" "$ROOT/packaging/belgian-azerty-windows/update-xkb-rules" > "$inc/update-xkb-rules"
sh "$inc/update-xkb-rules"; res $? "update-xkb-rules writes the rules file"
t=$(python3 "$ROOT/tools/captest.py" --include "$inc" none caps:be_windows 2>/dev/null); echo "$t" | grep -E 'expect|caps:be_windows'
[ "$(echo "$t" | grep 'caps:be_windows' | head -2 | grep -c 'mismatches=0')" = 2 ]; res $? "Caps and Caps+Shift: 0 mismatches"
a=$(echo "$t" | sed -n '/caps+altgr/,$p' | grep '  none ' | sed 's/^ *none *//'); b=$(echo "$t" | sed -n '/caps+altgr/,$p' | grep 'caps:be_windows' | sed 's/^ *caps:be_windows *//')
[ "$a" = "$b" ]; res $? "Caps+AltGr unchanged from stock Linux"
for v in "" oss nodeadkeys; do for o in caps:be_windows be_azerty:accents be_azerty:mac caps:be_windows,be_azerty:accents; do
  xkbcli compile-keymap --include "$inc" --include-defaults --layout be --variant "$v" --options "$o" >/dev/null 2>&1
  res $? "variant ${v:-standard} compiles with $o"
done; done

step "Shift+AltGr accents and the Apple layout (libxkbcommon)"
t=$(python3 "$ROOT/tools/optiontest.py" --include "$inc" be be_azerty:accents); echo "$t"
[ "$t" = "AC11 shift+altgr: dead_caron -> dead_acute
BKSL shift+altgr: dead_breve -> dead_grave
AB10 shift+altgr: dead_abovedot -> dead_tilde
differences: 3" ]; res $? "be_azerty:accents changes exactly Shift+AltGr on ù µ = to ´ \` ~"
t=$(python3 "$ROOT/tools/optiontest.py" --include "$inc" be be_azerty:mac fr:mac "")
[ -z "$(echo "$t" | grep -E ' (base|shift):')" ]; res $? "be_azerty:mac: plain and Shift keys equal Linux's French (Macintosh), the closest Mac layout"
[ "$(echo "$t" | grep -c ' altgr\| shift+altgr')" -le 20 ]; res $? "be_azerty:mac: Option layer close to French (Macintosh) ($(echo "$t" | tail -1))"
t=$(python3 "$ROOT/tools/optiontest.py" --include "$inc" be caps:be_windows,be_azerty:accents be caps:be_windows | tail -1)
[ "$t" = "differences: 3" ]; res $? "accents option on top of Windows Caps Lock: same 3 changes"
if command -v ckbcomp >/dev/null; then
  plain=$(ckbcomp -I"$inc" -rules evdev -layout be 2>/dev/null)
  for o in be_azerty:accents be_azerty:mac; do
    km=$(ckbcomp -I"$inc" -rules evdev -layout be -option "$o" 2>/dev/null) && [ -n "$km" ] && [ "$km" != "$plain" ]
    res $? "console keymap (ckbcomp) with $o: builds and follows the option"
  done
fi
rm -rf "$inc"

for iso in "$@"; do
  step "ISO checksum list: $iso"
  x=$(mktemp -d); xorriso -osirrox on -indev "$iso" -extract / "$x" >/dev/null 2>&1
  (cd "$x" && md5sum -c --quiet md5sum.txt); res $? "every file in $(basename "$iso") matches its md5sum.txt"
  chmod -R u+w "$x"; rm -rf "$x"
done

if [ "${DISPOSABLE:-0}" = 1 ]; then
  step "install / upgrade / trigger / purge cycle"
  bash "$ROOT/tests/pkg-cycle.sh" "$ROOT/dist" | grep -E '^(PASS|FAIL)'
  res "${PIPESTATUS[0]}" "package cycle"
fi
echo; [ "$FAIL" = 0 ] && echo "ALL PASS" || echo "SOME FAILED"; exit "$FAIL"
