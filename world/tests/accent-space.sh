#!/bin/bash
# world-keyboard-windows accent-space on a DISPOSABLE Ubuntu 24.04 container or VM (installs packages, adds users,
# edits /etc/default/keyboard). Run as root:
#   world/tests/accent-space.sh BELGIAN_DEB WORLD_DEB REPO_DIR
# Checks: the file it writes per user (layouts from /etc/default/keyboard and KDE's kxkbrc), the machine check of
# that very file, own and edited files left alone, US-international refused, layouts that disagree, next to
# be-azerty-fix accent-space, and package removal (only unchanged files of ours go).
set -u; export DEBIAN_FRONTEND=noninteractive; FAIL=0
BE=$(realpath "$1"); WO=$(realpath "$2"); REPO=$(realpath "$3")
pass() { echo "PASS  $*"; }; fail() { echo "FAIL  $*"; FAIL=1; }
t() { local d=$1; shift; if "$@" >/dev/null 2>&1; then pass "$d"; else fail "$d"; fi; }
as() { local u=$1; shift; runuser -u "$u" -- env HOME="/home/$u" "$@"; }
kb() { printf 'XKBMODEL="pc105"\nXKBLAYOUT="%s"\nXKBVARIANT="%s"\nXKBOPTIONS=""\n' "$1" "$2" > /etc/default/keyboard; }
X() { echo "/home/$1/.XCompose"; }
apt-get install -y "$WO" >/dev/null 2>&1; t "world package installed" dpkg-query -W world-keyboard-windows
W=world-keyboard-windows
for u in t1 t2 t3 t4 t5; do useradd -m "$u"; done
MARK="# Written by world-keyboard-windows accent-space: accent then Space as on Windows."

kb fr_windows ""
as t1 $W accent-space > /tmp/st1.txt 2>&1
t "off at the start, nothing written" sh -c "grep -q '^ *off' /tmp/st1.txt && [ ! -e $(X t1) ]"
as t1 $W accent-space on > /tmp/on1.txt 2>&1; rc=$?
t "French (as on Windows): on works" test $rc = 0
t "French: file = mark, include of the normal table, one line for ¨" sh -c "[ \"\$(sed -n 3p $(X t1))\" = 'include \"%L\"' ] && [ \"\$(head -1 $(X t1))\" = '$MARK' ] && [ \"\$(tail -n +4 $(X t1))\" = '<dead_diaeresis> <space> : \"¨\" diaeresis' ]"
t "file belongs to the user" sh -c "[ \"\$(stat -c %U $(X t1))\" = t1 ]"
mkdir -p /tmp/files; cp "$(X t1)" /tmp/files/fr_windows.XCompose
python3 -I "$REPO/world/tools/check_accent_space.py" "$REPO/world/layouts.tsv" "$REPO/world/cldr-43" "$REPO/world/xkb" /tmp/files/fr_windows.XCompose > /tmp/check-fr.txt 2>&1
t "machine check of the written file: French accent + Space like Windows, nothing worse" test $? = 0
sed -n 1p /tmp/check-fr.txt | sed 's/^/      /'
as t1 $W status > /tmp/st1b.txt 2>&1
t "status shows our layout and on" sh -c "grep -q 'accent-space knows: fr_windows' /tmp/st1b.txt && grep -q 'OK    on' /tmp/st1b.txt"
cp "$(X t1)" /tmp/fr1; as t1 $W accent-space on >/dev/null 2>&1
t "on again: same file" cmp /tmp/fr1 "$(X t1)"

