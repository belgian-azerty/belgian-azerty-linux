#!/bin/bash
# Check the Belgian Ctrl+Alt rules (keyd/be-winaltgr.conf) against a keyd source tree with keyd's own test program
# (no keyboard, no /dev/uinput, no root needed):
#   tests/keyd-rules.sh KEYD_SOURCE_DIR
# For example the keyd-team PPA's source: apt-get source keyd (with the PPA's deb-src line), or its .dsc unpacked.
# Each case types a key sequence into keyd and looks at what keyd sends on: for every key that is not a modifier, which
# modifiers are held at that moment. That is what decides the character, whatever extra modifier events keyd sends.
# Needs: gcc, python3.
set -u
K=$(realpath "${1:?usage: keyd-rules.sh KEYD_SOURCE_DIR}"); ROOT=$(cd "$(dirname "$0")/.." && pwd)
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
( cd "$K" && mkdir -p bin && gcc -DDATA_DIR= -o "$W/test-io" t/test-io.c src/keyboard.c src/string.c src/macro.c \
    src/config.c src/log.c src/ini.c src/keys.c src/unicode.c ) || { echo "FAIL  build of keyd's test program"; exit 1; }
cp "$ROOT/keyd/be-winaltgr.conf" "$W/test.conf"
FAIL=0
# case NAME EXPECTED INPUT...: EXPECTED = "key:modifiers key:modifiers ..." for every non-modifier key press sent on
case_() {
  local name=$1 want=$2; shift 2
  printf '%s\n' "$@" > "$W/case.t"; echo >> "$W/case.t"   # input, a blank line, no expected output
  local got
  got=$("$W/test-io" "$W/test.conf" "$W/case.t" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | python3 -c '
import sys
lines = sys.stdin.read().splitlines()
try:
    start = next(i for i, l in enumerate(lines) if l.startswith("Expected")) + 2
except StopIteration:
    sys.exit(0)
mods = {"leftcontrol": "C", "rightcontrol": "C", "leftalt": "A", "rightalt": "G", "leftshift": "S", "rightshift": "S", "leftmeta": "M", "rightmeta": "M"}
held = {}; out = []
for l in lines[start:]:
    w = l.split()
    if len(w) < 2 or w[-1] not in ("down", "up"):
        continue
    key, state = w[-2], w[-1]
    if key in mods:
        held[key] = (state == "down")
    elif state == "down":
        m = "".join(sorted(set(mods[k] for k, v in held.items() if v)))
        out.append(key + ":" + (m or "-"))
print(" ".join(out))')
  if [ "$got" = "$want" ]; then echo "PASS  $name"; else echo "FAIL  $name"; echo "        expected: $want"; echo "        got:      $got"; FAIL=1; fi
}
# G = AltGr (right Alt), C = Ctrl, A = left Alt, - = no modifier. keyd's test program names keys by their US symbol:
# [ = the ^ ¨ key, ] = $ *, ' = ù %, \ = µ £, / = = +.
case_ "Ctrl+Alt+2 sends AltGr+2 (@)" "2:G" "leftcontrol down" "leftalt down" "2 down" "2 up" "leftalt up" "leftcontrol up"
case_ "Ctrl+Alt+E sends AltGr+E (€)" "e:G" "leftcontrol down" "leftalt down" "e down" "e up" "leftalt up" "leftcontrol up"
case_ "Alt then Ctrl (other order) works too" "2:G" "leftalt down" "leftcontrol down" "2 down" "2 up" "leftcontrol up" "leftalt up"
case_ "right Ctrl + left Alt works too" "2:G" "rightcontrol down" "leftalt down" "2 down" "2 up" "leftalt up" "rightcontrol up"
case_ "Ctrl+Alt held, several symbols: 2 E 2 E" "2:G e:G 2:G e:G" "leftcontrol down" "leftalt down" "2 down" "2 up" "e down" "e up" "2 down" "2 up" "e down" "e up" "leftalt up" "leftcontrol up"
case_ "all 15 keys of the Windows AltGr layer" \
  "1:G 2:G 3:G 9:G [:G 6:G 9:G 0:G e:G [:G ]:G ':G \\:G /:G 102nd:G" \
  "leftcontrol down" "leftalt down" \
  "1 down" "1 up" "2 down" "2 up" "3 down" "3 up" "4 down" "4 up" "5 down" "5 up" "6 down" "6 up" "9 down" "9 up" "0 down" "0 up" \
  "e down" "e up" "[ down" "[ up" "] down" "] up" "' down" "' up" "\\ down" "\\ up" "/ down" "/ up" "102nd down" "102nd up" \
  "leftalt up" "leftcontrol up"
case_ "Ctrl+Alt+T stays Ctrl+Alt+T (terminal shortcut)" "t:AC" "leftcontrol down" "leftalt down" "t down" "t up" "leftalt up" "leftcontrol up"
case_ "Ctrl+Alt+Delete stays" "delete:AC" "leftcontrol down" "leftalt down" "delete down" "delete up" "leftalt up" "leftcontrol up"
case_ "Ctrl+Alt+F3 stays" "f3:AC" "leftcontrol down" "leftalt down" "f3 down" "f3 up" "leftalt up" "leftcontrol up"
case_ "Ctrl+Alt+Left stays" "left:AC" "leftcontrol down" "leftalt down" "left down" "left up" "leftalt up" "leftcontrol up"
case_ "Ctrl+Alt+7 (no AltGr symbol on Windows) stays" "7:AC" "leftcontrol down" "leftalt down" "7 down" "7 up" "leftalt up" "leftcontrol up"
case_ "symbol, then Ctrl+Alt+T with Ctrl+Alt still held" "2:G t:AC" "leftcontrol down" "leftalt down" "2 down" "2 up" "t down" "t up" "leftalt up" "leftcontrol up"
case_ "AltGr+4 sends AltGr+9 ({ as on Windows)" "9:G" "rightalt down" "4 down" "4 up" "rightalt up"
case_ "AltGr+5 sends AltGr+^ key ([ as on Windows)" "[:G" "rightalt down" "5 down" "5 up" "rightalt up"
case_ "AltGr+2 unchanged" "2:G" "rightalt down" "2 down" "2 up" "rightalt up"
case_ "plain keys unchanged" "2:- e:- 4:-" "2 down" "2 up" "e down" "e up" "4 down" "4 up"
case_ "Ctrl+C unchanged" "c:C" "leftcontrol down" "c down" "c up" "leftcontrol up"
case_ "Ctrl+Shift+2 unchanged" "2:CS" "leftcontrol down" "leftshift down" "2 down" "2 up" "leftshift up" "leftcontrol up"
echo; [ "$FAIL" = 0 ] && echo "ALL PASS" || echo "SOME FAILED"; exit "$FAIL"
