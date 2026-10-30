#!/bin/bash
# Build both packages of the Belgian AZERTY fix into dist/ (binary .deb + source package for each), then run lintian.
#   packaging/build-all.sh
# keyd itself is not built here: it comes from the keyd-team PPA (Ubuntu 24.04) or the distribution (Ubuntu 25.04+).
# Environment: MAINTAINER="Name <email>", COPYRIGHT_HOLDER="Name", SOURCE_URL=...
# Needs: build-essential debhelper devscripts lintian.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DIST=$ROOT/dist
MAINTAINER=${MAINTAINER:-Younes <linuxbelgiumkeyboard.rc0g4@aleeas.com>}
COPYRIGHT_HOLDER=${COPYRIGHT_HOLDER:-Younes from Belgium}
SOURCE_URL=${SOURCE_URL:-https://github.com/belgian-azerty/belgian-azerty-linux}
mkdir -p "$DIST"
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT

V=0.9.9         # version of our two packages (keep equal to their debian/changelog)
stage() {   # NAME: copy packaging/NAME plus its files from the project tree into $W/NAME-$V, fill placeholders
  local n=$1 d="$W/$1-$V"
  cp -r "$ROOT/packaging/$n" "$d"
  case "$n" in
    keyd-belgian-windows) cp "$ROOT/keyd/be-winaltgr.conf" "$d/" ;;
    belgian-azerty-windows) cp "$ROOT/xkb/symbols/be_capslock" "$d/"
                            cp "$ROOT/be-azerty-fix.sh" "$d/be-azerty-fix"; chmod 755 "$d/be-azerty-fix"
                            cp "$ROOT/README.md" "$d/README.md" ;;
  esac
  grep -rl '@MAINTAINER@\|@COPYRIGHT_HOLDER@\|@SOURCE_URL@' "$d/debian" | while read -r f; do
    sed -i "s|@MAINTAINER@|$MAINTAINER|g; s|@COPYRIGHT_HOLDER@|$COPYRIGHT_HOLDER|g; s|@SOURCE_URL@|$SOURCE_URL|g" "$f"
  done
  (cd "$d" && dpkg-buildpackage -us -uc > "$W/$n.log" 2>&1) || { tail -30 "$W/$n.log"; exit 1; }
  rm -f "$DIST/${n}"_*_all.deb "$DIST/${n}"_*.dsc "$DIST/${n}"_*.tar.xz
  cp "$W/${n}_${V}_all.deb" "$W/${n}_${V}.dsc" "$W/${n}_${V}.tar.xz" "$DIST/"
  echo "built $n $V"
}
stage keyd-belgian-windows
stage belgian-azerty-windows
echo "lintian:"
(cd "$DIST" && lintian --tag-display-limit 0 ./*.deb 2>&1 | sed 's/^/  /') || true
(cd "$DIST" && sha256sum ./*.deb ./*.dsc ./*.tar.* > SHA256SUMS)
echo "packages and SHA256SUMS in $DIST"
