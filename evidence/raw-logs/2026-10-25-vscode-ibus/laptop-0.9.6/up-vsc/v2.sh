#!/bin/bash
# Guest side of the VS Code ibus-skip test (live Mint 22.3 / Zorin 18.1, packages 0.9.6). Host serves this folder on
# 10.0.2.2:$HP (default 8010); results go back with POST to 10.0.2.2:$UPP (default 8011). Run as the live user:
#   bash /tmp/v.sh setup            install the 0.9.6 packages (sha-checked), "be-azerty-fix live", then VS Code
#                                   (official .deb from update.code.visualstudio.com)
#   bash /tmp/v.sh open LABEL MODE  MODE ibus: VS Code from its stock menu entry; MODE skip: first
#                                   "be-azerty-fix ibus-skip on com.microsoft.VSCode", then from the marked menu copy. Opens the
#                                   empty file /tmp/vsc-LABEL.txt; after 25 s records the main process's environment.
#   bash /tmp/v.sh fin LABEL        upload /tmp/vsc-LABEL.txt (saved with Ctrl+S) and the recorded environment
#   bash /tmp/v.sh do LABEL CMD...  run CMD, upload its output as LABEL.txt
HP=${HP:-8010}; UPP=${UPP:-8011}
H=http://10.0.2.2:$HP; U=http://10.0.2.2:$UPP
up() { wget -q -O /dev/null --post-file="$1" "$U/$2"; }
case "$1" in
  setup)
    cd /tmp || exit 1
    wget -q "$H/SHA256SUMS"
    for f in $(awk '/_all\.deb$|_amd64\.deb$/ {sub("^\\./","",$2); print $2}' SHA256SUMS); do wget -q "$H/$f"; done
    { sha256sum -c --ignore-missing SHA256SUMS
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ./keyd_*_amd64.deb ./keyd-belgian-windows_*.deb ./belgian-azerty-windows_*.deb 2>&1 | tail -2
      be-azerty-fix live
      echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE GTK_IM_MODULE=${GTK_IM_MODULE:-(unset)}"
      echo "-- VS Code"
      wget -q -O /tmp/code.deb "https://update.code.visualstudio.com/latest/linux-deb-x64/stable" && ls -l /tmp/code.deb && sha256sum /tmp/code.deb
      dpkg-deb -f /tmp/code.deb Package Version Maintainer
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y /tmp/code.deb 2>&1 | tail -2
      code --version 2>/dev/null | head -2
      echo "-- be-azerty-fix ibus-skip"; be-azerty-fix ibus-skip
    } > /tmp/setup.txt 2>&1; up /tmp/setup.txt setup.txt ;;
  open)
    l=$2; f=/tmp/vsc-$l.txt; : > "$f"
    if [ "$3" = skip ]; then be-azerty-fix ibus-skip on com.microsoft.VSCode > /tmp/on-$l.txt 2>&1; up /tmp/on-$l.txt "on-$l.txt"; d=$HOME/.local/share/applications/com.microsoft.VSCode.desktop
    else d=/usr/share/applications/com.microsoft.VSCode.desktop; fi
    ( gio launch "$d" "$f" >/dev/null 2>&1 & )
    ( sleep 25
      { echo "== $l ($3) $(date -u +%T), launched with: $d"
        grep '^Exec=' "$d" | head -1
        for p in $(pgrep -f '/usr/share/code/code' | head -3); do
          echo "pid $p $(tr '\0' ' ' < /proc/$p/cmdline | cut -c1-90): $(tr '\0' '\n' < /proc/$p/environ | grep '^GTK_IM_MODULE=' || echo GTK_IM_MODULE unset), im-ibus loaded: $(grep -c 'im-ibus' /proc/$p/maps)"
        done; } > /tmp/env-$l.txt 2>&1 ) & ;;
  fin)
    l=$2; up "/tmp/vsc-$l.txt" "vsc-$l.txt"; up "/tmp/env-$l.txt" "env-$l.txt" ;;
  do)
    l=$2; shift 2; { echo "\$ $*"; "$@"; echo "exit $?"; } > "/tmp/$l.txt" 2>&1; up "/tmp/$l.txt" "$l.txt" ;;
esac
