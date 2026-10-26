set -e
K=/root/be-rig/k94; SP=/mnt/c/Users/<you>/AppData/Local/Temp/claude/C--Users-x-zorin-and-Mint-keyboard-driver-resolution/a09be6af-3262-42b7-ba53-eb0280916bff/scratchpad
E="/mnt/c/Users/<you>/zorin and Mint keyboard driver resolution/evidence/raw-logs/2026-10-25-keyd-patch"
mkdir -p "$E/mint/shots" "$E/zorin/shots" "$E/common/scripts/guest" "$E/common/scripts/host"
cd $K/uploads
for f in *; do
  case "$f" in ready-*|done-*|_selftest.txt) continue ;; esac
  case "$f" in *mint*) d=mint ;; *zorin*) d=zorin ;; *) echo "unsorted $f"; continue ;; esac
  cp "$f" "$E/$d/"
  case "$f" in *-check.txt|*-sys-*.txt|*-uninstall.txt|*-install.txt) sed 's/\x1b\[[0-9;]*m//g' "$f" > "$E/$d/${f%.txt}.clean.txt" ;; esac
done
cd $K/shots
for f in *.png; do case "$f" in m-*|mint*) cp "$f" "$E/mint/shots/" ;; z-*|zorin*) cp "$f" "$E/zorin/shots/" ;; esac; done
cp $K/logs/iso-sha256.txt $K/logs/mint-official-sha256sum.txt $K/logs/typed-commands.log $K/logs/runs.log $K/logs/serve-sha256.txt "$E/common/"
cp $K/kit94/README.txt "$E/common/kit94-README.txt"
cp $K/serve/*.sh $K/serve/seq.txt $K/serve/seq8.txt $K/serve/sums.txt "$E/common/scripts/guest/"
cp $K/hrun.sh $K/krun.sh $K/ty.sh $K/sh.sh $K/rig/kcheck.py $K/rig/held.py $K/rig/upload_server.py $SP/hs/*.sh "$E/common/scripts/host/"
(cd $K/kit94 && sha256sum dist/* dist-0.9.3/* be-azerty-fix.sh) > "$E/common/deb-sha256.txt"
sha256sum "/mnt/c/Users/<you>/zorin and Mint keyboard driver resolution/keyd-094-kit/kit94.tgz" | sed 's|/mnt/c/.*/keyd-094-kit/|keyd-094-kit/|' > "$E/common/kit-sha256.txt"
cd "$E"; find . -type f | wc -l; du -sh .
