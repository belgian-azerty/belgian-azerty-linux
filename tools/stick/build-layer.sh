#!/bin/bash
# Build the Belgian stick's extra layer: our three packages installed on top of a distribution's untouched system
# image, as a second squashfs that casper stacks above filesystem.squashfs. The layer holds only what installing the
# packages changed, plus the stick glue (belgian-stick, its two services, the Ubiquity hook).
#   sudo tools/stick/build-layer.sh filesystem.squashfs DEB_DIR OUT.squashfs
# Needs root (loop and overlay mounts, chroot) and squashfs-tools.
set -euo pipefail
SQ=$1; DEBS=$2; OUT=$3
HERE=$(cd "$(dirname "$0")" && pwd)
W=$(mktemp -d)
cleanup() { for m in dev/pts dev proc sys; do umount "$W/root/$m" 2>/dev/null || true; done
            umount "$W/root" 2>/dev/null || true; umount "$W/lower" 2>/dev/null || true; rm -rf "$W"; }
trap cleanup EXIT
mkdir -p "$W/lower" "$W/upper" "$W/work" "$W/root"
mount -o loop,ro "$SQ" "$W/lower"
mount -t overlay -o "lowerdir=$W/lower,upperdir=$W/upper,workdir=$W/work" overlay "$W/root"
for m in dev dev/pts proc sys; do mount --bind "/$m" "$W/root/$m"; done
mkdir -p "$W/root/tmp/belgian"
cp "$DEBS"/keyd_*_amd64.deb "$DEBS"/keyd-belgian-windows_*_all.deb "$DEBS"/belgian-azerty-windows_*_all.deb "$W/root/tmp/belgian/"
printf '#!/bin/sh\nexit 101\n' > "$W/root/usr/sbin/policy-rc.d"; chmod 755 "$W/root/usr/sbin/policy-rc.d"   # start nothing
chroot "$W/root" sh -c 'DEBIAN_FRONTEND=noninteractive apt-get install -y /tmp/belgian/*.deb'
install -D -m 755 "$HERE/belgian-stick" "$W/root/usr/local/lib/belgian-stick/belgian-stick"
install -D -m 644 "$HERE/belgian-stick-live.service" "$W/root/etc/systemd/system/belgian-stick-live.service"
install -D -m 644 "$HERE/belgian-azerty-firstboot.service" "$W/root/etc/systemd/system/belgian-azerty-firstboot.service"
mkdir -p "$W/root/etc/systemd/system/multi-user.target.wants"
ln -sf /etc/systemd/system/belgian-stick-live.service "$W/root/etc/systemd/system/multi-user.target.wants/belgian-stick-live.service"
install -D -m 755 "$HERE/90belgian_azerty" "$W/root/usr/lib/ubiquity/target-config/90belgian_azerty"
dpkg-query --admindir="$W/root/var/lib/dpkg" -W keyd keyd-belgian-windows belgian-azerty-windows
for m in dev/pts dev proc sys; do umount "$W/root/$m"; done
umount "$W/root"
# Leave out build leftovers: these paths fall back to the system image's own version.
rm -rf "$W/upper/tmp/belgian" "$W/upper/usr/sbin/policy-rc.d" "$W/upper/var/cache/apt" "$W/upper/var/cache/man" \
       "$W/upper/var/cache/ldconfig" "$W/upper/var/log" "$W/upper/root"
rmdir "$W/upper/tmp" 2>/dev/null || true
echo "layer contents:"; (cd "$W/upper" && find . -maxdepth 3 | sort | head -80)
rm -f "$OUT"; # -no-xattrs: no overlayfs bookkeeping attributes (trusted.overlay.*) in a layer that casper stacks again
mksquashfs "$W/upper" "$OUT" -comp xz -noappend -quiet -no-xattrs
ls -l "$OUT"
