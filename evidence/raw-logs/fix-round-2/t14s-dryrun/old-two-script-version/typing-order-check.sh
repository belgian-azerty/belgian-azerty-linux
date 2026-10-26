#!/bin/bash
# Fast-typing order check for the T14s (see T14S-TEST-PLAN.md). Asks for short lines of @€@€..., in four conditions:
#   A  keyd on,  ibus on,  Ctrl+Alt+2 / Ctrl+Alt+E      (what users get)
#   B  keyd on,  ibus on,  AltGr+2 / AltGr+E
#   C  keyd OFF, ibus on,  AltGr+2 / AltGr+E           (stock Linux, for comparison)
#   D  keyd on,  ibus OFF, Ctrl+Alt+2 / Ctrl+Alt+E
# and counts lines where a character is swapped, missing or extra. Results are appended to belgian-typing-results.txt
# on the USB stick (or in your home folder if the stick is read-only).
#   bash typing-order-check.sh                 run A-D in this terminal
#   bash typing-order-check.sh --file F LABEL  score a file you typed elsewhere (e.g. saved from VS Code)
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
# Not called LINES: bash sets LINES to the terminal height after every command (checkwinsize), which made the first
# version ask for 24 lines per block instead of 5.
ROUNDS=5
RESULTS=$HERE/belgian-typing-results.txt
score() {   # reads lines on stdin: order errors (@@ or €€ or other characters) and length differences, separately
  local ok=0 n=0 short=0 l bad=""
  while IFS= read -r l; do
    [ -z "$l" ] && continue
    n=$((n + 1))
    if [[ "$l" =~ ^(@€)*@?$ ]]; then ok=$((ok + 1)); else bad="$bad [$l]"; fi
    [ "${#l}" -eq 16 ] || short=$((short + 1))
  done
  echo "order right in $ok/$n lines${bad:+ (wrong:$bad)}; $short lines not 16 characters (dropped/extra key, or miscounted)"
}
out() {
  # The live system mounts the stick at /cdrom read-only and owned by root: make it writable once and write as root.
  # (The first dry run used a second stick, mounted for the user, and so never saw this.)
  if ! { echo "$*" >> "$RESULTS"; } 2>/dev/null && ! { echo "$*" | sudo tee -a "$RESULTS" >/dev/null; } 2>/dev/null; then
    sudo mount -o remount,rw "$(findmnt -no TARGET --target "$HERE")" 2>/dev/null
    if ! { echo "$*" | sudo tee -a "$RESULTS" >/dev/null; } 2>/dev/null; then
      RESULTS=$HOME/belgian-typing-results.txt; echo "$*" >> "$RESULTS"
    fi
  fi
  echo "$*"
}
ask() {    # LABEL HOW
  echo; echo "=== $1"
  echo "Type @€@€@€@€@€@€@€@€ (8 pairs) with $2, as fast as you normally type, then Enter. $ROUNDS lines."
  echo "Do not correct mistakes. Just type the next line."
  local i l all=""
  for ((i = 1; i <= ROUNDS; i++)); do IFS= read -r -p "$i> " l; all+="$l"$'\n'; done
  out "$(date -u +%H:%M:%SZ) $XDG_SESSION_TYPE keyd=$(systemctl is-active keyd) ibus=$(pgrep -x ibus-daemon >/dev/null && echo on || echo off) $1: $(printf '%s' "$all" | score)"
}
if [ "${1:-}" = --file ]; then
  [ -r "${2:-}" ] || { echo "usage: $0 --file FILE LABEL (file not found: ${2:-})"; exit 1; }
  out "$(date -u +%H:%M:%SZ) ${XDG_SESSION_TYPE:-?} file ${3:-unnamed}: $(score < "$2")"; sync; exit 0
fi
sudo -n true 2>/dev/null || sudo -v || { echo "This test needs sudo (to stop and start keyd)."; exit 1; }
# Whatever happens (Ctrl+C, a closed window), put keyd and ibus back as they were before the next block or test.
KEYD_STOPPED=0; IBUS_STOPPED=0
restore() {
  if [ "$KEYD_STOPPED" = 1 ]; then sudo systemctl start keyd; KEYD_STOPPED=0; echo "(keyd started again)"; fi
  if [ "$IBUS_STOPPED" = 1 ]; then
    pgrep -x ibus-daemon >/dev/null || (setsid ibus-daemon -drx >/dev/null 2>&1 &)
    IBUS_STOPPED=0; echo "(ibus started again)"
  fi
}
trap restore EXIT
trap 'echo; echo "(interrupted)"; exit 130' INT TERM HUP
out "--- $(date -u) T14s, session $XDG_SESSION_TYPE, kernel $(uname -r)"
ask "A keyd-on Ctrl+Alt" "Left Ctrl + Left Alt held, then 2 and E"
ask "B keyd-on AltGr" "AltGr held, then 2 and E"
KEYD_STOPPED=1; sudo systemctl stop keyd; echo "(keyd stopped)"
ask "C keyd-off AltGr (stock Linux)" "AltGr held, then 2 and E"
restore; sleep 1
if pgrep -x ibus-daemon >/dev/null; then IBUS_STOPPED=1; ibus exit 2>/dev/null; sleep 1; fi
echo "(ibus $(pgrep -x ibus-daemon >/dev/null && echo 'still running: the desktop started it again' || echo stopped))"
ask "D keyd-on ibus-off Ctrl+Alt" "Left Ctrl + Left Alt held, then 2 and E"
restore; sleep 2
sync
echo; echo "Done. All results so far, from $RESULTS:"; echo; cat "$RESULTS"
case "$RESULTS" in
  "$HOME"/*) echo; echo "The USB stick could not be written: the file above is only in this live session and is gone after"
             echo "shutdown. Copy it first: select the lines above, copy them with Ctrl+Shift+C, open the web browser,"
             echo "go to claude.ai and paste them into the thread." ;;
esac
