#!/usr/bin/env python3
"""Score typed lines: score.py FILE KIND [PAIRS]. KIND altgr/ctrlalt: expect '@€'*PAIRS; dead: 'êëéèñ^é'.
Prints: right / swapped (same characters, other order) / other, plus the odd lines."""
import sys
f, kind = sys.argv[1], sys.argv[2]; n = int(sys.argv[3]) if len(sys.argv) > 3 else 8
exp = "@€" * n if kind in ("altgr", "ctrlalt") else "êëéèñ^é"
right = swapped = other = 0; odd = []
for l in open(f, encoding="utf-8", errors="replace").read().splitlines():
    l = l.strip()
    if not l: continue
    if l == exp: right += 1
    elif sorted(l) == sorted(exp): swapped += 1; odd.append("swap  " + l)
    else: other += 1; odd.append("other " + l)
print(f"{f.split('/')[-1]} {kind}: {right} right, {swapped} swapped, {other} other, of {right + swapped + other}")
for o in odd[:8]: print("   ", o)
