#!/bin/bash
# The whole T14s real-hardware test in one command (see T14S-TEST-PLAN.md). In the live session of the Belgian Zorin
# stick, open a terminal (Ctrl+Alt+T) and type:
#     bash /cdrom/t14s-test/run-test.sh
# It installs the packages from this folder (live session only), checks the layout, asks for the typing blocks on
# Xorg, does the VS Code part if there is internet, switches to Wayland and carries on by itself after the screen
# comes back, then writes one results file (belgian-t14s-results.txt) to the desktop and to this folder on the stick,
# with the anomalies it found listed at the end.
#   bash run-test.sh            start, or carry on where it stopped
#   bash run-test.sh --restart  forget the progress and start again from the beginning
# Ctrl+C pauses it at any point; the same command carries on from the last finished step.
# shellcheck disable=SC2024   # logs are written as the live user on purpose
set -u
# Scoring counts characters (@ and € are one each), which needs a UTF-8 locale.
[ "$(locale charmap 2>/dev/null)" = UTF-8 ] || export LC_ALL=C.UTF-8
HERE=$(cd "$(dirname "$0")" && pwd)
VERSION=0.9.1
NAME=belgian-t14s-results.txt
WORK=$HOME/.belgian-t14s/$NAME            # working copy; published to the desktop and the stick after every stage
STATE=$HOME/.belgian-t14s/state           # the live home survives the switch to Wayland (only the session restarts)
AUTOSTART=$HOME/.config/autostart/belgian-t14s-resume.desktop
ROUNDS=5                                  # not LINES: bash overwrites LINES with the terminal height
DESK=$(xdg-user-dir DESKTOP 2>/dev/null); [ -n "$DESK" ] && [ "$DESK" != "$HOME" ] || DESK=$HOME/Desktop
mkdir -p "${WORK%/*}" "$DESK"

if [ "${1:-}" = --restart ]; then rm -f "$STATE" "$WORK" "$AUTOSTART"; echo "Progress forgotten, starting again."; fi
stage=$(cat "$STATE" 2>/dev/null || echo start)
set_stage() { stage=$1; echo "$1" > "$STATE"; }

log() { echo "$*" >> "$WORK"; }
say() { echo "$*"; log "$*"; }
anomaly() { echo "  !! $*"; log "ANOMALY: $*"; }
STICK_OK=unknown
publish() {   # copy the working file to the desktop and to the stick (mounted read-only and root-owned at /cdrom)
  cp "$WORK" "$DESK/$NAME" 2>/dev/null
  if cp "$WORK" "$HERE/$NAME" 2>/dev/null || sudo cp "$WORK" "$HERE/$NAME" 2>/dev/null; then STICK_OK=yes
  else
    sudo mount -o remount,rw "$(findmnt -no TARGET --target "$HERE")" 2>/dev/null
    if sudo cp "$WORK" "$HERE/$NAME" 2>/dev/null; then STICK_OK=yes; else STICK_OK=no; fi
  fi
  sync
}
pause() { echo; read -r -p "$1 Press Enter to continue. " _; }
anomalies() { grep -c '^ANOMALY:' "$WORK" 2>/dev/null || echo 0; }

