#!/bin/bash
# gfed.sh STEP: guest side of the Fedora live test (point 3b). Writes /tmp/gfed-STEP.txt and uploads it to :8001.
# Steps: base, build (as packaging/OTHER-DISTRIBUTIONS.md, public repo at 4c5244a), inst, opts (GNOME user), sys (localectl).
U=http://10.0.2.2:8001; STEP=$1; O=/tmp/gfed-$STEP.txt
exec > $O 2>&1
up() { wget -q -T 5 --post-file=$O $U/gfed-$STEP.txt -O /dev/null 2>/dev/null || curl -s -m 5 -T $O $U/gfed-$STEP.txt >/dev/null; }
facts() {
  echo "--- facts $(date -u +%H:%M:%SZ) $STEP"
  grep -E '^(PRETTY_NAME|VERSION_ID)=' /etc/os-release
  rpm -q xkeyboard-config libxkbcommon keyd belgian-azerty-windows keyd-belgian-windows gnome-shell 2>&1
  echo "/etc/xkb: $(find /etc/xkb -type f 2>/dev/null | tr '\n' ' ')"
  echo "our rule lines in /etc/xkb/rules/evdev: caps:be_windows $(grep -c caps:be_windows /etc/xkb/rules/evdev 2>/dev/null) be_azerty:accents $(grep -c be_azerty:accents /etc/xkb/rules/evdev 2>/dev/null)"
  echo "rpm -V xkeyboard-config: [$(rpm -V xkeyboard-config 2>&1 | tr '\n' ';')]"
  command -v xkbcli >/dev/null && { xkbcli compile-keymap --kccgst --layout be --options caps:be_windows,be_azerty:accents 2>&1 | grep symbols; }
  echo "keyd: $(systemctl is-active keyd 2>&1) $(systemctl is-enabled keyd 2>&1); conf: $(ls /etc/keyd 2>&1 | tr '\n' ' ')"
  command -v keyd >/dev/null && echo "keyd check: $(sudo keyd check 2>&1 | tail -3 | tr '\n' ' ')"
  echo "keyd virtual devices: $(grep -c 'keyd virtual' /proc/bus/input/devices)"
  echo "session: $XDG_SESSION_TYPE $XDG_CURRENT_DESKTOP; sources: $(gsettings get org.gnome.desktop.input-sources sources) opts: $(gsettings get org.gnome.desktop.input-sources xkb-options)"
  if command -v xkbcli >/dev/null && [ -n "$WAYLAND_DISPLAY" ]; then
    timeout --foreground -k 2 8 xkbcli dump-keymap-wayland > /tmp/wl.xkb 2>/tmp/wl.err < /dev/null
    echo "compositor keymap (exit $?): $(grep -m1 xkb_symbols /tmp/wl.xkb) be_capslock=$(grep -c be_capslock /tmp/wl.xkb)"
  fi
  echo "localectl: $(localectl status 2>&1 | tr -s ' ' | tr '\n' ';')"
  echo "gdm dconf: $(timeout 5 sudo -n -u gdm dbus-run-session gsettings get org.gnome.desktop.input-sources sources </dev/null 2>&1 | tail -1)"
}
case $STEP in
  build)
    sudo dnf install -y -q rpm-build rpmdevtools gcc make kernel-headers systemd-rpm-macros git libxkbcommon-utils 2>&1 | tail -3
    # The live overlay is too small for a full clone (first try: "No space left on device"), so: the three spec files
    # of the public repo at 4c5244a, built in /tmp (RAM). Same specs and same sources as the documented steps.
    rm -rf ~/belgian-azerty-linux; df -h / /tmp | tail -2
    mkdir -p /tmp/spec && cd /tmp/spec
    for f in keyd belgian-azerty-windows keyd-belgian-windows; do curl -sSfL -o $f.spec https://raw.githubusercontent.com/belgian-azerty/belgian-azerty-linux/4c5244a/packaging/fedora/$f.spec; done
    sha256sum *.spec
    for s in keyd.spec belgian-azerty-windows.spec keyd-belgian-windows.spec; do spectool -g -R --define "_topdir /tmp/rpmbuild" "$s" 2>&1 | tail -1; rpmbuild -ba --define "_topdir /tmp/rpmbuild" "$s" > /tmp/rpmbuild-$s.log 2>&1; echo "$s exit $?"; grep -E '^(Wrote|error|RPM build errors)' /tmp/rpmbuild-$s.log; done
    ls -l /tmp/rpmbuild/RPMS/*/; sha256sum /tmp/rpmbuild/RPMS/*/*.rpm ;;
  inst)
    sudo dnf install -y /tmp/rpmbuild/RPMS/x86_64/keyd-2.6.0-*.rpm /tmp/rpmbuild/RPMS/noarch/*-0.9.12-*.rpm 2>&1 | tail -15 ;;
  opts)
    gsettings set org.gnome.desktop.input-sources xkb-options "['caps:be_windows', 'be_azerty:accents']"
    gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'be')]"; sleep 3 ;;
  sys)
    sudo localectl set-x11-keymap be pc105 "" caps:be_windows,be_azerty:accents; sleep 2 ;;
esac
facts; up
