#!/bin/sh
# Build the world-keyboard-windows .deb (prototype) from world/xkb/symbols and world/packaging.
#   sh world/build-deb.sh OUTDIR          (needs dpkg-buildpackage and debhelper; run on Ubuntu 24.04 or a container)
# Environment: MAINTAINER, COPYRIGHT_HOLDER, SOURCE_URL as in packaging/build-all.sh.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd); OUT=$(mkdir -p "$1" && cd "$1" && pwd)
MAINTAINER=${MAINTAINER:-Younes <linuxbelgiumkeyboard.rc0g4@aleeas.com>}
COPYRIGHT_HOLDER=${COPYRIGHT_HOLDER:-Younes from Belgium}
SOURCE_URL=${SOURCE_URL:-https://github.com/belgian-azerty/belgian-azerty-linux}
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
V=$(sed -n '1s/.*(\(.*\)).*/\1/p' "$HERE/packaging/debian/changelog")
D=$T/world-keyboard-windows-$V; mkdir -p "$D/symbols"
cp -r "$HERE/packaging/debian" "$D/"; cp "$HERE/packaging/xkb-files" "$HERE/packaging/50world-keyboard-windows-xkb-move" "$D/"
cp "$HERE"/xkb/symbols/* "$D/symbols/"; cp "$HERE/xkb/rules/evdev.xml" "$HERE/xkb/accent-space.tsv" "$HERE/packaging/world-keyboard-windows" "$D/"
awk -F'\t' 'NR > 1 { print $4 "\t" $5 "\t" $2 "\t" $3 }' "$HERE/layouts.tsv" > "$D/fallback.tsv"
grep -rl '@MAINTAINER@\|@COPYRIGHT_HOLDER@\|@SOURCE_URL@' "$D/debian" | while read -r f; do
  sed -i "s|@MAINTAINER@|$MAINTAINER|g; s|@COPYRIGHT_HOLDER@|$COPYRIGHT_HOLDER|g; s|@SOURCE_URL@|$SOURCE_URL|g" "$f"
done
chmod 755 "$D/xkb-files" "$D/world-keyboard-windows" "$D/debian/rules"
(cd "$D" && SOURCE_DATE_EPOCH=$(date -d "$(dpkg-parsechangelog -S Date)" +%s) dpkg-buildpackage -b -us -uc >/dev/null)
cp "$T"/*.deb "$OUT/"; ls "$OUT"/*.deb