# --- system facts -----------------------------------------------------------------------------------------------
facts() {
  local SB; SB=$(mokutil --sb-state 2>/dev/null | head -1)
  if [ -z "$SB" ] && [ -d /sys/firmware/efi ]; then   # last byte of the SecureBoot EFI variable: 1 on, 0 off
    SB=$(od -An -t u1 /sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c 2>/dev/null | awk '{print ($NF == 1) ? "enabled" : "disabled"}')
  fi
  log ""; log "== System facts ($1) $(date -u +%FT%TZ)"
  log "machine: $(cat /sys/class/dmi/id/sys_vendor 2>/dev/null) $(cat /sys/class/dmi/id/product_version 2>/dev/null) ($(cat /sys/class/dmi/id/product_name 2>/dev/null)), BIOS $(cat /sys/class/dmi/id/bios_version 2>/dev/null)"
  log "cpu: $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2-)  ram: $(free -g | awk '/^Mem/{print $2}') GB"
  log "system: $(lsb_release -ds 2>/dev/null), kernel $(uname -r), boot $([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS), secure boot: ${SB:-unknown}"
  log "session: ${XDG_SESSION_TYPE:-?} ${XDG_CURRENT_DESKTOP:-?}, locale ${LANG:-?}"
  log "keyboards: $(grep -B5 -E '^H: Handlers=.*kbd' /proc/bus/input/devices | sed -n 's/^N: Name="\(.*\)"/\1/p' | paste -sd ';' -)"
  log "/etc/default/keyboard: $(grep -E '^XKB(LAYOUT|VARIANT|OPTIONS)' /etc/default/keyboard 2>/dev/null | paste -sd ' ' -)"
  log "desktop layouts: $(gsettings get org.gnome.desktop.input-sources sources 2>/dev/null)  options: $(gsettings get org.gnome.desktop.input-sources xkb-options 2>/dev/null)"
  log "keyd: $(systemctl is-active keyd 2>/dev/null)  ibus: $(pgrep -x ibus-daemon >/dev/null && echo running || echo stopped) $(ibus version 2>/dev/null)"
  log "packages: $(dpkg-query -W -f='${Package} ${Version}; ' keyd keyd-belgian-windows belgian-azerty-windows keyboard-configuration xkb-data ibus 2>/dev/null)"
  local lag; lag=$(journalctl -b --no-pager 2>/dev/null | grep -c 'lagging behind')
  log "journal: 'event processing lagging' messages this boot: $lag; keyd warnings: $(journalctl -b -u keyd -p warning --no-pager -q 2>/dev/null | wc -l)"
  [ "$lag" -gt 0 ] 2>/dev/null && anomaly "$1: the desktop logged $lag 'input lagging behind' messages (keyboard events late)"
  return 0
}

