#!/bin/bash
# Unit tests for be-azerty-fix's settings logic, without root, a desktop or a virtual machine:
#   tests/settings-logic.sh
# The script is loaded with BE_AZERTY_FIX_SOURCE=1 (no command runs). A fake gsettings (values kept in files) stands in
# for the desktop's settings store, a fake dpkg-query for the installed keyd version.
# Covered: layout lists (Belgian first, nothing else removed) for GNOME, Cinnamon and MATE, the X11 and
# /etc/default/keyboard lists, a list that cannot be read, keyboard options, saved choices, the ibus skip default,
# and which keyd counts as this project's old build.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd); FIX=$ROOT/be-azerty-fix.sh
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
R=$T/results   # one line per check (the checks run in subshells, so a counter variable would not survive)
eq() {   # DESCRIPTION EXPECTED ACTUAL
  if [ "$2" = "$3" ]; then echo "PASS  $1"; echo P >> "$R"; else echo "FAIL  $1"; echo "        expected: $2"; echo "        actual:   $3"; echo F >> "$R"; fi
}

# ---- fakes --------------------------------------------------------------------------------------
mkdir -p "$T/bin" "$T/store"
cat > "$T/bin/gsettings" <<'G'
#!/bin/bash
# fake gsettings: get/set/list-schemas; values in $FAKE_STORE/SCHEMA.KEY; a file SCHEMA.KEY.broken makes reads fail
S=${FAKE_STORE:?}
case "$1" in
  list-schemas) printf '%s\n' ${FAKE_SCHEMAS:-} ;;
  get) [ -e "$S/$2.$3.broken" ] && { echo "error" >&2; exit 1; }
       if [ -f "$S/$2.$3" ]; then cat "$S/$2.$3"; else
         case "$3" in sources) echo "@a(ss) []" ;; *) echo "@as []" ;; esac; fi ;;
  set) [ -e "$S/$2.$3.broken" ] && exit 1; printf '%s\n' "$4" > "$S/$2.$3" ;;
  *) exit 1 ;;
esac
G
cat > "$T/bin/dpkg-query" <<'D'
#!/bin/bash
# fake dpkg-query: the version of keyd is $FAKE_KEYD (empty: not installed)
for a; do last=$a; done
[ "$last" = keyd ] && [ -n "${FAKE_KEYD:-}" ] && { printf '%s' "$FAKE_KEYD"; exit 0; }
exit 1
D
chmod 755 "$T/bin/gsettings" "$T/bin/dpkg-query"
export PATH="$T/bin:$PATH" FAKE_STORE="$T/store" HOME="$T/home"; mkdir -p "$HOME"
unset DISPLAY SUDO_USER PKEXEC_UID
put() { printf '%s\n' "$3" > "$FAKE_STORE/$1.$2"; }
got() { cat "$FAKE_STORE/$1.$2" 2>/dev/null; }
load() {   # load the script in this (sub)shell with the given choices file content
  printf '%s' "${1:-}" > "$T/choices"
  # shellcheck disable=SC1090
  TEST_CHOICES="$T/choices" BE_AZERTY_FIX_SOURCE=1 . "$FIX"
}

