#!/bin/bash
# Build the Belgian stick's extra layer: our two packages and keyd installed on top of a distribution's untouched system
# image, as a second squashfs that casper stacks above filesystem.squashfs. The layer holds only what installing the
# packages changed, the keyd-team PPA entry, plus the stick glue (belgian-stick, its two services, the Ubiquity hook).
#   sudo tools/stick/build-layer.sh filesystem.squashfs DEB_DIR OUT.squashfs
# Needs root (loop and overlay mounts, chroot) and squashfs-tools.
set -euo pipefail
SQ=$1; DEBS=$2; OUT=$3
HERE=$(cd "$(dirname "$0")" && pwd)
W=$(mktemp -d)
# Programs started inside the chroot (gpg-agent, dirmngr ...) keep its mounts busy: stop them before unmounting.
stop_chroot() { local p; for p in /proc/[0-9]*; do
                  [ "$(readlink "$p/root" 2>/dev/null)" = "$W/root" ] && kill -9 "${p#/proc/}" 2>/dev/null; done; sleep 1; }
cleanup() { stop_chroot
            for m in dev/pts dev proc sys "" ; do umount "$W/root/$m" 2>/dev/null || umount -l "$W/root/$m" 2>/dev/null || true; done
            umount "$W/lower" 2>/dev/null || umount -l "$W/lower" 2>/dev/null || true
            # Never delete through a mount: $W/root/dev is the build machine's own /dev while it is bind-mounted.
            if findmnt -rn -o TARGET | grep -q "^$W/"; then echo "cleanup: mounts left under $W, not deleting it" >&2; return; fi
            rm -rf --one-file-system "$W"; }
trap cleanup EXIT
mkdir -p "$W/lower" "$W/upper" "$W/work" "$W/root"
mount -o loop,ro "$SQ" "$W/lower"
mount -t overlay -o "lowerdir=$W/lower,upperdir=$W/upper,workdir=$W/work" overlay "$W/root"
for m in dev dev/pts proc sys; do mount --bind "/$m" "$W/root/$m"; done
mkdir -p "$W/root/tmp/belgian"
cp "$DEBS"/keyd_*_amd64.deb "$DEBS"/keyd-belgian-windows_*_all.deb "$DEBS"/belgian-azerty-windows_*_all.deb "$W/root/tmp/belgian/"
printf '#!/bin/sh\nexit 101\n' > "$W/root/usr/sbin/policy-rc.d"; chmod 755 "$W/root/usr/sbin/policy-rc.d"   # start nothing
chroot "$W/root" sh -c 'DEBIAN_FRONTEND=noninteractive apt-get install -y /tmp/belgian/*.deb'
# keyd comes from the keyd-team PPA: add that source with the distribution's own tool (Ubuntu's or Mint's
# add-apt-repository), so a system installed from the stick gets keyd updates and a later add-apt-repository (README)
# finds the same entry. Needs the internet while building; PPA=0 leaves it out.
if [ "${PPA:-1}" = 1 ]; then
  rm -f "$W/root/etc/resolv.conf"; cat /etc/resolv.conf > "$W/root/etc/resolv.conf"   # the image's own one needs /run
  chroot "$W/root" sh -c 'add-apt-repository -y -n ppa:keyd-team/ppa </dev/null || add-apt-repository -y ppa:keyd-team/ppa </dev/null'
  stop_chroot   # Mint's tool fetches the key with gpg, which leaves dirmngr running in the chroot
  # Mint's tool gets the key from keyserver.ubuntu.com and still writes the source when that fails. Then put the
  # PPA's key (keyd-team-ppa.asc, Launchpad PPA for keyd, checked below by fingerprint) where the source expects it.
  grep -rls keyd-team "$W/root/etc/apt/sources.list.d/" | while read -r f; do
    k=$(sed -n 's/.*signed-by=\([^] ]*\).*/\1/p' "$f" | head -1)
    if [ -n "$k" ] && [ ! -e "$W/root$k" ]; then
      mkdir -p "$W/root${k%/*}"; gpg --dearmor < "$HERE/keyd-team-ppa.asc" > "$W/root$k"; chmod 644 "$W/root$k"
      echo "the key download failed for ${f#"$W/root"}; used tools/stick/keyd-team-ppa.asc for $k"
    fi
  done
  rm -f "$W/root/etc/apt/keyrings/67D33FE29A58DA9441D20A9DCD9F79EC6A8AFB2F.keyring"*   # Mint's tool's leftover after a failed download
  # Every keyd-team source must carry the PPA's signing key.
  python3 "$HERE/check-ppa-key.py" "$W/root" 67D33FE29A58DA9441D20A9DCD9F79EC6A8AFB2F
fi
install -D -m 755 "$HERE/belgian-stick" "$W/root/usr/local/lib/belgian-stick/belgian-stick"
install -D -m 644 "$HERE/belgian-stick-live.service" "$W/root/etc/systemd/system/belgian-stick-live.service"
install -D -m 644 "$HERE/belgian-azerty-firstboot.service" "$W/root/etc/systemd/system/belgian-azerty-firstboot.service"
mkdir -p "$W/root/etc/systemd/system/multi-user.target.wants"
ln -sf /etc/systemd/system/belgian-stick-live.service "$W/root/etc/systemd/system/multi-user.target.wants/belgian-stick-live.service"
install -D -m 755 "$HERE/90belgian_azerty" "$W/root/usr/lib/ubiquity/target-config/90belgian_azerty"
dpkg-query --admindir="$W/root/var/lib/dpkg" -W keyd keyd-belgian-windows belgian-azerty-windows
stop_chroot
for m in dev/pts dev proc sys; do umount "$W/root/$m"; done
umount "$W/root"
# Leave out build leftovers: these paths fall back to the system image's own version.
rm -rf "$W/upper/tmp/belgian" "$W/upper/usr/sbin/policy-rc.d" "$W/upper/var/cache/apt" "$W/upper/var/cache/man" \
       "$W/upper/var/cache/ldconfig" "$W/upper/var/log" "$W/upper/root" "$W/upper/etc/resolv.conf" "$W/upper/var/lib/apt/lists"
rmdir "$W/upper/tmp" 2>/dev/null || true
echo "layer contents:"; (cd "$W/upper" && find . -maxdepth 3 | sort | head -80)
rm -f "$OUT"; # -no-xattrs: no overlayfs bookkeeping attributes (trusted.overlay.*) in a layer that casper stacks again
mksquashfs "$W/upper" "$OUT" -comp xz -noappend -quiet -no-xattrs
ls -l "$OUT"
