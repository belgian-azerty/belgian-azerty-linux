#!/bin/bash
# g26.sh STEP: guest side of the Ubuntu 26.04 live test (point 3). Writes /tmp/g26-STEP.txt and uploads it to :8001.
# Steps: apt (keyd + 0.9.11), up912 (upgrade to 0.9.12), xkbre (reinstall xkb-data), opts (GNOME user options), facts.
S=http://10.0.2.2:8000; U=http://10.0.2.2:8001; STEP=$1; O=/tmp/g26-$STEP.txt
facts() {
  echo "--- facts $(date -u +%H:%M:%SZ) $STEP"
  cat /etc/os-release | grep -E '^(PRETTY_NAME|VERSION_ID)='
  dpkg-query -W -f '${Package} ${Version} ${Status}\n' xkb-data keyd belgian-azerty-windows keyd-belgian-windows 2>&1
  R=$(readlink -f /usr/share/X11/xkb/rules/evdev); echo "rules real name: $R"
  echo "diversions: $(dpkg-divert --list 2>/dev/null | grep -E 'evdev|be_capslock' | tr '\n' ';')"
  echo "rule lines caps:be_windows: $(grep -c 'caps:be_windows' "$R")  be_azerty:accents: $(grep -c 'be_azerty:accents' "$R")  be_azerty:mac: $(grep -c 'be_azerty:mac' "$R")"
  echo "our block markers: $(grep -c '// belgian-azerty-windows:' "$R")"
  echo "dpkg -V xkb-data: [$(dpkg -V xkb-data 2>&1 | tr '\n' ';')]"
  xkbcli compile-keymap --layout be --options caps:be_windows,be_azerty:accents >/tmp/km.txt 2>/tmp/km.err; echo "xkbcli compile be+options: exit $? $(wc -l </tmp/km.txt) lines, err: $(head -c 300 /tmp/km.err | tr '\n' ' ')"
  echo "keyd: $(systemctl is-active keyd 2>&1) $(systemctl is-enabled keyd 2>&1); conf: $(ls /etc/keyd 2>&1 | tr '\n' ' ')"
  echo "keyd input devices: $(grep -c 'keyd virtual' /proc/bus/input/devices)"
  echo "session: $XDG_SESSION_TYPE $XDG_CURRENT_DESKTOP; gnome sources: $(gsettings get org.gnome.desktop.input-sources sources) opts: $(gsettings get org.gnome.desktop.input-sources xkb-options)"
  echo "localectl: $(localectl status 2>&1 | tr -s ' ' | tr '\n' ';')"
}
{
case $STEP in
  apt)
    cd /tmp; for f in belgian-azerty-windows_0.9.11_all.deb keyd-belgian-windows_0.9.11_all.deb belgian-azerty-windows_0.9.12_all.deb keyd-belgian-windows_0.9.12_all.deb SHA256SUMS-debs; do wget -q $S/$f -O $f; done
    sha256sum -c SHA256SUMS-debs
    grep -h '^Components' /etc/apt/sources.list.d/*.sources
    sudo apt-get update -q 2>&1 | tail -3
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q keyd 2>&1 | tail -4
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q ./belgian-azerty-windows_0.9.11_all.deb ./keyd-belgian-windows_0.9.11_all.deb 2>&1 | tail -12
    ;;
  up912)
    cd /tmp; sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q ./belgian-azerty-windows_0.9.12_all.deb ./keyd-belgian-windows_0.9.12_all.deb 2>&1 | tail -12 ;;
  xkbre)
    sudo DEBIAN_FRONTEND=noninteractive apt-get install --reinstall -y -q xkb-data 2>&1 | tail -6 ;;
  opts)
    gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'be')]"
    gsettings set org.gnome.desktop.input-sources xkb-options "['caps:be_windows', 'be_azerty:accents']"
    sleep 2 ;;
esac
facts
} > $O 2>&1
wget -q --post-file=$O $U/g26-$STEP.txt -O /dev/null; echo "uploaded $O"