echo "== pure list functions"
(
  load ""
  eq "GNOME list: empty -> Belgian" "[('xkb', 'be')]" "$(be_first_sources "@a(ss) []")"
  eq "GNOME list: be+us stays" "[('xkb', 'be'), ('xkb', 'us')]" "$(be_first_sources "[('xkb', 'be'), ('xkb', 'us')]")"
  eq "GNOME list: us+be -> be first, us kept" "[('xkb', 'be'), ('xkb', 'us')]" "$(be_first_sources "[('xkb', 'us'), ('xkb', 'be')]")"
  eq "GNOME list: ibus engines kept in order" "[('xkb', 'be'), ('ibus', 'mozc-jp'), ('xkb', 'us'), ('ibus', 'libpinyin')]" \
     "$(be_first_sources "[('ibus', 'mozc-jp'), ('xkb', 'us'), ('ibus', 'libpinyin')]")"
  eq "GNOME list: the user's own be+oss stays the Belgian entry (no VARIANT given)" "[('xkb', 'be+oss'), ('xkb', 'us')]" "$(be_first_sources "[('xkb', 'us'), ('xkb', 'be+oss')]")"
  eq "libgnomekbd/MATE: the user's own be oss stays the Belgian entry" "['be\\toss', 'us']" "$(be_first_layouts "['us', 'be\\toss']")"
  eq "X11 / default file: be(oss) keeps its variant" "be,us oss," "$(be_first_xkb "us,be" ",oss")"
  eq "X11 / default file: be(oss) alone stays" "be oss" "$(be_first_xkb "be" "oss")"
  eq "GNOME list: no Belgian prefix confusion (bepo is not be)" "[('xkb', 'be'), ('xkb', 'fr+bepo')]" "$(be_first_sources "[('xkb', 'fr+bepo')]")"
  eq "GNOME list: Belgian listed twice -> once" "[('xkb', 'be'), ('xkb', 'us')]" "$(be_first_sources "[('xkb', 'be'), ('xkb', 'us'), ('xkb', 'be')]")"
  eq "libgnomekbd/MATE: empty -> Belgian" "['be\\t']" "$(be_first_layouts "@as []")"
  eq "libgnomekbd/MATE: us, be -> the user's be moved first, us kept, be not twice" "['be', 'us']" "$(be_first_layouts "['us', 'be']")"
  eq "libgnomekbd/MATE: variants kept" "['be\\t', 'us\\tintl', 'de\\tneo']" "$(be_first_layouts "['us\\tintl', 'be\\t', 'de\\tneo']")"
  eq "X11 / default file: us,be -> be,us" "be,us " "$(be_first_xkb "us,be" "")"
  eq "X11 / default file: variants follow their layouts" "be,us,ru ,,phonetic" "$(be_first_xkb "us,ru" ",phonetic")"
  eq "X11 / default file: be only stays be" "be " "$(be_first_xkb "be" "")"
  eq "X11 / default file: empty -> be" "be " "$(be_first_xkb "" "")"
  eq "messages name what was kept" "us, ibus anthy" "$(kept_entries "[('xkb', 'be'), ('xkb', 'us'), ('ibus', 'anthy')]")"
  eq "messages: nothing kept when Belgian is alone" "" "$(kept_entries "[('xkb', 'be')]")"
  # shellcheck disable=SC2034   # read by the functions of the loaded script
  VARIANT=oss VARIANT_GIVEN=1
  eq "VARIANT=oss: plain be kept after be+oss" "[('xkb', 'be+oss'), ('xkb', 'be')]" "$(be_first_sources "[('xkb', 'be')]")"
  eq "VARIANT=oss in X11 list" "be,be oss," "$(be_first_xkb "be" "")"
)

echo "== keyboard options"
(
  load ""; XKB_CAPS=$T/caps; XKB_RULES=$T/rules; : > "$XKB_CAPS"; echo caps:be_windows > "$XKB_RULES"
  DECIMAL=comma CAPS=windows
  eq "comma + Windows Caps: others kept, old kpdl replaced" "compose:ralt,grp:alt_shift_toggle,kpdl:comma,caps:be_windows" \
     "$(want_options "compose:ralt,kpdl:dot,grp:alt_shift_toggle")"
  DECIMAL=period CAPS=linux
  eq "period + Linux Caps: our options out, others kept" "terminate:ctrl_alt_bksp" "$(want_options "terminate:ctrl_alt_bksp,kpdl:comma,caps:be_windows")"
  rm -f "$XKB_CAPS"; CAPS=windows
  eq "Windows Caps without the package files: option not added" "lv3:ralt_switch" "$(want_options "lv3:ralt_switch")"
  eq "uninstall: only caps:be_windows removed" "a,kpdl:comma,b" "$(without_caps_option "a,caps:be_windows,kpdl:comma,b")"
)

