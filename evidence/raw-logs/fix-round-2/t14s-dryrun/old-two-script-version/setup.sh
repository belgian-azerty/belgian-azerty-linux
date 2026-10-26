#!/bin/bash
# T14s real-hardware test, live session of the Belgian Zorin OS 18.1 USB stick. See T14S-TEST-PLAN.md.
#   bash setup.sh            install the packages from this folder and switch everything on (keyd, Caps, Period)
#   bash setup.sh wayland    switch the live session from Xorg to Wayland (the session restarts by itself)
#   bash setup.sh vscode     download and install VS Code (needs internet)
# shellcheck disable=SC2024   # the logs are meant to be written as the live user, not as root
HERE=$(cd "$(dirname "$0")" && pwd)
LOG=$HOME/t14s-setup.log
set -u
case "${1:-}" in
  wayland)
    printf '[daemon]\nWaylandEnable=true\nAutomaticLoginEnable=true\nAutomaticLogin=%s\n' "$USER" | sudo tee /etc/gdm3/custom.conf >/dev/null
    sudo sed -i 's/^Session=.*/Session=zorin-wayland/; s/^XSession=.*/XSession=zorin-wayland/' "/var/lib/AccountsService/users/$USER" 2>/dev/null
    grep -q '^Session=' "/var/lib/AccountsService/users/$USER" 2>/dev/null || printf 'Session=zorin-wayland\n' | sudo tee -a "/var/lib/AccountsService/users/$USER" >/dev/null
    echo "The screen goes black for a moment and comes back on Wayland. Then open a terminal again (Ctrl+Alt+T)."
    sleep 3; sudo systemctl restart gdm3 ;;
  vscode)
    if command -v code >/dev/null; then echo "VS Code is already installed: start it with  code"; exit 0; fi
    cd /tmp && wget -q --show-progress -O code.deb 'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64' \
      || { echo "DOWNLOAD FAILED: is Wi-Fi connected (top right)?"; exit 1; }
    if sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ./code.deb > "$LOG" 2>&1; then echo "VS Code installed: start it with  code"
    else echo "VS CODE INSTALL FAILED. Last lines of $LOG:"; tail -15 "$LOG"; exit 1; fi ;;
  "")
    gsettings set org.gnome.desktop.session idle-delay 0; gsettings set org.gnome.desktop.screensaver lock-enabled false
    missing=""
    for f in keyd_ keyd-belgian-windows_ belgian-azerty-windows_; do ls "$HERE/$f"*.deb >/dev/null 2>&1 || missing="$missing ${f}*.deb"; done
    [ -f "$HERE/be-azerty-fix.sh" ] || missing="$missing be-azerty-fix.sh"
    if [ -n "$missing" ]; then echo "MISSING in $HERE:$missing  (copy the whole t14s-test folder onto the stick)"; exit 1; fi
    if [ -f "$HERE/SHA256SUMS" ]; then
      (cd "$HERE" && sha256sum --quiet -c SHA256SUMS) && echo "✔ files checked (SHA256SUMS)" || { echo "FILES DAMAGED (SHA256SUMS does not match): copy the folder again"; exit 1; }
    fi
    if sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$HERE"/keyd_*.deb "$HERE"/keyd-belgian-windows_*.deb "$HERE"/belgian-azerty-windows_*.deb > "$LOG" 2>&1; then
      echo "✔ packages installed"
    else echo "PACKAGE INSTALL FAILED. Last lines of $LOG:"; tail -15 "$LOG"; exit 1; fi
    sudo bash "$HERE/be-azerty-fix.sh" system > "$HOME/t14s-fix.log" 2>&1; rc=$?
    grep -E '✔|✘|Choices' "$HOME/t14s-fix.log"
    [ $rc = 0 ] || echo "be-azerty-fix reported a problem (full output in $HOME/t14s-fix.log)"
    echo; echo "Session type: $XDG_SESSION_TYPE   keyd: $(systemctl is-active keyd)   ibus: $(pgrep -x ibus-daemon >/dev/null && echo running || echo stopped)"
    echo "Next:  bash $HERE/typing-order-check.sh" ;;
  *) sed -n '2,5p' "$0" ;;
esac