# layouts from KDE's kxkbrc too; layouts that agree are merged
mkdir -p /home/t2/.config; printf '[Layout]\nLayoutList=de_windows,es_windows\nVariantList=,\n' > /home/t2/.config/kxkbrc; chown -R t2: /home/t2/.config
kb gb_windows ""
as t2 $W accent-space on >/dev/null 2>&1
t "German + Spanish (KDE list): lines for ´ and ¨" sh -c "[ \"\$(tail -n +4 $(X t2))\" = \"\$(printf '%s\n' '<dead_acute> <space> : \"´\" acute' '<dead_diaeresis> <space> : \"¨\" diaeresis')\" ]"
# layouts that disagree: Swiss German wants ¨, Swiss French wants " (as Linux): ¨ stays as on Linux
kb ch_windows,ch_windows basic,fr
as t3 $W accent-space on > /tmp/on3.txt 2>&1
t "Swiss German + Swiss French: ¨ left as on Linux (they differ on Windows), ´ line only" sh -c "[ \"\$(tail -n +4 $(X t3))\" = '<dead_acute> <space> : \"´\" acute' ] && grep -q 'dead_diaeresis then Space: your layouts' /tmp/on3.txt"
# Linux's own layouts that already type like Windows (Swedish, Romanian standard): only the accent lines
kb se,ro ,std
useradd -m t6; as t6 $W accent-space on >/dev/null 2>&1
t "Swedish + Romanian (Linux layouts): lines for ´, ¨ and ˙ (Windows gives · after ˙ + Space)" sh -c "[ \"\$(tail -n +4 $(X t6))\" = \"\$(printf '%s\n' '<dead_abovedot> <space> : \"·\" periodcentered' '<dead_acute> <space> : \"´\" acute' '<dead_diaeresis> <space> : \"¨\" diaeresis')\" ]"
cp "$(X t6)" /tmp/files/ro+std.XCompose
python3 -I "$REPO/world/tools/check_accent_space.py" "$REPO/world/layouts.tsv" "$REPO/world/cldr-43" "$REPO/world/xkb" /tmp/files/ro+std.XCompose > /tmp/check-ro.txt 2>&1
t "machine check of that file on Romanian (standard): like Windows, nothing worse" test $? = 0
sed -n 1p /tmp/check-ro.txt | sed 's/^/      /'
# step B: every accent sequence where Windows differs, not only accent then Space (Turkish Q: ´ then ı gives í)
kb tr_windows ""
useradd -m t7; as t7 $W accent-space on >/dev/null 2>&1
t "Turkish Q (as on Windows): lines also for other accent sequences (´ then ı gives í, as on Windows)" sh -c "grep -qxF '<dead_acute> <idotless> : \"í\" iacute' $(X t7)"
cp "$(X t7)" /tmp/files/tr_windows.XCompose
python3 -I "$REPO/world/tools/check_accent_space.py" "$REPO/world/layouts.tsv" "$REPO/world/cldr-43" "$REPO/world/xkb" /tmp/files/tr_windows.XCompose > /tmp/check-tr.txt 2>&1
t "machine check of that file on Turkish Q: like Windows, nothing worse" test $? = 0
sed -n 1p /tmp/check-tr.txt | sed 's/^/      /'
as t7 $W accent-space off >/dev/null 2>&1
# route 1: the Polish ~ is a real accent key now; with accent-space it gives Windows's letters (~ then a gives ą)
kb pl_windows ""
useradd -m t8; as t8 $W accent-space on >/dev/null 2>&1
t "Polish (Programmers, as on Windows): ~ then a gives ą with accent-space (as on Windows)" sh -c "grep -qxF '<dead_tilde> <a> : \"ą\" aogonek' $(X t8)"
cp "$(X t8)" /tmp/files/pl_windows.XCompose
python3 -I "$REPO/world/tools/check_accent_space.py" "$REPO/world/layouts.tsv" "$REPO/world/cldr-43" "$REPO/world/xkb" /tmp/files/pl_windows.XCompose > /tmp/check-pl.txt 2>&1
t "machine check of that file on Polish: like Windows, nothing worse" test $? = 0
sed -n 1p /tmp/check-pl.txt | sed 's/^/      /'
as t8 $W accent-space off >/dev/null 2>&1
# nothing to do
kb gb_windows ""
as t4 $W accent-space on >/dev/null 2>&1
t "English (UK) only: nothing needed, no file" test ! -e "$(X t4)"
# US international
kb fr_windows,us ,intl
as t4 $W accent-space on >/dev/null 2>&1; rc=$?
t "with us+intl: refused, no file" sh -c "[ $rc = 1 ] && [ ! -e $(X t4) ]"
# own file and edited file
kb fr_windows ""
printf 'include "%%L"\n<Multi_key> <a> <a> : "å"\n' > "$(X t4)"; chown t4: "$(X t4)"; cp "$(X t4)" /tmp/own4
as t4 $W accent-space on >/dev/null 2>&1; rc=$?
t "own ~/.XCompose: on refuses and leaves it unchanged" sh -c "[ $rc = 1 ] && cmp -s /tmp/own4 $(X t4)"
as t4 $W accent-space off >/dev/null 2>&1
t "own ~/.XCompose: off leaves it unchanged" cmp /tmp/own4 "$(X t4)"
echo '<Multi_key> <o> <o> : "ø"' >> "$(X t1)"; cp "$(X t1)" /tmp/edit1
as t1 $W accent-space off >/dev/null 2>&1; rc=$?
t "edited file of ours: off refuses and keeps it" sh -c "[ $rc = 1 ] && cmp -s /tmp/edit1 $(X t1)"
cp /tmp/fr1 "$(X t1)"; as t1 $W accent-space off >/dev/null 2>&1
t "off: our file removed" test ! -e "$(X t1)"
as t1 $W accent-space on >/dev/null 2>&1

# next to the Belgian package and its own accent-space
apt-get install -y --no-install-recommends "$BE" >/dev/null 2>&1; t "Belgian package installed" dpkg-query -W belgian-azerty-windows
BF=$(command -v be-azerty-fix)
kb be,fr_windows ,
as t5 "$BF" accent-space on >/dev/null 2>&1; cp "$(X t5)" /tmp/be5
t "be-azerty-fix accent-space on wrote its file" sh -c "head -1 $(X t5) | grep -q be-azerty-fix"
as t5 $W accent-space on > /tmp/on5.txt 2>&1
t "ours with the Belgian file: says already on, file unchanged" sh -c "grep -q 'already on through be-azerty-fix' /tmp/on5.txt && cmp -s /tmp/be5 $(X t5)"
as t5 $W accent-space off >/dev/null 2>&1
t "our off leaves the Belgian file alone" cmp /tmp/be5 "$(X t5)"

# removal: only unchanged files of ours go
cp /tmp/fr1 "$(X t2)"; echo '# my note' >> "$(X t2)"; cp "$(X t2)" /tmp/edit2
apt-get remove -y world-keyboard-windows > /tmp/remove.log 2>&1
t "package removed" sh -c "! dpkg-query -W -f='\${db:Status-Abbrev}' world-keyboard-windows | grep -q ii"
t "removal: unchanged file of ours gone (t1, t3)" sh -c "[ ! -e $(X t1) ] && [ ! -e $(X t3) ]"
t "removal: edited file of ours kept (t2)" cmp /tmp/edit2 "$(X t2)"
t "removal: own file kept (t4)" cmp /tmp/own4 "$(X t4)"
t "removal: Belgian file kept (t5)" cmp /tmp/be5 "$(X t5)"
t "removal: command gone" test ! -e /usr/bin/world-keyboard-windows
grep 'world-keyboard-windows:' /tmp/remove.log | sed 's/^/      /'
echo; [ $FAIL = 0 ] && echo "ALL PASS" || echo "SOME FAILED"; exit $FAIL