echo "== live: desktop lists keep other layouts and input methods"
for d in GNOME X-Cinnamon MATE; do
(
  rm -f "$FAKE_STORE"/*
  export XDG_CURRENT_DESKTOP=$d
  export FAKE_SCHEMAS="org.gnome.desktop.input-sources org.cinnamon.desktop.input-sources org.gnome.libgnomekbd.keyboard org.mate.peripherals-keyboard-xkb.kbd"
  put org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'anthy'), ('xkb', 'be')]"
  put org.gnome.desktop.input-sources xkb-options "['compose:ralt', 'grp:alt_shift_toggle']"
  put org.cinnamon.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'anthy')]"
  put org.cinnamon.desktop.input-sources xkb-options "['terminate:ctrl_alt_bksp', 'compose:ralt']"
  put org.gnome.libgnomekbd.keyboard layouts "['us', 'ru\\tphonetic']"
  put org.mate.peripherals-keyboard-xkb.kbd layouts "['de\\t', 'be\\t']"
  load "PROFILE=windows
DECIMAL=comma
CAPS=linux
"
  out=$(live 2>&1)
  case $d in
    GNOME) eq "$d: input sources" "[('xkb', 'be'), ('xkb', 'us'), ('ibus', 'anthy')]" "$(got org.gnome.desktop.input-sources sources)"
           eq "$d: options kept + comma" "['compose:ralt', 'grp:alt_shift_toggle', 'kpdl:comma']" "$(got org.gnome.desktop.input-sources xkb-options)"
           eq "$d: message names what was kept" 1 "$(printf '%s\n' "$out" | grep -c 'kept: us, ibus anthy')" ;;
    X-Cinnamon) eq "$d: input sources" "[('xkb', 'be'), ('xkb', 'us'), ('ibus', 'anthy')]" "$(got org.cinnamon.desktop.input-sources sources)"
           eq "$d: libgnomekbd layouts" "['be\\t', 'us', 'ru\\tphonetic']" "$(got org.gnome.libgnomekbd.keyboard layouts)"
           eq "$d: options kept + comma" "['terminate:ctrl_alt_bksp', 'compose:ralt', 'kpdl:comma']" "$(got org.cinnamon.desktop.input-sources xkb-options)"
           eq "$d: GNOME store untouched" "[('xkb', 'us'), ('ibus', 'anthy'), ('xkb', 'be')]" "$(got org.gnome.desktop.input-sources sources)" ;;
    MATE)  eq "$d: layouts" "['be\\t', 'de\\t']" "$(got org.mate.peripherals-keyboard-xkb.kbd layouts)" ;;
  esac
  eq "$d: no errors" 0 "$FAILED"
)
done

echo "== live: an empty list (follows the system default) starts from the system default's layouts"
(
  rm -f "$FAKE_STORE"/*
  export XDG_CURRENT_DESKTOP=X-Cinnamon FAKE_SCHEMAS="org.cinnamon.desktop.input-sources org.gnome.libgnomekbd.keyboard"
  put org.cinnamon.desktop.input-sources sources "[('xkb', 'de'), ('xkb', 'be')]"   # only the libgnomekbd list is empty
  load ""
  printf 'XKBLAYOUT="us,be"\nXKBVARIANT="intl,"\n' > "$T/keyboard"
  # shellcheck disable=SC2034   # read by system_list of the loaded script
  KEYBOARD_FILE=$T/keyboard
  out=$(live 2>&1)
  eq "empty libgnomekbd list: system layouts, Belgian first, us(intl) kept" "['be\\t', 'us\\tintl']" "$(got org.gnome.libgnomekbd.keyboard layouts)"
  eq "the other (non-empty) list keeps its own entries" "[('xkb', 'be'), ('xkb', 'de')]" "$(got org.cinnamon.desktop.input-sources sources)"
  eq "message says it was empty and what was kept" 1 "$(printf '%s\n' "$out" | grep -c 'was empty.*kept: us+intl')"
  rm -f "$FAKE_STORE"/*; out=$(live 2>&1)
  eq "both empty: input sources from the system default" "[('xkb', 'be'), ('xkb', 'us+intl')]" "$(got org.cinnamon.desktop.input-sources sources)"
  eq "no errors" 0 "$FAILED"
)

echo "== live: a list that cannot be read is left alone"
(
  rm -f "$FAKE_STORE"/*
  export XDG_CURRENT_DESKTOP=GNOME FAKE_SCHEMAS="org.gnome.desktop.input-sources"
  put org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'anthy')]"; : > "$FAKE_STORE/org.gnome.desktop.input-sources.sources.broken"
  put org.gnome.desktop.input-sources xkb-options "['compose:ralt']"; : > "$FAKE_STORE/org.gnome.desktop.input-sources.xkb-options.broken"
  load ""
  live >/dev/null 2>&1
  eq "unreadable sources: unchanged" "[('xkb', 'us'), ('ibus', 'anthy')]" "$(got org.gnome.desktop.input-sources sources)"
  eq "unreadable options: unchanged" "['compose:ralt']" "$(got org.gnome.desktop.input-sources xkb-options)"
  eq "and reported as an error" 1 "$FAILED"
)

echo "== saved choices"
choice() {   # CHOICES-FILE-CONTENT ENV... -> "PROFILE DECIMAL CAPS"
  local c=$1; shift
  ( export XDG_CURRENT_DESKTOP=${DESK:-X-Cinnamon} FAKE_SCHEMAS=""; for e; do export "${e?}"; done; load "$c"; echo "$PROFILE $DECIMAL $CAPS" )
}
eq "nothing saved, Mint: windows period windows" "windows period windows" "$(choice "")"
eq "nothing saved, Zorin (GNOME): Windows profile keeps Linux Caps Lock" "windows period linux" "$(DESK=GNOME choice "")"
eq "Zorin: CAPS=windows given wins" "windows period windows" "$(DESK=GNOME choice "" CAPS=windows)"
eq "saved comma and linux Caps kept on a rerun" "windows comma linux" "$(choice "PROFILE=windows
DECIMAL=comma
CAPS=linux
")"
eq "DECIMAL given beats the saved one" "windows period linux" "$(choice "PROFILE=windows
DECIMAL=comma
CAPS=linux
" DECIMAL=period)"
eq "PROFILE given sets Caps Lock from the profile" "linux comma linux" "$(choice "PROFILE=windows
DECIMAL=comma
CAPS=windows
" PROFILE=linux)"

echo "== ibus skip: off unless the user switched it on"
(
  load "PROFILE=windows
"
  SKIP_AUTOSTART=$T/autostart; : > "$SKIP_AUTOSTART"; skip_paths
  rm -f "$SKIP_AUTO"
  eq "no choice, Windows profile: off" off "$(skip_auto_choice)"
  mkdir -p "${SKIP_AUTO%/*}"; echo on > "$SKIP_AUTO"
  eq "user switched it on: on" on "$(skip_auto_choice)"
  echo off > "$SKIP_AUTO"
  eq "user switched it off: off" off "$(skip_auto_choice)"
  rm -f "$SKIP_AUTOSTART"; echo on > "$SKIP_AUTO"
  eq "without the package (no autostart entry): off" off "$(skip_auto_choice)"
)

echo "== which keyd is this project's old build"
k() { ( FAKE_KEYD=$1; export FAKE_KEYD; load ""; ours_keyd && echo ours || echo not-ours ); }
eq "2.5.0-5~ubuntu24.04.3 (0.9.6-0.9.7)" ours "$(k 2.5.0-5~ubuntu24.04.3)"
eq "2.5.0-5~ubuntu24.04.1 (0.9.1-0.9.3)" ours "$(k 2.5.0-5~ubuntu24.04.1)"
eq "2.5.0-0beazerty2 (before 0.9.1)" ours "$(k 2.5.0-0beazerty2)"
eq "keyd-team PPA 2.5.0-5~debian202508121658~ubuntu24.04.1" not-ours "$(k 2.5.0-5~debian202508121658~ubuntu24.04.1)"
eq "Ubuntu 25.04 archive 2.5.0-5" not-ours "$(k 2.5.0-5)"
eq "not installed" not-ours "$(k "")"

FAILS=$(grep -c F "$R"); echo; echo "$(wc -l < "$R") checks"
[ "$FAILS" = 0 ] && echo "ALL PASS" || echo "SOME FAILED ($FAILS)"; [ "$FAILS" = 0 ]
