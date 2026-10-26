#!/usr/bin/env python3
"""charcount.py FILE: extra score for the VS Code runs when Enters went missing (lines merged).
Expected: 70 burst lines of '@€'x8 (560 @ and 560 €), then 3 dead-key lines 'êëéèñ^é'."""
import sys
DEAD = "êëéèñ^é"
t = open(sys.argv[1], encoding="utf-8", errors="replace").read()
lines = [l for l in t.splitlines() if l.strip()]
burst = "".join(lines).replace(DEAD, "")
other = sorted(set(burst) - set("@€"))
print(f"  lines {len(lines)} (expected 73); line lengths: {[len(l) for l in lines]}")
print(f"  burst text ({len(burst)} chars, expected 1120): @ {burst.count('@')}/560, € {burst.count('€')}/560, "
      f"'@€' pairs {burst.count('@€')}, '€€' {burst.count('€€')}, '@@' {burst.count('@@')}, other chars {other}")
print(f"  dead-key strings found: {t.count(DEAD)}/3")