# --- scoring ----------------------------------------------------------------------------------------------------
# One typed line should be @€ repeated (eight pairs asked; more or fewer pairs are fine, only the characters and
# their order count). Classify it: ok, order (same number of @ and €, wrong order), count (a key dropped or doubled),
# other (characters that are not @ or €: a shortcut did not work).
classify() {
  local l=$1 ats eur rest
  [[ "$l" =~ ^(@€)+$ ]] && { echo ok; return; }
  rest=${l//[@€]/}; [ -n "$rest" ] && { echo "other:$rest"; return; }
  ats=${l//[^@]/}; eur=${l//[^€]/}
  if [ "${#ats}" = "${#eur}" ]; then echo order; else echo "count:${#ats}@,${#eur}€"; fi
}
score_block() {   # LABEL, lines on stdin -> one result line + anomalies
  local label=$1 l c n=0 ok=0 pairs=0 order=0 count=0 other=0 detail=""
  while IFS= read -r l; do
    [ -z "$l" ] && continue
    n=$((n + 1)); c=$(classify "$l")
    case $c in ok) ok=$((ok + 1)); pairs=$((pairs + ${#l} / 2)) ;; order) order=$((order + 1)); detail+=" [$l]" ;;
      count*) count=$((count + 1)); detail+=" [$l]" ;; other*) other=$((other + 1)); detail+=" [$l]" ;; esac
  done
  log "$label: $ok/$n right ($pairs @€ pairs in the right lines), $order with swapped order, $count with a dropped/doubled key, $other with other characters${detail:+ | wrong lines:$detail}"
  echo "  $label: $ok/$n right"
  [ "$order" -gt 0 ] && anomaly "$label: characters arrived in the wrong order in $order of $n lines"
  [ "$other" -gt 0 ] && anomaly "$label: unexpected characters in $other of $n lines (a shortcut did not give @ or €)"
  [ "$count" -gt 0 ] && anomaly "$label: a key missing or doubled in $count of $n lines (a typing slip, or a lost key)"
  [ "$n" -lt "$ROUNDS" ] && [ "$label" != "${label#*VS Code}" ] && anomaly "$label: only $n lines found in the file"
  return 0
}
ask_block() {     # LABEL HOW
  echo; echo "=== $1"
  echo "Hold $2 the WHOLE time and press the keys 2, E, 2, E ... (eight pairs), so that the line reads"
  echo "    @€@€@€@€@€@€@€@€"
  echo "(a pair more or less is fine). Type as fast as you normally do, then let go and press Enter."
  echo "$ROUNDS lines. Do not correct mistakes, just go on with the next line."
  local i l all=""
  # Drop keys that arrived before the prompt, then let the user start the block when ready (in the emulator, keys
  # sent while ibus was stopping went missing).
  while read -r -t 0.2 _; do :; done
  read -r -p "Press Enter when you are ready for this block. " _
  for ((i = 1; i <= ROUNDS; i++)); do IFS= read -r -p "$i> " l; all+="$l"$'\n'; done
  log "-- $(date -u +%H:%M:%SZ) ${XDG_SESSION_TYPE:-?} keyd=$(systemctl is-active keyd) ibus=$(pgrep -x ibus-daemon >/dev/null && echo on || echo off)"
  printf '%s' "$all" | score_block "$1"
}

# --- keyd / ibus are always put back --------------------------------------------------------------------------
KEYD_STOPPED=0; IBUS_STOPPED=0
restore() {
  if [ "$KEYD_STOPPED" = 1 ]; then sudo systemctl start keyd; KEYD_STOPPED=0; echo "(keyd started again)"; fi
  if [ "$IBUS_STOPPED" = 1 ]; then
    pgrep -x ibus-daemon >/dev/null || (setsid ibus-daemon -drx >/dev/null 2>&1 &)
    IBUS_STOPPED=0; echo "(ibus started again)"
  fi
}
trap 'restore; [ -s "$WORK" ] && publish' EXIT
trap 'echo; echo "(stopped. Run the same command again to carry on where you were.)"; exit 130' INT TERM HUP

# --- stages ---------------------------------------------------------------------------------------------------
do_setup() {
  say "=== Belgian AZERTY T14s test, version $VERSION, started $(date -u +%FT%TZ)"
  gsettings set org.gnome.desktop.session idle-delay 0 2>/dev/null; gsettings set org.gnome.desktop.screensaver lock-enabled false 2>/dev/null
  local missing="" f
  for f in keyd_ keyd-belgian-windows_ belgian-azerty-windows_; do ls "$HERE/$f"*.deb >/dev/null 2>&1 || missing+=" ${f}*.deb"; done
  [ -f "$HERE/be-azerty-fix.sh" ] || missing+=" be-azerty-fix.sh"
  if [ -n "$missing" ]; then anomaly "files missing in $HERE:$missing (copy the whole t14s-test folder onto the stick)"; return 1; fi
  if [ -f "$HERE/SHA256SUMS" ]; then
    if (cd "$HERE" && sha256sum --quiet -c SHA256SUMS >/dev/null 2>&1); then say "✔ files checked"
    else anomaly "files damaged (SHA256SUMS does not match): copy the folder onto the stick again"; return 1; fi
  fi
  if sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$HERE"/keyd_*.deb "$HERE"/keyd-belgian-windows_*.deb \
       "$HERE"/belgian-azerty-windows_*.deb > "${WORK%/*}/apt.log" 2>&1; then say "✔ packages installed"
  else anomaly "package install failed: $(tail -3 "${WORK%/*}/apt.log" | paste -sd ' ' -)"; return 1; fi
  sudo bash "$HERE/be-azerty-fix.sh" system > "${WORK%/*}/fix.log" 2>&1; local rc=$?
  sed 's/\x1b\[[0-9;]*m//g' "${WORK%/*}/fix.log" | grep -E '✔|✘|Choices' | while IFS= read -r l; do say "  $l"; done
  [ $rc = 0 ] || anomaly "be-azerty-fix system ended with status $rc: $(grep '✘' "${WORK%/*}/fix.log" | head -3 | paste -sd ' ' -)"
  [ "$(systemctl is-active keyd)" = active ] || anomaly "keyd is not running after setup"
  return 0
}
do_layout() {     # SESSION: quick check that the layout and Caps Lock are the Windows-Belgian ones
  echo; echo "=== Layout check ($1)"
  echo "Type the word  azerty  then switch Caps Lock ON and press the ten keys of the top row from 1 to 0"
  echo "(the keys that normally give & é \" ' ( § è ! ç à), switch Caps Lock OFF again, then Enter."
  local l; IFS= read -r -p "> " l
  if [ "$l" = azerty1234567890 ]; then log "layout check $1: ok ($l)"; echo "  ok"
  else log "layout check $1: typed [$l], expected [azerty1234567890]"; anomaly "$1 layout check: typed '$l' instead of 'azerty1234567890'"; fi
}
do_typing() {     # SESSION
  echo; echo "Now the fast-typing blocks: four blocks of $ROUNDS short lines, about 6 minutes."
  ask_block "$1 A keyd-on Ctrl+Alt" "Left Ctrl + Left Alt"
  ask_block "$1 B keyd-on AltGr" "AltGr"
  KEYD_STOPPED=1; sudo systemctl stop keyd; echo "(keyd stopped for this block: this is how stock Linux behaves)"
  ask_block "$1 C keyd-off AltGr (stock Linux)" "AltGr"
  restore; sleep 1
  [ "$(systemctl is-active keyd)" = active ] || anomaly "$1: keyd did not start again after block C"
  if pgrep -x ibus-daemon >/dev/null; then IBUS_STOPPED=1; ibus exit 2>/dev/null; sleep 2; fi
  if pgrep -x ibus-daemon >/dev/null; then echo "(ibus is running again: the desktop restarted it by itself)"; log "$1 D: ibus was restarted by the desktop before the block, D counts as a second A"
  else echo "(ibus stopped for this block)"; fi
  ask_block "$1 D keyd-on ibus-off Ctrl+Alt" "Left Ctrl + Left Alt"
  restore; sleep 2
  return 0
}
net_ok() { wget -q --spider --timeout=8 https://update.code.visualstudio.com/ 2>/dev/null; }
do_vscode() {     # SESSION
  echo; echo "=== VS Code ($1, optional)"
  if ! command -v code >/dev/null; then
    if ! net_ok; then
      echo "This part needs internet. Connect to Wi-Fi (top right corner) now and press Enter,"
      read -r -p "or type s and Enter to skip VS Code: " a
      [ "$a" = s ] && { log "VS Code $1: skipped by choice"; return 0; }
      net_ok || { log "VS Code $1: skipped, no internet"; echo "  no internet, skipped"; return 0; }
    fi
    echo "Downloading VS Code (about 100 MB)..."
    if ! (cd /tmp && wget -q -O code.deb 'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64'); then
      anomaly "VS Code $1: download failed"; return 0; fi
    if ! sudo DEBIAN_FRONTEND=noninteractive apt-get install -y /tmp/code.deb > "${WORK%/*}/vscode-apt.log" 2>&1; then
      anomaly "VS Code $1: install failed: $(tail -2 "${WORK%/*}/vscode-apt.log" | paste -sd ' ' -)"; return 0; fi
  fi
  local f=$HOME/vsc-$1.txt; : > "$f"
  echo "VS Code opens with an empty file. Type $ROUNDS lines as in block A: hold Left Ctrl + Left Alt the whole time and"
  echo "press 2, E, 2, E ... (eight pairs) so that each line reads @€@€@€@€@€@€@€@€, then Enter;"
  echo "as fast as you normally type, then save with Ctrl+S and close VS Code. The test carries on when VS Code closes."
  code --wait --new-window --disable-extensions --skip-welcome --skip-release-notes --disable-workspace-trust "$f" >/dev/null 2>&1
  log "-- $(date -u +%H:%M:%SZ) VS Code $(code --version 2>/dev/null | head -1) in ${XDG_SESSION_TYPE:-?}"
  score_block "$1 VS Code Ctrl+Alt" < "$f"
  [ -s "$f" ] || anomaly "VS Code $1: the file was empty (not saved?)"
  return 0
}
do_switch() {
  echo; echo "=== Switching to Wayland"
  echo "The screen goes black for a few seconds and comes back on Wayland. A terminal opens by itself and the test"
  echo "carries on. (If no terminal opens after a minute: Ctrl+Alt+T and the same command as before.)"
  # After the new login, a terminal reopens by itself. At session start the terminal service can be slow to answer
  # (in the emulator gnome-terminal gave up after 25 s), so try a few times and fall back to a notification.
  mkdir -p "${AUTOSTART%/*}"
  cat > "${STATE%/*}/resume.sh" <<RESUME
#!/bin/bash
sleep 5
for i in 1 2 3 4 5 6; do
  gnome-terminal -- bash -c 'bash "$HERE/run-test.sh"; exec bash' && exit 0
  sleep 10
done
notify-send -u critical "Belgian T14s test" "Press Ctrl+Alt+T and type: bash $HERE/run-test.sh"
RESUME
  printf '[Desktop Entry]\nType=Application\nName=Belgian T14s test (resume)\nExec=bash %s\nX-GNOME-Autostart-enabled=true\n' "${STATE%/*}/resume.sh" > "$AUTOSTART"
  printf '[daemon]\nWaylandEnable=true\nAutomaticLoginEnable=true\nAutomaticLogin=%s\n' "$USER" | sudo tee /etc/gdm3/custom.conf >/dev/null
  local acc=/var/lib/AccountsService/users/$USER
  sudo sed -i 's/^Session=.*/Session=zorin-wayland/; s/^XSession=.*/XSession=zorin-wayland/' "$acc" 2>/dev/null
  sudo grep -q '^Session=' "$acc" 2>/dev/null || printf '[User]\nSession=zorin-wayland\n' | sudo tee -a "$acc" >/dev/null
  log "switch to Wayland requested $(date -u +%H:%M:%SZ)"; publish
  pause "Ready."
  sudo systemctl restart gdm3
  sleep 60   # the session ends here; this line is only reached if gdm did not restart
  anomaly "the switch to Wayland did not happen"
}
finish() {
  local n; n=$(anomalies)
  log ""; log "== Summary $(date -u +%FT%TZ): $n anomalies"
  grep '^ANOMALY:' "$WORK" | sed 's/^ANOMALY: /  - /' >> "$WORK"
  log "== End of results"
  publish
  echo; echo "================================================================================"
  if [ "$n" = 0 ]; then echo "Finished. No anomalies found."; else echo "Finished. $n anomalies found:"; grep '^ANOMALY:' "$WORK" | sed 's/^ANOMALY: /  - /' | sort -u; fi
  echo
  echo "The results are in ONE file: $NAME"
  echo "  - on the desktop of this live session: $DESK/$NAME"
  if [ "$STICK_OK" = yes ]; then
    echo "  - and on the USB stick, folder t14s-test."
    echo "Now shut down (top right, Power Off), start Windows, open the USB stick, folder t14s-test, and send"
    echo "$NAME to the thread (drag the file in, or open it with Notepad and paste its text)."
  else
    echo "The USB stick could not be written, so the file is ONLY in this live session and is gone after shutdown."
    echo "Before shutting down, open Firefox, go to claude.ai and put the file from the desktop into the thread"
    echo "(or open it, select all, copy, and paste)."
  fi
  echo "================================================================================"
}

# --- main -----------------------------------------------------------------------------------------------------
if [ "$stage" = finished ]; then echo "The test is already finished. Results: $DESK/$NAME  (bash $0 --restart to do it again)"; exit 0; fi
sudo -n true 2>/dev/null || sudo -v || { echo "This test needs sudo."; exit 1; }
case $stage in
  start)
    do_setup || { finish; exit 1; }
    facts xorg-start; publish; set_stage xorg ;&
  xorg)
    if [ "${XDG_SESSION_TYPE:-}" != x11 ]; then anomaly "expected an Xorg session at the start, got ${XDG_SESSION_TYPE:-?}"; fi
    do_layout xorg; do_typing xorg; publish; set_stage xorg-vscode ;&
  xorg-vscode)
    do_vscode xorg; publish; set_stage wayland
    do_switch; exit 0 ;;
  wayland)
    rm -f "$AUTOSTART"
    echo "Welcome back. The test carries on, now on Wayland."
    facts wayland
    if [ "${XDG_SESSION_TYPE:-}" != wayland ]; then
      anomaly "the session after the switch is ${XDG_SESSION_TYPE:-?}, not Wayland: Wayland part skipped"
    else
      [ "$(systemctl is-active keyd)" = active ] || anomaly "keyd is not running after the switch to Wayland"
      do_layout wayland; do_typing wayland; publish; set_stage wayland-vscode
      do_vscode wayland
    fi
    set_stage finished; finish ;;
  wayland-vscode)
    do_vscode wayland; set_stage finished; finish ;;
  *) echo "Unknown progress '$stage': bash $0 --restart"; exit 1 ;;
esac
