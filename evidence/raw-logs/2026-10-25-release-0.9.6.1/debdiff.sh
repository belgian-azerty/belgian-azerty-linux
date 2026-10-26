#!/bin/bash
# debdiff.sh OLD.deb NEW.deb: every file in data + control, sha256 old vs new, SAME / DIFF / ONLY-OLD / ONLY-NEW
set -euo pipefail
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
for s in old new; do d=$1; [ $s = new ] && d=$2
  mkdir -p $W/$s/data $W/$s/ctl; dpkg-deb -x "$d" $W/$s/data; dpkg-deb -e "$d" $W/$s/ctl
  (cd $W/$s && find data ctl -type f -o -type l | sort | while read -r f; do
     if [ -L "$f" ]; then echo "link:$(readlink "$f")  $f"; else echo "$(sha256sum < "$f" | cut -c1-64)  $f"; fi; done) > $W/$s.lst
done
join -j2 -a1 -a2 -e MISSING -o 0,1.1,2.1 <(awk '{print $1, $2}' $W/old.lst | sort -k2) <(awk '{print $1, $2}' $W/new.lst | sort -k2) | \
while read -r f o n; do
  if [ "$o" = MISSING ]; then st=ONLY-NEW; elif [ "$n" = MISSING ]; then st=ONLY-OLD; elif [ "$o" = "$n" ]; then st=SAME; else st=DIFF; fi
  printf '%-8s %s  old %s  new %s\n' $st "$f" "${o:0:16}" "${n:0:16}"
done
# dpkg-deb -c listing (modes, owners) compared too, without dates
diff <(dpkg-deb -c "$1" | awk '{print $1,$2,$6}') <(dpkg-deb -c "$2" | awk '{print $1,$2,$6}') > /dev/null && echo "modes/owners/paths: SAME" || echo "modes/owners/paths: DIFFERENT"
