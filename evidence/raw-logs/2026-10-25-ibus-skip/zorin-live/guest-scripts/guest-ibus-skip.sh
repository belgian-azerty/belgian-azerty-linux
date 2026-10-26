#!/bin/bash
# Guest side of the ibus-skip emulator test (live Mint 22.3 / Zorin 18.1). Served by the host on 10.0.2.2:8000;
# results go back with POST to 10.0.2.2:8001 (rig/upload_server.py). Run as the live user in a terminal:
#   bash /tmp/g.sh setup GTKVER     install the 0.9.5 packages + the Typebox app, Belgian layout for this session
#   bash /tmp/g.sh info LABEL       upload what the running apps see (environment, ibus-skip list, typed lines)
#   bash /tmp/g.sh do LABEL CMD...  run CMD, upload its output as LABEL.txt
H=http://10.0.2.2:8000; U=http://10.0.2.2:8001
up() { wget -q -O /dev/null --post-file="$1" "$U/$2"; }
case "$1" in
  setup)
    cd /tmp || exit 1
    for f in keyd_2.5.0-5~ubuntu24.04.2_amd64.deb keyd-belgian-windows_0.9.4_all.deb belgian-azerty-windows_0.9.5_all.deb typebox.py SHA256SUMS; do wget -q "$H/$f"; done
    { sha256sum -c --ignore-missing SHA256SUMS
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ./keyd_*.deb ./keyd-belgian-windows_*.deb ./belgian-azerty-windows_*.deb 2>&1 | tail -3
      sudo install -m 755 typebox.py /opt/typebox.py
      printf '%s\n' '[Desktop Entry]' 'Type=Application' 'Name=Typebox' 'Comment=ibus-skip test window' \
        "Exec=python3 /opt/typebox.py --gtk $2 --out /tmp/tb.txt" 'Categories=Utility;GTK;' | sudo tee /usr/share/applications/be-typebox.desktop >/dev/null
      be-azerty-fix live
      systemctl is-active keyd; echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE GTK_IM_MODULE=${GTK_IM_MODULE:-(unset)} QT_IM_MODULE=${QT_IM_MODULE:-(unset)}"
      pgrep -a ibus-daemon; be-azerty-fix ibus-skip; ls /etc/xdg/autostart/be-azerty-ibus-skip.desktop
    } > /tmp/setup.txt 2>&1; up /tmp/setup.txt setup.txt ;;
  info)
    o=/tmp/info-$2.txt
    { echo "== $2 $(date -u +%T)"
      echo "shell in this terminal: GTK_IM_MODULE=${GTK_IM_MODULE:-(unset)}"
      for p in $(pgrep -f gnome-terminal-server) $(pgrep -f typebox.py) $(pgrep -x gnome-text-edit) $(pgrep -x xed) $(pgrep -x code); do
        echo "pid $p $(tr '\0' ' ' < /proc/$p/cmdline | cut -c1-80): $(tr '\0' '\n' < /proc/$p/environ | grep '^GTK_IM_MODULE=' || echo GTK_IM_MODULE unset)"
      done
      echo "-- be-azerty-fix ibus-skip"; be-azerty-fix ibus-skip
      echo "-- files"; ls -la ~/.local/share/applications/ ~/.config/systemd/user/*.d/ ~/.config/belgian-azerty/ 2>&1
      echo "-- systemctl --user cat gnome-terminal-server"; systemctl --user cat gnome-terminal-server.service 2>&1 | grep -v '^$'
      echo "-- typebox info"; cat /tmp/tb.txt.info 2>&1
    } > "$o" 2>&1
    up "$o" "info-$2.txt"
    [ -f /tmp/tb.txt ] && { up /tmp/tb.txt "tb-$2.txt"; mv /tmp/tb.txt "/tmp/tb-$2.txt"; }
    [ -f /tmp/term.txt ] && { up /tmp/term.txt "term-$2.txt"; mv /tmp/term.txt "/tmp/term-$2.txt"; }
    rm -f /tmp/tb.txt.info ;;
  imcheck)
    # imcheck LABEL PROCNAME: per process, GTK_IM_MODULE and whether GTK's ibus module library is loaded (GTK 3 apps,
    # Electron) - a GTK 3 app that took the skip never loads im-ibus.so.
    o=/tmp/imcheck-$2.txt
    { echo "== $2 $3 $(date -u +%T)"
      for p in $(pgrep -x "$3"); do
        echo "pid $p $(tr '\0' ' ' < /proc/$p/cmdline | cut -c1-70): $(tr '\0' '\n' < /proc/$p/environ | grep '^GTK_IM_MODULE=' || echo GTK_IM_MODULE unset), im-ibus loaded: $(grep -c 'im-ibus' /proc/$p/maps)"
      done; } > "$o" 2>&1
    up "$o" "imcheck-$2.txt" ;;
  do)
    l=$2; shift 2; { echo "\$ $*"; "$@"; echo "exit $?"; } > "/tmp/$l.txt" 2>&1; up "/tmp/$l.txt" "$l.txt" ;;
esac
