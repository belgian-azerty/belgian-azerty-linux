#!/usr/bin/env python3
"""blockscore.py FILE SPEC: score a typed file block by block. SPEC = "100:altgr-o30,100:ctrlalt-o30,3:dead".
If the file is shorter than SPEC (lines lost while a window opened), the missing lines are counted from the start."""
import sys
lines = [l.strip() for l in open(sys.argv[1], encoding="utf-8", errors="replace").read().splitlines() if l.strip()]
spec = [(int(n), k) for n, k in (s.split(":") for s in sys.argv[2].split(","))]
total = sum(n for n, _ in spec); lost = total - len(lines)
i = -lost
for n, k in spec:
    blk = lines[max(i, 0):i + n]; i += n
    exp = "êëéèñ^é" if k == "dead" else "@€" * 8
    r = sum(1 for l in blk if l == exp); s = sum(1 for l in blk if l != exp and sorted(l) == sorted(exp))
    print(f"  {k:12s} {r:3d} right, {s:3d} swapped, {len(blk)-r-s:3d} other, of {len(blk)}" + (f"  (expected {n})" if len(blk) != n else ""))
