#!/usr/bin/env python3
# Compare what the desktop typed (one line per plan cell) with the plan's two expectations: the data step's
# prediction and Windows.   python3 -I world/tools/compare_typed.py PLAN.json TYPED.txt
import json, sys
plan = json.load(open(sys.argv[1])); typed = open(sys.argv[2]).read().split('\n')
cells = plan['cells']; n = len(cells); pred = win = wn = 0; bad = []; wbad = []
for i, c in enumerate(cells):
    t = typed[i] if i < len(typed) else None
    t = t if t != '' else None
    if t == c['lin']: pred += 1
    else: bad.append((c['what'], c['lin'], t))
    if c['win'] is not None:
        wn += 1
        if t == c['win']: win += 1
        else: wbad.append((c['what'], c['win'], t))
print(f"{plan['windows']} on {plan['linux']}: {n} cells; desktop = prediction {pred}/{n}; desktop = Windows {win}/{wn}")
for b in bad[:20]: print('  NOT AS PREDICTED', b)
for b in wbad: print('  differs from Windows', b)
sys.exit(0 if pred == n else 1)
