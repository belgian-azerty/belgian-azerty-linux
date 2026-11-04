#!/bin/bash
# gtwi.sh STEP: guest side of the installed openSUSE Tumbleweed test with SELinux enforcing (Younes "go tumbleweed", 4 Nov).
# Steps: base, build (0.9.12-1 specs of the public repo at 4c5244a, as packaging/OTHER-DISTRIBUTIONS.md), inst, sys, gnome, kde, facts.
U=http://10.0.2.2:8001; STEP=$1; O=/tmp/gtwi-$STEP.txt
exec > $O 2>&1
up() { curl -s -m 5 -T $O $U/gtwi-$STEP.txt >/dev/null; }
facts() {
  echo "--- facts $(date -u +%H:%M:%SZ) $STEP"
  grep -E '^(PRETTY_NAME|VERSION_ID)=' /etc/os-release
  rpm -q xkeyboard-config libxkbcommon0 keyd belgian-azerty-windows keyd-belgian-windows kwin6 plasma6-workspace sddm systemd 2>&1
  echo "SELinux: getenforce=$(getenforce 2>&1) enforce-file=$(cat /sys/fs/selinux/enforce 2>&1) lsm=$(cat /sys/kernel/security/lsm 2>&1) cmdline-security=$(grep -oE '(security|selinux|apparmor)=[^ ]*' /proc/cmdline | tr '\n' ' ')"
  echo "/etc/xkb: $(find /etc/xkb -type f 2>/dev/null | tr '\n' ' ')"
  echo "our rule lines: caps:be_windows $(grep -c caps:be_windows /etc/xkb/rules/evdev 2>/dev/null) be_azerty:accents $(grep -c be_azerty:accents /etc/xkb/rules/evdev 2>/dev/null)"
  echo "rpm -V xkeyboard-config: [$(rpm -V xkeyboard-config 2>&1 | tr '\n' ';')]"
  command -v xkbcli >/dev/null && { xkbcli compile-keymap --kccgst --layout be --options caps:be_windows,be_azerty:accents 2>&1 | grep symbols; }
  echo "keyd: $(systemctl is-active keyd 2>&1) $(systemctl is-enabled keyd 2>&1); conf: $(ls /etc/keyd 2>&1 | tr '\n' ' ')"
  command -v keyd >/dev/null && echo "keyd version/check: $(keyd -v 2>&1 | head -1); $(sudo keyd check 2>&1 | tail -2 | tr '\n' ' ')"
  echo "keyd virtual devices: $(grep -c 'keyd virtual' /proc/bus/input/devices)"
  echo "session: $XDG_SESSION_TYPE $XDG_CURRENT_DESKTOP; gnome sources: $(gsettings get org.gnome.desktop.input-sources sources 2>&1) opts: $(gsettings get org.gnome.desktop.input-sources xkb-options 2>&1)"
  echo "kxkbrc: $(grep -E '^(LayoutList|Options|ResetOldOptions|Use)=' ~/.config/kxkbrc 2>/dev/null | tr '\n' ' ')"
  if command -v xkbcli >/dev/null && [ -n "$WAYLAND_DISPLAY" ]; then
    timeout --foreground -k 2 8 xkbcli dump-keymap-wayland > /tmp/wl.xkb 2>/tmp/wl.err < /dev/null
    echo "compositor keymap (exit $?): $(grep -m1 xkb_symbols /tmp/wl.xkb) be_capslock=$(grep -c be_capslock /tmp/wl.xkb)"
  fi
  echo "localectl: $(localectl status 2>&1 | tr -s ' ' | tr '\n' ';')"
  echo "AVC localed/xkb: $(sudo journalctl -b --no-pager 2>/dev/null | grep -iE 'avc.*denied' | grep -iE 'localed|xkb' | tail -2)"
}
case $STEP in
  build)
    df -h / /tmp | tail -2
    sudo zypper -n install --no-recommends rpm-build systemd-rpm-macros git curl 2>&1 | tail -3
    sudo zypper -n install --no-recommends libxkbcommon-tools 2>&1 | tail -1 || sudo zypper -n install --no-recommends xkbcli 2>&1 | tail -1
    mkdir -p /tmp/spec /tmp/rpmbuild/SOURCES && cd /tmp/spec
    for f in belgian-azerty-windows keyd-belgian-windows; do curl -sSfL -o $f.spec https://raw.githubusercontent.com/belgian-azerty/belgian-azerty-linux/4c5244a/packaging/opensuse/$f.spec; done
    sha256sum *.spec
    curl -sSfL -o /tmp/rpmbuild/SOURCES/belgian-azerty-linux-0.9.12.tar.gz https://github.com/belgian-azerty/belgian-azerty-linux/archive/refs/tags/v0.9.12.tar.gz
    sha256sum /tmp/rpmbuild/SOURCES/*.tar.gz
    for s in belgian-azerty-windows.spec keyd-belgian-windows.spec; do rpmbuild -ba --define "_topdir /tmp/rpmbuild" "$s" > /tmp/rpmbuild-$s.log 2>&1; echo "$s exit $?"; grep -E '^(Wrote|error|RPM build errors)' /tmp/rpmbuild-$s.log; done
    sha256sum /tmp/rpmbuild/RPMS/*/*.rpm ;;
  inst)
    sudo zypper -n install --allow-unsigned-rpm /tmp/rpmbuild/RPMS/noarch/*-0.9.12-*.rpm 2>&1 | tail -12 ;;
  sys)
    sudo localectl set-x11-keymap be pc105 "" caps:be_windows,be_azerty:accents; echo "localectl exit $?"; sleep 2 ;;
  gnome)
    gsettings set org.gnome.desktop.input-sources xkb-options "['caps:be_windows', 'be_azerty:accents']"
    gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'be')]"; sleep 3 ;;
  kde)
    kwriteconfig6 --file kxkbrc --group Layout --key LayoutList be
    kwriteconfig6 --file kxkbrc --group Layout --key VariantList ""
    kwriteconfig6 --file kxkbrc --group Layout --key Use true
    kwriteconfig6 --file kxkbrc --group Layout --key ResetOldOptions true
    kwriteconfig6 --file kxkbrc --group Layout --key Options caps:be_windows,be_azerty:accents
    dbus-send --session --type=signal --reply-timeout=100 /Layouts org.kde.keyboard.reloadConfig; sleep 3 ;;
esac
facts; up
