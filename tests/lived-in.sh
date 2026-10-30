#!/bin/bash
# "Take nothing away" checks on lived-in profiles, in a DISPOSABLE Ubuntu 24.04 system container (systemd running):
# it creates users, installs and purges packages and adds the keyd-team PPA. Run as root:
#   tests/lived-in.sh NEW_DIST_DIR [OLD_DIST_DIR]
# NEW_DIST_DIR: the packages to test. OLD_DIST_DIR (optional): the 0.9.7 packages, for the upgrade path.
# Users: alice (logged in; GNOME-style list us + Japanese ibus input method + be, own options), bob (not logged in,
# Cinnamon settings with a second layout and the Windows Caps Lock option), chen (logged in; Chinese input method only),
# dave (created after "system": a new user), erin (logged in; Mint user who never changed her layouts: empty lists),
# frank (not logged in; his own list with US only). Every store is dumped before and after each step; the only changes
# allowed are listed per step, anything else that disappears is a FAIL.
set -u
NEW=$(realpath "${1:?usage: lived-in.sh NEW_DIST_DIR [OLD_DIST_DIR]}"); OLD=${2:+$(realpath "$2")}
# Wait until systemd has finished starting: it mounts a fresh /tmp, which would hide a work folder made before.
systemctl is-system-running --wait >/dev/null 2>&1
FAIL=0; W=$(mktemp -d)
pass() { echo "PASS  $*"; }
fail() { echo "FAIL  $*"; FAIL=1; }
t() { local d=$1; shift; if "$@" >/dev/null 2>&1; then pass "$d"; else fail "$d"; fi; }
export DEBIAN_FRONTEND=noninteractive

# ---- users and their settings -------------------------------------------------------------------
userdel -r ubuntu >/dev/null 2>&1   # the image's own uid 1000
mkuser() { useradd -m -u "$2" -s /bin/bash "$1"; }
bus_up() { loginctl enable-linger "$1"; for _ in $(seq 20); do [ -S "/run/user/$(id -u "$1")/bus" ] && return 0; sleep 0.3; done; return 1; }
gs() {   # USER ARGS...: gsettings as that user (session bus if logged in, else a private one)
  local u=$1 uid; uid=$(id -u "$u"); shift
  if [ -S "/run/user/$uid/bus" ]; then runuser -u "$u" -- env HOME="/home/$u" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" gsettings "$@" 2>/dev/null
  else runuser -u "$u" -- env -u XDG_RUNTIME_DIR HOME="/home/$u" GIO_USE_VFS=local dbus-run-session -- gsettings "$@" 2>/dev/null; fi
}
mkuser alice 1000; mkuser bob 1001; mkuser chen 1002; mkuser erin 1004; mkuser frank 1005
bus_up alice; bus_up chen; bus_up erin
gs erin set org.gnome.desktop.interface clock-format "'24h'"   # some setting of her own, but the layout lists empty
gs frank set org.gnome.desktop.input-sources sources "[('xkb', 'us')]"
gs alice set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'mozc-jp'), ('xkb', 'be')]"
gs alice set org.gnome.desktop.input-sources xkb-options "['compose:ralt', 'grp:alt_shift_toggle']"
gs alice set org.cinnamon.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'mozc-jp'), ('xkb', 'be')]"
gs alice set org.cinnamon.desktop.input-sources xkb-options "['compose:ralt']"
gs alice set org.gnome.libgnomekbd.keyboard layouts "['us', 'be']"
gs alice set org.freedesktop.ibus.general preload-engines "['mozc-jp']"
gs bob set org.cinnamon.desktop.input-sources sources "[('xkb', 'be'), ('xkb', 'fr')]"
gs bob set org.cinnamon.desktop.input-sources xkb-options "['terminate:ctrl_alt_bksp', 'caps:be_windows']"
gs bob set org.gnome.desktop.input-sources xkb-options "['caps:be_windows', 'compose:menu']"
gs chen set org.gnome.desktop.input-sources sources "[('ibus', 'libpinyin')]"
# alice also has her own launcher copy of the text editor (must never be touched)
mkdir -p /home/alice/.local/share/applications
printf '[Desktop Entry]\nName=My editor\nExec=gnome-text-editor --mine\nType=Application\n' > /home/alice/.local/share/applications/org.gnome.TextEditor.desktop
chown -R alice: /home/alice/.local
# a text editor menu file (one of the apps the ibus skip handles)
mkdir -p /usr/share/applications
printf '[Desktop Entry]\nName=Text Editor\nExec=gnome-text-editor %%U\nType=Application\n' > /usr/share/applications/org.x.editor.desktop
# the system default: US first, Belgian second, a switch key
sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="us,be"/; s/^XKBVARIANT=.*/XKBVARIANT=","/; s/^XKBOPTIONS=.*/XKBOPTIONS="grp:alt_shift_toggle"/' /etc/default/keyboard
# a kernel boot image and an update-initramfs that only counts its runs (a container has no real kernel)
mkdir -p /boot /usr/local/sbin; touch -d '2026-01-01' /boot/initrd.img-6.8.0-test
printf '#!/bin/sh\necho run >> /var/log/initramfs-runs\ntouch /boot/initrd.img-6.8.0-test\n' > /usr/local/sbin/update-initramfs; chmod 755 /usr/local/sbin/update-initramfs
: > /var/log/initramfs-runs
runs() { wc -l < /var/log/initramfs-runs; }

