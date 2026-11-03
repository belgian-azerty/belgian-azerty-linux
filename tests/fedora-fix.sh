#!/bin/bash
# be-azerty-fix on Fedora (systemd-localed), in a DISPOSABLE Fedora 44/45 container or VM, as root:
#   tests/fedora-fix.sh RPM_DIR
# RPM_DIR holds belgian-azerty-windows-*.noarch.rpm (files in /etc/xkb). No systemd needed: when PID 1 is not systemd,
# a system D-Bus and systemd-localed are started by hand. Not covered: GNOME session, GDM, keyd, dracut, console.
set -u; RPMD=$(realpath "${1:?usage: fedora-fix.sh RPM_DIR}"); ROOT=$(cd "$(dirname "$0")/.." && pwd); FIX=$ROOT/be-azerty-fix.sh
FAIL=0; pass() { echo "PASS  $*"; }; fail() { echo "FAIL  $*"; FAIL=1; }
t() { local d=$1; shift; if "$@" >/dev/null 2>&1; then pass "$d"; else fail "$d"; fi; }
dnf -y -q install systemd dbus-daemon kbd xkeyboard-config libxkbcommon-utils glib2 gsettings-desktop-schemas dconf \
  util-linux shadow-utils diffutils findutils procps-ng >/dev/null 2>&1 || { echo "FAIL  dnf install"; exit 1; }
if [ ! -d /run/systemd/system ]; then
  mkdir -p /run/dbus /run/systemd/system; dbus-daemon --system --fork; sleep 1
  /usr/lib/systemd/systemd-localed >/tmp/localed.log 2>&1 & sleep 2
