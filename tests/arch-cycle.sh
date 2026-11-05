#!/bin/bash
# Arch Linux package cycle, in a DISPOSABLE container or VM, as root (no systemd needed):
#   tests/arch-cycle.sh [SOURCE_TARBALL]
# Builds packaging/arch/* with makepkg as a normal user (SOURCE_TARBALL = the v<version> tag archive; without it
# makepkg downloads it), then installs, updates, upgrades and removes with pacman, and checks that nothing of Arch's own
# is touched and nothing of the user's is taken away.
set -u; FAIL=0; ROOT=$(cd "$(dirname "$0")/.." && pwd); TB=${1:+$(realpath "$1")}
pass() { echo "PASS  $*"; }; fail() { echo "FAIL  $*"; FAIL=1; }
t() { local d=$1; shift; if "$@" >/dev/null 2>&1; then pass "$d"; else fail "$d"; fi; }
pacman -Syu --noconfirm --needed xkeyboard-config libxkbcommon libx11 python python-cffi diffutils util-linux shadow binutils fakeroot sudo >/dev/null 2>&1 || { echo "FAIL  pacman install"; exit 1; }
export LANG=en_US.UTF-8; OPTS=caps:be_windows,be_azerty:accents
echo "== $(. /etc/os-release; echo "$PRETTY_NAME"); $(pacman -Q xkeyboard-config libxkbcommon pacman | tr '\n' ' ')"
# the baseline: what pacman -Qkk says about xkeyboard-config before we do anything (the container leaves out man pages
# and translations on purpose, NoExtract, so it is not "clean" even untouched)
pacman -Qkk xkeyboard-config > /tmp/qkk0 2>&1; echo "      baseline pacman -Qkk xkeyboard-config: $(tail -1 /tmp/qkk0)"
qsame() { pacman -Qkk xkeyboard-config > /tmp/qkk1 2>&1; cmp -s /tmp/qkk0 /tmp/qkk1; }
# build as a normal user
useradd -m builder; mkdir -p /home/builder/b; cp -r "$ROOT"/packaging/arch/belgian-azerty-windows "$ROOT"/packaging/arch/keyd-belgian-windows /home/builder/b/
V=$(sed -n 's/^pkgver=//p' /home/builder/b/belgian-azerty-windows/PKGBUILD)
[ -n "$TB" ] && for d in belgian-azerty-windows keyd-belgian-windows; do cp "$TB" /home/builder/b/$d/belgian-azerty-linux-$V.tar.gz; done
chown -R builder /home/builder/b; OUT=/tmp/arch-cycle; mkdir -p $OUT/pkgs
b() { su builder -c "cd /home/builder/b/$1 && makepkg -f --noconfirm --nodeps" > $OUT/makepkg-$1-$2.log 2>&1; }
b belgian-azerty-windows r1; b keyd-belgian-windows r1
t "makepkg built both packages (pkgrel 1)" ls /home/builder/b/belgian-azerty-windows/belgian-azerty-windows-$V-1-any.pkg.tar.zst /home/builder/b/keyd-belgian-windows/keyd-belgian-windows-$V-1-any.pkg.tar.zst
cp /home/builder/b/*/*-1-any.pkg.tar.zst $OUT/pkgs/
for p in $OUT/pkgs/*-1-any.pkg.tar.zst; do echo "      $(basename $p): $(LC_ALL=C bsdtar -tf $p 2>/dev/null | grep -v '^\.' | tr '\n' ' ')"; done
P1=$OUT/pkgs/belgian-azerty-windows-$V-1-any.pkg.tar.zst; K1=$OUT/pkgs/keyd-belgian-windows-$V-1-any.pkg.tar.zst
# (each package listed on its own: "bsdtar -tf A B" would read B as a name inside A)
t "nothing outside /etc/xkb, /etc/keyd, the keyd drop-in, the X11 loader and the licence" sh -c "! for p in $P1 $K1; do bsdtar -tf \$p; done | grep -v '^\.' | grep -v '^etc/xkb/\|^etc/keyd/\|^usr/lib/systemd/system/keyd.service.d/\|^usr/share/licenses/\|^etc/\$\|^usr/\$\|^usr/lib/\$\|^usr/lib/systemd/\$\|^usr/lib/systemd/system/\$\|^usr/share/\$\|^usr/bin/\$\|^usr/bin/be-azerty-x11-load\$\|^etc/xdg/\$\|^etc/xdg/autostart/\$\|^etc/xdg/autostart/be-azerty-x11-load.desktop\$'"
t "the X11 loader and its start entry are in belgian-azerty-windows" sh -c "bsdtar -tf $P1 | grep -qx usr/bin/be-azerty-x11-load && bsdtar -tf $P1 | grep -qx etc/xdg/autostart/be-azerty-x11-load.desktop"
t "before: our options unknown (control)" sh -c "xkbcli compile-keymap --layout be --options $OPTS 2>&1 | grep -q 'Unrecognized RMLVO option'"
# a file of the user's own in /etc/xkb and /etc/keyd, before install
mkdir -p /etc/xkb/symbols /etc/keyd; echo '// my own' > /etc/xkb/symbols/mine; printf '[ids]\n*\n[main]\n' > /etc/keyd/default.conf
pacman -U --noconfirm $P1 $K1 > /tmp/inst.log 2>&1; rc=$?; sed -n '/keyd-belgian-windows:\|belgian-azerty-windows:/p' /tmp/inst.log | sort -u | sed 's/^/      /'
t "pacman -U installs both (keyd comes from Arch [extra] as dependency)" sh -c "[ $rc = 0 ] && pacman -Q belgian-azerty-windows keyd-belgian-windows keyd"
echo "      $(pacman -Q keyd) from Arch"
t "pacman -Qkk ours clean" sh -c 'pacman -Qkk belgian-azerty-windows keyd-belgian-windows 2>&1 | grep -q "belgian-azerty-windows: .* 0 altered files" && ! pacman -Qkk belgian-azerty-windows keyd-belgian-windows 2>&1 | grep -qv " 0 altered files"'
t "xkeyboard-config: pacman -Qkk same as the baseline" qsame
t "the user's own files are kept (symbols/mine, keyd default.conf)" sh -c 'grep -q "my own" /etc/xkb/symbols/mine && [ -f /etc/keyd/default.conf ]'
t "keyd-belgian-windows warned about the other keyd file" grep -q "default.conf exists" /tmp/inst.log
t "options known, no warning" sh -c "! xkbcli compile-keymap --layout be --options $OPTS 2>&1 | grep -q Unrecognized"
if python3 -c 'import xkbcommon' 2>/dev/null; then   # pip install xkbcommon==1.5.1
  c=$(python3 "$ROOT"/tools/captest.py none caps:be_windows 2>/dev/null)
  t "Caps and Caps+Shift: 0 mismatches vs Windows" test "$(echo "$c" | grep caps:be_windows | head -2 | grep -c mismatches=0)" = 2
  o=$(python3 "$ROOT"/tools/optiontest.py be be_azerty:accents | tail -1)
  t "be_azerty:accents: exactly 3 changes" test "$o" = "differences: 3"
  m=$(python3 "$ROOT"/tools/optiontest.py be be_azerty:mac fr:mac "")
  t "be_azerty:mac: plain and Shift = French (Macintosh)" test -z "$(echo "$m" | grep -E ' (base|shift):')"
else echo "      python module xkbcommon not installed: key-by-key checks skipped"; fi
useradd -m tester; u=$(su tester -c "xkbcli compile-keymap --layout be --options $OPTS" 2>&1)
t "a normal user sees the options too" sh -c "echo \"\$0\" | grep -q '^xkb_keymap' && ! echo \"\$0\" | grep -q Unrecognized" "$u"
t "keyd check on the installed rules: no errors" sh -c 'keyd check /etc/keyd/be-winaltgr.conf 2>&1 | grep -q "No errors found"'
t "keyd drop-in in place" test -f /usr/lib/systemd/system/keyd.service.d/belgian-windows-restart.conf
# an Arch update of the keyboard data
pacman -S --noconfirm xkeyboard-config >/dev/null 2>&1
t "after reinstalling xkeyboard-config: options still known, ours clean" sh -c "! xkbcli compile-keymap --layout be --options $OPTS 2>&1 | grep -q Unrecognized && ! pacman -Qkk belgian-azerty-windows 2>&1 | grep -qv ' 0 altered files'"
# upgrade to a rebuilt higher release
for d in belgian-azerty-windows keyd-belgian-windows; do sed -i 's/^pkgrel=1/pkgrel=2/' /home/builder/b/$d/PKGBUILD; b $d r2; done
cp /home/builder/b/*/*-2-any.pkg.tar.zst $OUT/pkgs/; P2=$OUT/pkgs/belgian-azerty-windows-$V-2-any.pkg.tar.zst; K2=$OUT/pkgs/keyd-belgian-windows-$V-2-any.pkg.tar.zst
pacman -U --noconfirm $P2 $K2 >/dev/null 2>&1; rc=$?
t "upgrade to pkgrel 2: upgraded, options known, ours clean" sh -c "[ $rc = 0 ] && pacman -Q belgian-azerty-windows | grep -q $V-2 && ! xkbcli compile-keymap --layout be --options $OPTS 2>&1 | grep -q Unrecognized && ! pacman -Qkk belgian-azerty-windows keyd-belgian-windows 2>&1 | grep -qv ' 0 altered files'"
# a user who changed our rules file, then a package change: pacman keeps theirs; when our file is the same in both
# packages there is nothing new to offer (no .pacnew); when ours changed, ours goes beside theirs as .pacnew
echo '// my change' >> /etc/xkb/rules/evdev
pacman -U --noconfirm $P1 $K1 > /tmp/down.log 2>&1
t "changed rules file kept, ours unchanged between packages: no .pacnew" sh -c 'grep -q "my change" /etc/xkb/rules/evdev && [ ! -e /etc/xkb/rules/evdev.pacnew ]'
sed -i 's/^pkgrel=2/pkgrel=3/; s|Removed with the package.|Removed with the package (r3).|' /home/builder/b/belgian-azerty-windows/PKGBUILD; b belgian-azerty-windows r3
cp /home/builder/b/belgian-azerty-windows/*-3-any.pkg.tar.zst $OUT/pkgs/; P3=$OUT/pkgs/belgian-azerty-windows-$V-3-any.pkg.tar.zst
pacman -U --noconfirm $P3 > /tmp/up3.log 2>&1
t "changed rules file kept, ours changed: new one as .pacnew" sh -c 'grep -q "my change" /etc/xkb/rules/evdev && grep -q "(r3)" /etc/xkb/rules/evdev.pacnew'
t "the .pacnew message is shown" grep -q "evdev.pacnew holds the new rules" /tmp/up3.log
rm -f /etc/xkb/rules/evdev.pacnew
# remove
pacman -R --noconfirm belgian-azerty-windows keyd-belgian-windows > /tmp/rm.log 2>&1; rc=$?
t "pacman -R removes both" sh -c "[ $rc = 0 ] && ! pacman -Q belgian-azerty-windows keyd-belgian-windows"
t "after removal: be_capslock gone, keyd drop-in gone" sh -c '[ ! -e /etc/xkb/symbols/be_capslock ] && [ ! -e /usr/lib/systemd/system/keyd.service.d/belgian-windows-restart.conf ]'
ls -la /etc/xkb/rules/ /etc/keyd/ 2>&1 | sed 's/^/      /'
t "after removal: a changed rules file is kept as evdev.pacsave (pacman's backup rule)" sh -c '[ ! -e /etc/xkb/rules/evdev ] && grep -q "my change" /etc/xkb/rules/evdev.pacsave'
t "after removal: options unknown again, keymap still compiles" sh -c "xkbcli compile-keymap --layout be --options $OPTS 2>&1 | grep -q Unrecognized && xkbcli compile-keymap --layout be --options $OPTS >/dev/null 2>&1"
t "after removal: xkeyboard-config pacman -Qkk same as the baseline" qsame
t "after removal: the user's own files still there; keyd itself stays" sh -c 'grep -q "my own" /etc/xkb/symbols/mine && [ -f /etc/keyd/default.conf ] && pacman -Q keyd'
rm -f /etc/xkb/rules/evdev.pacsave
# clean install, clean removal: nothing left
pacman -U --noconfirm $P2 >/dev/null 2>&1; pacman -R --noconfirm belgian-azerty-windows >/dev/null 2>&1
t "unchanged file: install then remove leaves no evdev, no .pacsave" sh -c '[ ! -e /etc/xkb/rules/evdev ] && [ ! -e /etc/xkb/rules/evdev.pacsave ] && [ ! -e /etc/xkb/symbols/be_capslock ]'
# a rules file of the user's own in /etc/xkb before install
mkdir -p /etc/xkb/rules; printf '! include %%S/evdev\n// the user own rules\n' > /etc/xkb/rules/evdev; cp /etc/xkb/rules/evdev /tmp/userrules
pacman -U --noconfirm $P2 > /tmp/own.log 2>&1; rc=$?; echo "      install over a user's own /etc/xkb/rules/evdev: rc $rc"; grep -i "exists in filesystem\|pacnew\|belgian-azerty-windows:" /tmp/own.log | sed 's/^/      /'
t "a user's own rules file is never overwritten" cmp -s /etc/xkb/rules/evdev /tmp/userrules
t "  ... and ours is put beside it as .pacnew, with the message" sh -c 'grep -q caps:be_windows /etc/xkb/rules/evdev.pacnew && grep -q "was already there and is kept" /tmp/own.log' 
# be-azerty-fix knows Debian/Ubuntu and Fedora only: elsewhere it must stop and change nothing
if ! grep -q '^ID=["]*fedora' /etc/os-release; then
  cp -a /etc/xkb /tmp/xkb-before; bash "$ROOT"/be-azerty-fix.sh check > /tmp/fix.log 2>&1; rc=$?
  t "be-azerty-fix stops on this system (exit $rc) and changes nothing" sh -c "[ $rc != 0 ] && grep -q 'changes' /tmp/fix.log && grep -q 'nothing' /tmp/fix.log && diff -r /tmp/xkb-before /etc/xkb"
fi
[ "$FAIL" = 0 ] && echo "ALL PASS" || echo "SOME FAILED"