dump() {   # FILE: every keyboard store of every user, one "key = value" line each
  {
    echo "system XKBLAYOUT = $(. /etc/default/keyboard; echo "$XKBLAYOUT")"
    echo "system XKBVARIANT = $(. /etc/default/keyboard; echo "$XKBVARIANT")"
    echo "system XKBOPTIONS = $(. /etc/default/keyboard; echo "$XKBOPTIONS")"
    for u in alice bob chen dave erin frank; do
      id "$u" >/dev/null 2>&1 || continue
      for k in "org.gnome.desktop.input-sources sources" "org.gnome.desktop.input-sources xkb-options" \
               "org.cinnamon.desktop.input-sources sources" "org.cinnamon.desktop.input-sources xkb-options" \
               "org.gnome.libgnomekbd.keyboard layouts" "org.freedesktop.ibus.general preload-engines"; do
        # shellcheck disable=SC2086
        echo "$u $k = $(gs "$u" get $k)"
      done
      echo "$u launchers = $(cd "/home/$u/.local/share/applications" 2>/dev/null && for f in *.desktop; do [ -f "$f" ] && echo "$f:$(md5sum < "$f" | cut -c1-8)"; done | tr '\n' ' ')"
    done
  } > "$1"
}
# Entries of a list value, one per line ("('xkb', 'us')", "'compose:ralt'"; system lines: comma lists), to see what
# disappeared.
entries() { if grep -q "[('\[]" <<< "$1"; then grep -oE "\('[^']*', '[^']*'\)|'[^']*'" <<< "$1"; else tr ',' '\n' <<< "$1" | grep -v '^$'; fi; }
nothing_lost() {   # BEFORE AFTER DESCRIPTION [ALLOWED-REMOVAL-REGEX]: no list entry and no line disappeared
  local b=$1 a=$2 d=$3 allow=${4:-^$} lost="" key bv av e
  while IFS= read -r line; do
    key=${line%% = *}; bv=${line#* = }; av=$(grep -F "$key = " "$a" | head -1); av=${av#* = }
    if [ "$(entries "$bv" | wc -l)" -gt 0 ]; then
      while IFS= read -r e; do
        entries "$av" | grep -qxF "$e" || { grep -qE "$allow" <<< "$key $e" || lost="$lost [$key: $e]"; }
      done < <(entries "$bv")
    elif [ "$bv" != "$av" ] && [ -n "${bv//,/}" ] && [ "$bv" != "@as []" ] && [ "$bv" != "@a(ss) []" ]; then
      grep -qE "$allow" <<< "$key $bv" || lost="$lost [$key: $bv -> $av]"
    fi
  done < "$b"
  if [ -z "$lost" ]; then pass "$d: nothing taken away"; else fail "$d: taken away:$lost"; fi
}
as_alice() { SUDO_USER=alice XDG_CURRENT_DESKTOP=${DESK:-GNOME} "$@"; }
# A container has no /dev/uinput, so keyd cannot run here: "keyd ... not running" is the one error allowed.
no_errors() {   # LOG RC
  [ "$2" = 0 ] && return 0
  [ "$(grep '✘' "$1" | grep -vc 'marked ✘ above')" = "$(grep '✘' "$1" | grep -c 'not running')" ]
}

# ---- optional: 0.9.7 first (upgrade path) --------------------------------------------------------
if [ -n "$OLD" ]; then
  echo "== 0.9.7 installed first, ibus skip on by its default, then upgraded"
  apt-get install -y "$OLD"/keyd_*_amd64.deb "$OLD"/keyd-belgian-windows_*_all.deb "$OLD"/belgian-azerty-windows_*_all.deb >/dev/null 2>&1
  t "0.9.7 installed" sh -c "dpkg-query -W -f='\${Version}' belgian-azerty-windows | grep -qx 0.9.7"
  runuser -u bob -- env HOME=/home/bob be-azerty-fix ibus-skip refresh >/dev/null 2>&1   # bob's login under 0.9.7
  t "0.9.7 default: bob's text editor skips ibus (marked launcher copy)" grep -q '^X-BelgianAzerty-IbusSkip=' /home/bob/.local/share/applications/org.x.editor.desktop
  apt-get install -y "$NEW"/keyd-belgian-windows_*_all.deb "$NEW"/belgian-azerty-windows_*_all.deb >/dev/null 2>&1
  t "upgraded to the new version" sh -c "dpkg-query -W -f='\${Version}' belgian-azerty-windows | grep -vqx 0.9.7"
  runuser -u bob -- env HOME=/home/bob be-azerty-fix ibus-skip refresh >/dev/null 2>&1   # bob's next login
  t "after upgrade, bob's next login: the marked copy is gone (skip now opt-in)" test ! -e /home/bob/.local/share/applications/org.x.editor.desktop
  t "keyd is still the old build after the upgrade" sh -c "dpkg-query -W -f='\${Version}' keyd | grep -q '^2.5.0-5~ubuntu24.04.3$'"
  be-azerty-fix check 2>/dev/null | grep -q 'switch-keyd'; t "check points to switch-keyd" test $? = 0
  out=$(be-azerty-fix switch-keyd 2>&1); t "switch-keyd without the PPA: clear message, nothing changed" sh -c "echo \"$out\" | grep -q 'add the keyd-team PPA' && dpkg-query -W -f='\${Version}' keyd | grep -q '~ubuntu24.04.3$'"
  add-apt-repository -y ppa:keyd-team/ppa >/dev/null 2>&1
  be-azerty-fix switch-keyd > "$W/switch.log" 2>&1
  t "switch-keyd: keyd now the PPA's" sh -c "dpkg-query -W -f='\${Version}' keyd | grep -q '~debian'"
  t "switch-keyd: Belgian rules still installed" test -f /etc/keyd/be-winaltgr.conf
  t "switch-keyd: keyd-belgian-windows still installed" dpkg-query -W keyd-belgian-windows
  apt-get -s upgrade 2>/dev/null | grep -q '^Inst keyd ' && fail "apt would replace the PPA's keyd" || pass "apt keeps the PPA's keyd (no older build comes back)"
  sed 's/^/      /' "$W/switch.log"
else
  echo "== fresh install, keyd from the keyd-team PPA already present"
  add-apt-repository -y ppa:keyd-team/ppa >/dev/null 2>&1; apt-get install -y keyd >/dev/null 2>&1
  t "PPA keyd present first" sh -c "dpkg-query -W -f='\${Version}' keyd | grep -q '~debian'"
  apt-get install -y "$NEW"/keyd-belgian-windows_*_all.deb "$NEW"/belgian-azerty-windows_*_all.deb >/dev/null 2>&1
  t "both packages installed on top" sh -c "dpkg-query -W belgian-azerty-windows keyd-belgian-windows"
  t "keyd still the PPA's" sh -c "dpkg-query -W -f='\${Version}' keyd | grep -q '~debian'"
fi
t "keyd parses the Belgian rules" sh -c "keyd.rvaiya check /etc/keyd/be-winaltgr.conf"

echo "== system, run by alice (GNOME), lived-in profiles"
dump "$W/0"; r0=$(runs)
as_alice be-azerty-fix system > "$W/system1.log" 2>&1; rc=$?
t "system finished without errors (keyd not running: container limit)" no_errors "$W/system1.log" "$rc"
grep '✘' "$W/system1.log" | sed 's/^/      /'
dump "$W/1"
nothing_lost "$W/0" "$W/1" "system (alice)" "^alice org.gnome.desktop.input-sources xkb-options 'kpdl"
t "alice GNOME: be first, us and Japanese input method kept" grep -qF "alice org.gnome.desktop.input-sources sources = [('xkb', 'be'), ('xkb', 'us'), ('ibus', 'mozc-jp')]" "$W/1"
t "alice GNOME options: compose and switch key kept" sh -c "grep -F 'alice org.gnome.desktop.input-sources xkb-options' $W/1 | grep -q \"'compose:ralt', 'grp:alt_shift_toggle'\""
t "system default: be first, us kept, switch key kept" sh -c ". /etc/default/keyboard; [ \"\$XKBLAYOUT\" = be,us ] && echo \"\$XKBOPTIONS\" | grep -q grp:alt_shift_toggle"
t "bob (not logged in) untouched by alice's system run" bash -c "diff <(grep '^bob' $W/0) <(grep '^bob' $W/1)"
# Users without Cinnamon options of their own see the new Cinnamon default (the override that "system" writes for new
# users and reset settings): with the Windows profile it now carries be_azerty:accents. That one addition is allowed.
others_same() {   # REGEX: those users' lines unchanged, apart from be_azerty:accents in the Cinnamon default
  diff <(grep -E "$1" "$W/0") <(grep -E "$1" "$W/1" | sed -E "/cinnamon.desktop.input-sources xkb-options/{s/, 'be_azerty:accents'//; s/'be_azerty:accents', //; s/\['be_azerty:accents'\]/@as []/}")
}
diff <(grep -E '^(chen|erin|frank)' "$W/0") <(grep -E '^(chen|erin|frank)' "$W/1") | sed 's/^/      /'
t "chen untouched (apart from the new Cinnamon default)" others_same '^chen'
t "check after system: the system default with be first counts as right" sh -c "be-azerty-fix check 2>/dev/null | grep 'XKBLAYOUT=' | grep -q '✔'"
t "erin and frank untouched by alice's run (apart from the new Cinnamon default)" others_same '^(erin|frank)'
t "alice's own launcher copy untouched" bash -c "diff <(grep '^alice launchers' $W/0) <(grep '^alice launchers' $W/1)"
t "alice: no ibus skip files (she has an input method; and the skip is off by default)" sh -c "! grep -rqs '^X-BelgianAzerty-IbusSkip=' /home/alice/.local/share/applications"
t "boot image rebuilt once (the file changed)" test "$(( $(runs) - r0 ))" = 1
t "alice GNOME options: Windows Shift+AltGr accents added (Windows profile, also on GNOME)" sh -c "grep -F 'alice org.gnome.desktop.input-sources xkb-options' $W/1 | grep -q be_azerty:accents"
t "system default: accents option added" sh -c ". /etc/default/keyboard; echo \"\$XKBOPTIONS\" | grep -q be_azerty:accents"
t "choices file has ACCENTS and APPLE" sh -c "grep -qx ACCENTS=windows /var/lib/belgian-azerty-windows/choices && grep -qx APPLE=no /var/lib/belgian-azerty-windows/choices"
grep -E 'kept|initramfs|boot image' "$W/system1.log" | sed 's/^/      /'

echo "== same run again: nothing changes, no boot image rebuild"
r1=$(runs); as_alice be-azerty-fix system > "$W/system2.log" 2>&1
dump "$W/2"
t "second run: stores identical" diff "$W/1" "$W/2"
t "second run: boot image not rebuilt" test "$(runs)" = "$r1"

echo "== Period -> Comma (as the window does), then back"
r1=$(runs); as_alice be-azerty-fix system DECIMAL=comma >/dev/null 2>&1; dump "$W/3"
nothing_lost "$W/2" "$W/3" "switch to comma"
t "comma: boot image rebuilt (the file changed)" test "$(( $(runs) - r1 ))" = 1
as_alice be-azerty-fix system DECIMAL=period >/dev/null 2>&1; dump "$W/4"
nothing_lost "$W/3" "$W/4" "switch back to period" "kpdl:comma"

echo "== ACCENTS=linux, then back to the profile's"
as_alice be-azerty-fix system ACCENTS=linux >/dev/null 2>&1; dump "$W/4a"
nothing_lost "$W/4" "$W/4a" "ACCENTS=linux" "be_azerty:accents"
t "ACCENTS=linux: option out of alice's options and the system default" sh -c "! grep -E '^(alice org.gnome.desktop.input-sources xkb-options|system XKBOPTIONS)' $W/4a | grep -q be_azerty"
as_alice be-azerty-fix system ACCENTS=windows >/dev/null 2>&1; dump "$W/4b"
nothing_lost "$W/4a" "$W/4b" "ACCENTS=windows again"
t "rerun without ACCENTS keeps the saved choice" sh -c "SUDO_USER=alice XDG_CURRENT_DESKTOP=GNOME be-azerty-fix system 2>/dev/null | head -1 | grep -q 'accents windows (kept from the last run)'"

echo "== Apple keyboard: APPLE=yes, the key-swap switch, back to a PC keyboard"
as_alice be-azerty-fix system APPLE=yes > "$W/apple0.log" 2>&1; rc=$?; dump "$W/4b2"
t "APPLE=yes without an Apple keyboard: refused, nothing changed" sh -c "[ $rc != 0 ] && grep -q 'no Apple keyboard' $W/apple0.log && diff -q $W/4b $W/4b2"
as_alice be-azerty-fix system APPLE=yes FORCE=1 > "$W/apple.log" 2>&1; rc=$?; dump "$W/4c"
t "APPLE=yes: no errors" no_errors "$W/apple.log" "$rc"
nothing_lost "$W/4b" "$W/4c" "APPLE=yes" "be_azerty:accents|caps:be_windows"
t "APPLE=yes: alice's options have be_azerty:mac, not the Windows accents" sh -c "grep -F 'alice org.gnome.desktop.input-sources xkb-options' $W/4c | grep be_azerty:mac | grep -vq be_azerty:accents"
t "APPLE=yes: system default too" sh -c ". /etc/default/keyboard; echo \"\$XKBOPTIONS\" | grep be_azerty:mac | grep -vq be_azerty:accents"
t "APPLE=yes: the keymap compiles with the system default's options" sh -c ". /etc/default/keyboard; xkbcli compile-keymap --layout \"\$XKBLAYOUT\" --options \"\$XKBOPTIONS\" | grep -q enfilledcircbullet"
be-azerty-fix apple-iso-keys on > "$W/iso.log" 2>&1
t "apple-iso-keys on: modprobe file with iso_layout=1" grep -qx 'options hid_apple iso_layout=1' /etc/modprobe.d/belgian-azerty-apple.conf
t "apple-iso-keys on: says the driver is not loaded (no Apple keyboard here)" grep -q 'not loaded now' "$W/iso.log"
t "check shows the Apple section" sh -c "be-azerty-fix check 2>/dev/null | grep -q 'iso_layout\|driver not loaded'"
be-azerty-fix apple-iso-keys auto >/dev/null 2>&1
t "apple-iso-keys auto: file removed" test ! -e /etc/modprobe.d/belgian-azerty-apple.conf
as_alice be-azerty-fix system APPLE=no >/dev/null 2>&1; dump "$W/4d"
t "APPLE=no: back to the Windows accents, no Mac option" sh -c "grep -F 'alice org.gnome.desktop.input-sources xkb-options' $W/4d | grep be_azerty:accents | grep -vq be_azerty:mac"
nothing_lost "$W/4b" "$W/4d" "Apple and back" "kpdl"

echo "== accent then space (per user)"
runuser -u alice -- env HOME=/home/alice be-azerty-fix accent-space on >/dev/null 2>&1
t "alice: ~/.XCompose written, loads the normal table" grep -qx 'include "%L"' /home/alice/.XCompose
printf '<Multi_key> <a> <a> : "å"\n' > /home/bob/.XCompose; chown bob: /home/bob/.XCompose
runuser -u bob -- env HOME=/home/bob be-azerty-fix accent-space on >/dev/null 2>&1
t "bob's own ~/.XCompose untouched by accent-space on" grep -qx '<Multi_key> <a> <a> : "å"' /home/bob/.XCompose
t "check shows alice's accent-then-space status" sh -c "runuser -u alice -- env HOME=/home/alice be-azerty-fix check 2>/dev/null | grep -q 'then space gives ´'"

echo "== chen runs it (Chinese input method only)"
dump "$W/5"; SUDO_USER=chen XDG_CURRENT_DESKTOP=GNOME be-azerty-fix system >/dev/null 2>&1; dump "$W/6"
nothing_lost "$W/5" "$W/6" "system (chen)" "kpdl"
t "chen: be first, pinyin kept" grep -qF "chen org.gnome.desktop.input-sources sources = [('xkb', 'be'), ('ibus', 'libpinyin')]" "$W/6"

echo "== erin runs it on Mint (Cinnamon), her layout lists empty (they follow the system default be,us)"
dump "$W/6a"; SUDO_USER=erin XDG_CURRENT_DESKTOP=X-Cinnamon be-azerty-fix system > "$W/erin.log" 2>&1; dump "$W/6b"
nothing_lost "$W/6a" "$W/6b" "system (erin)" "kpdl|caps"
t "erin libgnomekbd: be first and the system default's us (not Belgian only)" grep -qF "erin org.gnome.libgnomekbd.keyboard layouts = ['be\\t', 'us\\t']" "$W/6b"
t "erin Cinnamon input sources: be, us" grep -qF "erin org.cinnamon.desktop.input-sources sources = [('xkb', 'be'), ('xkb', 'us')]" "$W/6b"
t "erin: the message says the list was empty and names us" grep -q 'was empty.*kept: us' "$W/erin.log"

echo "== system for frank, who is not logged in (over ssh or from a console)"
dump "$W/6c"; SUDO_USER=frank XDG_CURRENT_DESKTOP=GNOME be-azerty-fix system > "$W/frank.log" 2>&1; dump "$W/6d"
nothing_lost "$W/6c" "$W/6d" "system (frank)" "kpdl|caps"
t "frank's own list: be first, us kept (his setting would beat the system default)" grep -qF "frank org.gnome.desktop.input-sources sources = [('xkb', 'be'), ('xkb', 'us')]" "$W/6d"
t "frank: the message says he is not logged in" grep -q 'frank is not logged in' "$W/frank.log"
grep -E 'frank|kept' "$W/frank.log" | sed 's/^/      /'

echo "== a new user after system"
mkuser dave 1003; dump "$W/7"
t "dave starts with the system default be,us (no own settings yet)" sh -c ". /etc/default/keyboard; [ \"\$XKBLAYOUT\" = be,us ]"

echo "== uninstall"
dump "$W/8"
as_alice be-azerty-fix uninstall > "$W/uninstall.log" 2>&1; rc=$?
t "uninstall finished without errors" no_errors "$W/uninstall.log" "$rc"
grep '✘' "$W/uninstall.log" | sed 's/^/      /'
dump "$W/9"
nothing_lost "$W/8" "$W/9" "uninstall" "caps:be_windows|be_azerty:"
t "uninstall: none of our options left anywhere" sh -c "! grep -q 'be_azerty:\|caps:be_windows' $W/9"
t "uninstall: alice's accent-space file removed" test ! -e /home/alice/.XCompose
t "uninstall: bob's own ~/.XCompose kept" grep -qx '<Multi_key> <a> <a> : "å"' /home/bob/.XCompose
t "bob's caps:be_windows removed although bob was not logged in (Cinnamon)" sh -c "grep -F 'bob org.cinnamon.desktop.input-sources xkb-options' $W/9 | grep -q \"\\['terminate:ctrl_alt_bksp'\\]\""
t "bob's caps:be_windows removed (GNOME), compose kept" sh -c "grep -F 'bob org.gnome.desktop.input-sources xkb-options' $W/9 | grep -q \"\\['compose:menu'\\]\""
t "chen never had Cinnamon options: uninstall does not pin any for him" sh -c "[ -z \"\$(runuser -u chen -- env HOME=/home/chen dconf read /org/cinnamon/desktop/input-sources/xkb-options)\" ]"
t "bob's layouts kept" grep -qF "bob org.cinnamon.desktop.input-sources sources = [('xkb', 'be'), ('xkb', 'fr')]" "$W/9"
t "packages purged" sh -c "! dpkg-query -W -f='\${Status}' belgian-azerty-windows 2>/dev/null | grep -q installed"
t "keyd from the PPA stays (installed by the user)" sh -c "dpkg-query -W -f='\${Version}' keyd | grep -q '~debian'"
t "system default keeps be,us and the switch key" sh -c ". /etc/default/keyboard; [ \"\$XKBLAYOUT\" = be,us ] && echo \"\$XKBOPTIONS\" | grep -q grp:alt_shift_toggle"
grep -E 'bob|keyd|stays' "$W/uninstall.log" | sed 's/^/      /'

echo "== only belgian-azerty-windows, no keyd"
apt-get purge -y keyd >/dev/null 2>&1
apt-get install -y "$NEW"/belgian-azerty-windows_*_all.deb >/dev/null 2>&1
out=$(as_alice be-azerty-fix system 2>&1); rc=$?
t "system without keyd: no error" test "$rc" = 0
t "system without keyd: says where keyd comes from" sh -c "echo \"\$0\" | grep -q 'keyd-belgian-windows not installed'" "$out"
runuser -u dave -- env HOME=/home/dave be-azerty-fix ibus-skip refresh >/dev/null 2>&1   # dave's login: no input method
echo "== four layouts in the system default already, and a be(oss) user"
cp /etc/default/keyboard "$W/keyboard.saved"
sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="us,de,fr,ru"/; s/^XKBVARIANT=.*/XKBVARIANT="intl,nodeadkeys,,phonetic"/' /etc/default/keyboard
out=$(as_alice be-azerty-fix system 2>&1)
t "five layouts do not fit: system default be,us,de,fr with their variants" sh -c ". /etc/default/keyboard; [ \"\$XKBLAYOUT\" = be,us,de,fr ] && [ \"\$XKBVARIANT\" = ,intl,nodeadkeys, ]"
t "and the command says ru was left out there" sh -c "echo \"\$0\" | grep -q 'ru left out'" "$out"
sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="be"/; s/^XKBVARIANT=.*/XKBVARIANT="oss"/' /etc/default/keyboard
gs alice set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'be+oss')]"
as_alice be-azerty-fix system >/dev/null 2>&1
t "be(oss) system default: no Windows accents option (oss has its own Shift+AltGr level)" sh -c ". /etc/default/keyboard; ! echo \"\$XKBOPTIONS\" | grep -q be_azerty:accents"
t "alice with be+oss first: no accents option in her options" sh -c "! runuser -u alice -- env HOME=/home/alice DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus gsettings get org.gnome.desktop.input-sources xkb-options | grep -q be_azerty:accents"
t "be(oss) system default keeps oss (not pushed back by plain be)" sh -c ". /etc/default/keyboard; [ \"\$XKBLAYOUT\" = be ] && [ \"\$XKBVARIANT\" = oss ]"
t "alice's be+oss moved first, not plain be added" sh -c "[ \"\$(runuser -u alice -- env HOME=/home/alice DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus gsettings get org.gnome.desktop.input-sources sources)\" = \"[('xkb', 'be+oss'), ('xkb', 'us')]\" ]"
cp "$W/keyboard.saved" /etc/default/keyboard
t "Caps-only route: no ibus skip files at dave's login" sh -c "! grep -rqs '^X-BelgianAzerty-IbusSkip=' /home/dave/.local/share/applications /home/dave/.config/systemd"
apt-get purge -y belgian-azerty-windows >/dev/null 2>&1

echo "== only keyd-belgian-windows (with the PPA's keyd)"
dump "$W/10"; apt-get install -y keyd "$NEW"/keyd-belgian-windows_*_all.deb >/dev/null 2>&1; dump "$W/11"
t "keyd-only route: no keyboard store changed" diff "$W/10" "$W/11"
t "keyd-only route: rules installed" test -f /etc/keyd/be-winaltgr.conf

rm -rf "$W"
echo; [ "$FAIL" = 0 ] && echo "ALL PASS" || echo "SOME FAILED"; exit "$FAIL"
