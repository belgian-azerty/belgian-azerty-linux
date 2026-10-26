#!/bin/bash
# One command for every test that needs no virtual machine. Run from anywhere on Ubuntu 24.04:
#   tests/run-offline.sh [ISO...]            static checks, package build + lintian, Caps Lock table check,
#                                            and for each ISO given: full checksum check of its md5sum.txt
#   sudo DISPOSABLE=1 tests/run-offline.sh   additionally the install/upgrade/purge cycle (tests/pkg-cycle.sh), which
#                                            changes this system's packages: only in a throwaway container or VM
# Needs: shellcheck debhelper devscripts lintian xorriso python3 libxkbcommon-tools, python3 module xkbcommon
# (pip install xkbcommon), and for keyd's build dh-python scdoc curl.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd); FAIL=0
step() { echo; echo "### $*"; }
res() { if [ "$1" = 0 ]; then echo "PASS  $2"; else echo "FAIL  $2"; FAIL=1; fi; }

step "shellcheck (warnings and errors)"
shellcheck -S warning "$ROOT"/be-azerty-fix.sh "$ROOT"/tools/make_belgian_iso.sh "$ROOT"/packaging/*.sh \
  "$ROOT"/packaging/*/build.sh "$ROOT"/packaging/belgian-azerty-windows/update-xkb-rules \
  "$ROOT"/packaging/*/debian/postinst "$ROOT"/packaging/*/debian/postrm "$ROOT"/tests/*.sh "$ROOT"/t14s-test/*.sh
res $? "shellcheck"

step "build every package from source, lintian"
out=$(bash "$ROOT/packaging/build-all.sh" 2>&1); rc=$?; echo "$out" | tail -8
res $rc "build"
echo "$out" | grep -E '^  [EW]: ' | grep -v 'wrong-name-for-upstream-changelog' > /tmp/lintian-issues.txt
[ ! -s /tmp/lintian-issues.txt ]; res $? "lintian: no errors or warnings in our packages (Debian's own keyd packaging excluded)"

step "Caps Lock option vs the Windows table (libxkbcommon, files from the package source)"
inc=$(mktemp -d); mkdir -p "$inc/rules" "$inc/symbols"
cp "$ROOT/xkb/symbols/be_capslock" "$inc/symbols/"
{ cat /usr/share/X11/xkb/rules/evdev; printf '\n! option\t=\tsymbols\n  caps:be_windows\t=\t+be_capslock(windows)\n'; } > "$inc/rules/evdev"
t=$(python3 "$ROOT/tools/captest.py" --include "$inc" none caps:be_windows 2>/dev/null); echo "$t" | grep -E 'expect|caps:be_windows'
[ "$(echo "$t" | grep 'caps:be_windows' | head -2 | grep -c 'mismatches=0')" = 2 ]; res $? "Caps and Caps+Shift: 0 mismatches"
a=$(echo "$t" | sed -n '/caps+altgr/,$p' | grep '  none ' | sed 's/^ *none *//'); b=$(echo "$t" | sed -n '/caps+altgr/,$p' | grep 'caps:be_windows' | sed 's/^ *caps:be_windows *//')
[ "$a" = "$b" ]; res $? "Caps+AltGr unchanged from stock Linux"
for v in oss nodeadkeys; do
  xkbcli compile-keymap --include "$inc" --include-defaults --layout be --variant "$v" --options caps:be_windows >/dev/null 2>&1
  res $? "variant $v compiles with caps:be_windows"
done
rm -rf "$inc"

for iso in "$@"; do
  step "ISO checksum list: $iso"
  x=$(mktemp -d); xorriso -osirrox on -indev "$iso" -extract / "$x" >/dev/null 2>&1
  (cd "$x" && md5sum -c --quiet md5sum.txt); res $? "every file in $(basename "$iso") matches its md5sum.txt"
  chmod -R u+w "$x"; rm -rf "$x"
done

if [ "${DISPOSABLE:-0}" = 1 ]; then
  step "install / upgrade / trigger / purge cycle"
  OLD_KEYD="$ROOT/keyd/keyd_2.5.0-0beazerty2_amd64.deb" bash "$ROOT/tests/pkg-cycle.sh" "$ROOT/dist" | grep -E '^(PASS|FAIL)'
  res "${PIPESTATUS[0]}" "package cycle"
fi
echo; [ "$FAIL" = 0 ] && echo "ALL PASS" || echo "SOME FAILED"; exit "$FAIL"