fi
echo "== $(. /etc/os-release; echo "$PRETTY_NAME"); $(rpm -q systemd xkeyboard-config libxkbcommon | tr '\n' ' ')"
localectl set-x11-keymap us pc105 "" "" >/dev/null 2>&1
t "start: system default is US (control)" sh -c '. /etc/vconsole.conf; [ "$XKBLAYOUT" = us ] && [ -z "${XKBOPTIONS:-}" ]'
dnf -y -q install "$RPMD"/belgian-azerty-windows-*.noarch.rpm >/dev/null 2>&1
t "belgian-azerty-windows rpm installed, files in /etc/xkb" sh -c 'rpm -q belgian-azerty-windows && [ -f /etc/xkb/symbols/be_capslock ]'
useradd -m tester
f=$(BE_AZERTY_FIX_SOURCE=1 bash -c ". '$FIX'; echo \$FAMILY \$KEYBOARD_FILE \$XKB_RULES \$XKB_CAPS")
t "family detected: fedora, /etc/vconsole.conf, rules and symbols in /etc/xkb" test "$f" = "fedora /etc/vconsole.conf /etc/xkb/rules/evdev /etc/xkb/symbols/be_capslock"
bash "$FIX" check > /tmp/check0.log 2>&1
t "check runs (reads /etc/vconsole.conf, shows the rpm)" sh -c 'grep -q "System default (/etc/vconsole.conf)" /tmp/check0.log && grep -q "belgian-azerty-windows 0.9" /tmp/check0.log'
# the user has stored desktop settings (logged in before, not now): US input source
runuser -u tester -- env HOME=/home/tester GIO_USE_VFS=local dbus-run-session -- gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us')]"
SUDO_USER=tester bash "$FIX" system > /tmp/sys1.log 2>&1; rc=$?; sed 's/^/      /' /tmp/sys1.log | grep -v '^      *$' | head -40
t "system: rc 0" test $rc = 0
t "system default: be first, us kept, pc105" sh -c '. /etc/vconsole.conf; [ "$XKBLAYOUT" = be,us ] && [ "$XKBMODEL" = pc105 ]'
t "system default options: Windows accents (GNOME: Windows Caps Lock is opt-in)" sh -c '. /etc/vconsole.conf; [ "$XKBOPTIONS" = be_azerty:accents ]'
t "console keymap follows (KEYMAP=be...)" sh -c '. /etc/vconsole.conf; case "$KEYMAP" in be*) true ;; *) false ;; esac'
t "X11 file written by localed agrees" sh -c 'grep -q "\"XkbLayout\" \"be,us\"" /etc/X11/xorg.conf.d/00-keyboard.conf && grep -q "\"XkbOptions\" \"be_azerty:accents\"" /etc/X11/xorg.conf.d/00-keyboard.conf'
t "the rpm's files untouched (rpm -V clean)" sh -c '[ -z "$(rpm -V belgian-azerty-windows)" ]'
t "xkeyboard-config untouched (rpm -V clean)" sh -c '[ -z "$(rpm -V xkeyboard-config)" ]'
t "the system default's keymap compiles with our option, no warning" sh -c '. /etc/vconsole.conf; xkbcli compile-keymap --layout "$XKBLAYOUT" --options "$XKBOPTIONS" 2>&1 >/dev/null | grep -q . && exit 1; xkbcli compile-keymap --layout "$XKBLAYOUT" --options "$XKBOPTIONS" | grep -q be_capslock'
g=$(runuser -u tester -- env HOME=/home/tester GIO_USE_VFS=local dbus-run-session -- sh -c 'gsettings get org.gnome.desktop.input-sources sources; gsettings get org.gnome.desktop.input-sources xkb-options')
echo "      tester's stored settings: $(echo $g)"
t "tester's stored desktop settings: be first, us kept, accents option" sh -c "echo \"\$0\" | grep -qF \"[('xkb', 'be'), ('xkb', 'us')]\" && echo \"\$0\" | grep -q be_azerty:accents" "$g"
t "choices saved" grep -qx "ACCENTS=windows" /var/lib/belgian-azerty-windows/choices
t "no boot image here: skipped, not an error" grep -q "no boot image found" /tmp/sys1.log
SUDO_USER=tester bash "$FIX" system > /tmp/sys2.log 2>&1; rc=$?
t "second run: rc 0, nothing to change" sh -c "[ $rc = 0 ] && grep -q 'already set' /tmp/sys2.log"
SUDO_USER=tester bash "$FIX" system CAPS=windows DECIMAL=comma > /tmp/sys3.log 2>&1; rc=$?
t "CAPS=windows DECIMAL=comma: kpdl:comma, caps:be_windows, accents" sh -c ". /etc/vconsole.conf; [ $rc = 0 ] && [ \"\$XKBOPTIONS\" = kpdl:comma,caps:be_windows,be_azerty:accents ]"
SUDO_USER=tester bash "$FIX" system PROFILE=linux > /tmp/sys4.log 2>&1; rc=$?
t "PROFILE=linux: only kpdl:comma left (kept), layouts kept" sh -c ". /etc/vconsole.conf; [ $rc = 0 ] && [ \"\$XKBOPTIONS\" = kpdl:comma ] && [ \"\$XKBLAYOUT\" = be,us ]"
SUDO_USER=tester bash "$FIX" system PROFILE=windows DECIMAL=period VARIANT=oss > /tmp/sys5.log 2>&1; rc=$?
t "VARIANT=oss: variant set, no accents option (oss has its own)" sh -c ". /etc/vconsole.conf; [ $rc = 0 ] && [ \"\${XKBVARIANT%%,*}\" = oss ] && ! echo \"\$XKBOPTIONS\" | grep -q be_azerty:accents"
# back to the standard variant (an existing be+oss entry is kept without VARIANT=, as on Debian), then Windows profile
localectl set-x11-keymap be,us pc105 "" "" >/dev/null 2>&1
SUDO_USER=tester bash "$FIX" system PROFILE=windows > /tmp/sys6.log 2>&1
bash "$FIX" check > /tmp/check1.log 2>&1
t "check shows Belgian first and the accents" sh -c 'grep -q "XKBLAYOUT=be,us" /tmp/check1.log && grep -q "be_azerty:accents" /tmp/check1.log'
SUDO_USER=tester bash "$FIX" switch-keyd > /tmp/sk.log 2>&1; rc=$?
t "switch-keyd: nothing to do on Fedora, rc 0" sh -c "[ $rc = 0 ] && grep -q 'nothing to switch on Fedora' /tmp/sk.log"
SUDO_USER=tester bash "$FIX" uninstall > /tmp/un.log 2>&1; rc=$?; sed 's/^/      /' /tmp/un.log | grep -v '^      *$' | head -20
t "uninstall: rc 0" test $rc = 0
grep -v '^#' /etc/vconsole.conf | sed 's/^/      after uninstall: /'
t "uninstall: our options out of the system default, Belgian and the other layout kept" sh -c '. /etc/vconsole.conf; [ "$XKBLAYOUT" = be,us ] && ! echo "${XKBOPTIONS:-}" | grep -q "be_azerty\|caps:be_windows"'
t "uninstall: rpm removed, /etc/xkb files gone, choices gone" sh -c '! rpm -q belgian-azerty-windows && [ ! -e /etc/xkb/symbols/be_capslock ] && [ ! -e /var/lib/belgian-azerty-windows/choices ]'
g=$(runuser -u tester -- env HOME=/home/tester GIO_USE_VFS=local dbus-run-session -- gsettings get org.gnome.desktop.input-sources xkb-options)
t "uninstall: our options out of tester's desktop settings" sh -c "! echo '$g' | grep -q 'be_azerty\|caps:be_windows'"
t "after all: keyboard compiles with the system default" sh -c '. /etc/vconsole.conf; xkbcli compile-keymap --layout "$XKBLAYOUT" --options "${XKBOPTIONS:-}" >/dev/null'
# systemd before 258 (Fedora 42 and older): the X11 settings only in 00-keyboard.conf
cp /etc/vconsole.conf /tmp/vc; sed -i '/^XKB/d' /etc/vconsole.conf
v=$(BE_AZERTY_FIX_SOURCE=1 bash -c ". '$FIX'; sysdef XKBLAYOUT; sysdef XKBMODEL" | tr '\n' ' ')
t "older systemd: the system default is read from 00-keyboard.conf" test "$v" = "be,us pc105 "
cp /tmp/vc /etc/vconsole.conf
[ "$FAIL" = 0 ] && echo "ALL PASS" || echo "SOME FAILED"
