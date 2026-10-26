#!/bin/bash
# stick-fingerprint.sh STICK.iso: the content of a Belgian stick that must match between two builds from the same
# stock ISO and packages (the ISO file itself is not byte-reproducible: timestamps). Prints sorted "sha256  path" lines
# for the boot menus, /belgian/*, /md5sum.txt without the layer's own line, and our files in the package layer
# (/casper/zz-belgian-azerty.squashfs; files that apt rewrites with timestamps, .pyc caches and logs are left out).
# Needs xorriso and squashfs-tools. Run as root.
set -eu
iso=$(readlink -f "$1"); x=$(mktemp -d); trap 'chmod -R u+w "$x" 2>/dev/null; rm -rf "$x"' EXIT
for f in /boot/grub/grub.cfg /boot/grub/loopback.cfg /isolinux/menuentries.cfg /isolinux/live.cfg /md5sum.txt; do
  xorriso -osirrox on -indev "$iso" -extract "$f" "$x/$(basename "$f")" >/dev/null 2>&1 || true
done
xorriso -osirrox on -indev "$iso" -extract /belgian "$x/belgian" >/dev/null 2>&1
xorriso -osirrox on -indev "$iso" -extract /casper/zz-belgian-azerty.squashfs "$x/layer.sqfs" >/dev/null 2>&1
unsquashfs -q -d "$x/layer" "$x/layer.sqfs" >/dev/null
cd "$x"
{ for f in grub.cfg loopback.cfg menuentries.cfg live.cfg; do [ -f "$f" ] && sha256sum "$f"; done
  # md5sum.txt lists the squashfs layer, whose bytes carry timestamps; drop that one line
  grep -v 'zz-belgian-azerty.squashfs' md5sum.txt | sha256sum | sed 's|-$|md5sum.txt (without the layer line)|'
  (cd belgian && sha256sum ./* | sed 's|  \./|  belgian/|')
  OURS='^\./(usr/sbin/be-azerty-fix|usr/bin/(be-azerty-settings|keyd)|usr/lib/belgian-azerty-windows/|usr/local/lib/belgian-stick/|etc/keyd/|etc/systemd/system/(belgian|keyd)|usr/lib/systemd/system/keyd|etc/xdg/autostart/be-azerty|usr/share/X11/xkb/(symbols/be_capslock|rules/evdev)|usr/share/applications/be-azerty|usr/share/polkit-1/actions/org\.belgianazerty|var/lib/belgian-azerty-windows/)'
  (cd layer && find . -type f | grep -E "$OURS" | sort | while read -r f; do sha256sum "$f"; done | sed 's|  \./|  layer/|')
} | sort -k2
