#!/bin/bash
# Host side: start a systemd container with headless GNOME Shell 46 (image with gnome-shell, see RESULTS.md), install
# the world package, and type every plan cell of every layout in world/layouts.tsv. Needs docker; run from the repository root:
#   world/tests/gnome-typing.sh IMAGE WORLD_DEB OUTDIR [ONLY]     (ONLY: regex on "layout(variant)", default all)
set -u; ONLY=${4:-.}; IMG=$1; DEB=$(realpath "$2"); OUT=$(mkdir -p "$3" && realpath "$3"); REPO=$(pwd); N=world-typing
docker rm -f $N >/dev/null 2>&1
docker run -d --name $N --privileged --tmpfs /run --tmpfs /run/lock --tmpfs /tmp -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  -v "$REPO":/src:ro -v "$DEB":/tmp-deb/world.deb:ro -v "$OUT":/out "$IMG" /sbin/init >/dev/null
until s=$(docker exec $N systemctl is-system-running 2>/dev/null); [ "$s" = running ] || [ "$s" = degraded ]; do sleep 1; done
docker exec $N sh -c 'DEBIAN_FRONTEND=noninteractive apt-get install -y -qq /tmp-deb/world.deb >/dev/null 2>&1; dpkg-query -W world-keyboard-windows; useradd -m tester; chmod 777 /out'
FAIL=0
# tabs to \037 first: with IFS=tab, read would merge an empty column (no Linux variant) with the next one
tail -n +2 world/layouts.tsv | tr '\t' '\037' | while IFS=$'\037' read -r cldr bl bv ol ov desc rest; do
  echo "$ol($ov)" | grep -Eq "$ONLY" || continue
  id=$ol; [ "$ov" = basic ] || id="$ol+$ov"
  docker exec -u tester $N python3 -I /src/world/tools/gen_typing_plan.py /src/world/cldr-43/$cldr $ol $ov /out/plan-$ol-$ov.json < /dev/null
  docker exec -u tester $N bash /src/world/tests/run-gnome.sh "$id" /out/plan-$ol-$ov.json /out/typed-$ol-$ov.txt 0.02 < /dev/null
  python3 -I world/tools/compare_typed.py "$OUT/plan-$ol-$ov.json" "$OUT/typed-$ol-$ov.txt" | tee "$OUT/compare-$ol-$ov.txt"
done
docker rm -f $N >/dev/null
