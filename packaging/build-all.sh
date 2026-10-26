#!/bin/bash
# Build every package of the Belgian AZERTY fix into dist/ (binary .deb + source package for each), then run lintian.
#   packaging/build-all.sh [--no-keyd]
# Environment: MAINTAINER="Name <email>", COPYRIGHT_HOLDER="Name", SOURCE_URL=... (maintainer and holder decided by
# Younes on 2026-10-24: MIT licence, e-mail below; Maintainer "Younes" and holder "Younes from Belgium" from 2026-10-25
# 19:26Z and 20:02Z; SOURCE_URL stays a placeholder until the project is published). Needs: build-essential debhelper devscripts lintian (+ dh-python python3 scdoc curl for keyd).
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DIST=$ROOT/dist
MAINTAINER=${MAINTAINER:-Younes <linuxbelgiumkeyboard.rc0g4@aleeas.com>}
COPYRIGHT_HOLDER=${COPYRIGHT_HOLDER:-Younes from Belgium}
SOURCE_URL=${SOURCE_URL:-not published yet}
mkdir -p "$DIST"
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT

V=0.9.7         # version of our two packages (keep equal to their debian/changelog)
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
[ "${1:-}" = --no-keyd ] || bash "$ROOT/packaging/keyd-backport/build.sh" "$DIST"
echo "lintian:"
(cd "$DIST" && lintian --tag-display-limit 0 ./*.deb 2>&1 | sed 's/^/  /') || true
(cd "$DIST" && sha256sum ./*.deb ./*.dsc ./*.tar.* > SHA256SUMS)
echo "packages and SHA256SUMS in $DIST"
# The T14s test folder carries its own copy of the three packages and the script (T14S-TEST-PLAN.md, run-test.sh).
T=$ROOT/t14s-test
rm -f "$T"/*.deb
cp "$DIST"/keyd_*_amd64.deb "$DIST"/keyd-belgian-windows_*_all.deb "$DIST"/belgian-azerty-windows_*_all.deb "$T/"
cp "$ROOT/be-azerty-fix.sh" "$T/"
(cd "$T" && sha256sum ./*.deb be-azerty-fix.sh run-test.sh README.txt > SHA256SUMS)
echo "t14s-test/ refreshed"
