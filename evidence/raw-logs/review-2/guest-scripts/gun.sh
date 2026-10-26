#!/bin/bash
# uninstall and verify: $1 = label
L=$1; cd /tmp
{ echo "== be-azerty-fix uninstall"; sudo be-azerty-fix uninstall; echo "rc=$?"
  echo "== after"; dpkg -l keyd keyd-belgian-windows belgian-azerty-windows 2>&1 | grep -E '^(ii|rc|un)|aucun|no packages' ; echo "dpkg-query: $(dpkg-query -W keyd keyd-belgian-windows belgian-azerty-windows 2>&1 | tr '\n' ' ')"
  echo "diversions: $(dpkg-divert --list | grep -c evdev)"
  want=$(grep ' usr/share/X11/xkb/rules/evdev$' /var/lib/dpkg/info/xkb-data.md5sums | cut -d' ' -f1); have=$(md5sum < /usr/share/X11/xkb/rules/evdev | cut -d' ' -f1)
  echo "evdev md5 $have, xkb-data says $want: $([ "$have" = "$want" ] && echo IDENTICAL || echo DIFFERENT)"
  echo "dpkg -V xkb-data: [$(dpkg -V xkb-data)]"
  ls -la /usr/share/X11/xkb/rules/evdev.distrib /usr/share/X11/xkb/symbols/be_capslock /usr/share/glib-2.0/schemas/zz_belgian-azerty-windows.gschema.override /etc/keyd /usr/lib/systemd/system/keyd.service.d 2>&1
  echo "keyd service: $(systemctl is-active keyd 2>&1) / $(systemctl is-enabled keyd 2>&1)"
  grep XKB /etc/default/keyboard
  echo "Cinnamon default now: $(GSETTINGS_BACKEND=memory gsettings get org.cinnamon.desktop.input-sources xkb-options 2>&1)"; echo "gnome user setting: $(gsettings get org.gnome.desktop.input-sources xkb-options)"
  echo "user setting now: $(gsettings get org.cinnamon.desktop.input-sources xkb-options 2>&1)"; echo "gnome user setting: $(gsettings get org.gnome.desktop.input-sources xkb-options)"
  setxkbmap -query | grep options
  echo "keyd unit: $(systemctl show keyd -p LoadState -p ActiveState 2>&1 | tr "\n" " ")"; echo "be-azerty-fix still present: $(command -v be-azerty-fix || echo no)"
} > /tmp/un-$L.txt 2>&1
wget -q --post-file=/tmp/un-$L.txt http://10.0.2.2:8001/un-$L.txt -O /dev/null; echo GUNDONE
