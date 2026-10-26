#!/bin/bash
# Build keyd for Ubuntu 24.04 (noble: Linux Mint 22, Zorin OS 18), which ship no keyd: a rebuild of Debian's own
# keyd 2.5.0-5 source package (maintained in Debian by Richard Hansen, salsa.debian.org/debian/keyd) plus ONE patch
# of this project, patches/0012-Keep-AltGr-held-while-a-Ctrl-Alt-layer-is-held.patch (from 0.9.4, Younes's decision
# of 2026-10-24 23:11Z; its header says what it changes, why, and the measured numbers). Until 0.9.3 the rebuild was
# unchanged (2.5.0-5~ubuntu24.04.1). The version 2.5.0-5~ubuntu24.04.2 still sorts below Debian's 2.5.0-5, so a
# keyd from the distribution always wins (and then the patch is gone: Ctrl+Alt still works, as in 0.9.3).
# From 2.5.0-5~ubuntu24.04.3 (0.9.6.1, Younes 2026-10-25 19:26Z) the Maintainer field names Younes, who builds this
# backport; Debian's maintainer stays in XSBC-Original-Maintainer (Ubuntu's convention for changed Debian packages).
# Only metadata differs from .2: same source and patch; the keyd program differs only in its build ID (an identity
# checksum the linker stamps in), its machine code and data are byte-identical (checked for 0.9.6.1).
# Note: Debian names the binary /usr/bin/keyd.rvaiya (Debian bug #1098982); the service is still keyd.service.
#   build.sh OUTDIR        (needs: build-essential debhelper dh-python python3 scdoc devscripts curl)
set -euo pipefail
OUT=$(realpath "${1:?usage: build.sh OUTDIR}")
HERE=$(cd "$(dirname "$0")" && pwd)
BASE=https://deb.debian.org/debian/pool/main/k/keyd
declare -A SHA=(
  [keyd_2.5.0-5.dsc]=""   # checked through the .dsc's own checksums below
  [keyd_2.5.0.orig.tar.gz]=93ec6c153ef673a7a8b4d8b686494dee11d182513f4531c71dce15a8db7f6c1c
  [keyd_2.5.0-5.debian.tar.xz]=58a10ccc8186197ff9f33da9229f2f840ca00b8c27dab78f58aacc78823328b8
)
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
cd "$W"
for f in "${!SHA[@]}"; do curl -sSfLO "$BASE/$f"; done
for f in keyd_2.5.0.orig.tar.gz keyd_2.5.0-5.debian.tar.xz; do
  echo "${SHA[$f]}  $f" | sha256sum -c --quiet
done
dpkg-source -x keyd_2.5.0-5.dsc >/dev/null 2>&1    # also checks the files against the .dsc
cd keyd-2.5.0
# Our one patch: added to Debian's quilt series; dpkg-buildpackage applies it (dpkg-source --before-build).
PATCH=0012-Keep-AltGr-held-while-a-Ctrl-Alt-layer-is-held.patch
cp "$HERE/patches/$PATCH" debian/patches/
echo "$PATCH" >> debian/patches/series
export DEBFULLNAME="${DEBFULLNAME:-Younes}" DEBEMAIL="${DEBEMAIL:-linuxbelgiumkeyboard.rc0g4@aleeas.com}"
# Maintainer: the builder of this backport; Debian's maintainer moves to XSBC-Original-Maintainer.
orig=$(sed -n 's/^Maintainer: //p' debian/control)
sed -i "s/^Maintainer: .*/Maintainer: $DEBFULLNAME <$DEBEMAIL>\nXSBC-Original-Maintainer: $orig/" debian/control
dch -b -v 2.5.0-5~ubuntu24.04.3 -D noble \
  "Backport of Debian keyd 2.5.0-5 to Ubuntu 24.04 (noble), the base of Linux Mint 22 and Zorin OS 18, which ship no keyd. The version sorts below 2.5.0-5, so a distribution keyd always replaces it." 2>/dev/null
dch -a "Add patch 0012-Keep-AltGr-held-while-a-Ctrl-Alt-layer-is-held.patch (Belgian AZERTY project, not upstream yet): while a Ctrl+Alt layer is held, keep AltGr down between keys instead of putting Ctrl+Alt back after every key (2 key events per character instead of about 8). Fewer swapped characters with ibus at very fast Ctrl+Alt typing. Six test expectations updated." 2>/dev/null
dch -a "Maintainer: Younes (builder of this backport); Debian's maintainer kept as XSBC-Original-Maintainer. Same source and patch as 2.5.0-5~ubuntu24.04.2." 2>/dev/null
# Pin the date dch wrote, so two builds give the same packages (second review R2-10). It must lie in the past:
# dpkg only clamps file times that are newer than this date (SOURCE_DATE_EPOCH), so a future date changes nothing.
sed -i "0,/^ -- /s/^\( -- .*>\)  .*/\1  Sun, 25 Oct 2026 19:00:00 +0000/" debian/changelog
dpkg-buildpackage -us -uc -sa > ../build.log 2>&1 || { tail -30 ../build.log; exit 1; }
cd ..
mkdir -p "$OUT"
V=2.5.0-5~ubuntu24.04.3
grep -q "applying $PATCH" build.log || { echo "our patch was not applied"; exit 1; }
rm -f "$OUT"/keyd_*~ubuntu24.04.*_amd64.deb "$OUT"/keyd_*~ubuntu24.04.*.dsc "$OUT"/keyd_*~ubuntu24.04.*.debian.tar.xz \
      "$OUT"/keyd-application-mapper_*~ubuntu24.04.*_all.deb
cp keyd_${V}_amd64.deb keyd_${V}.dsc keyd_${V}.debian.tar.xz \
   keyd_2.5.0.orig.tar.gz keyd-application-mapper_${V}_all.deb "$OUT"/
echo "keyd $V built into $OUT (upstream test suite ran: make test-io)"
