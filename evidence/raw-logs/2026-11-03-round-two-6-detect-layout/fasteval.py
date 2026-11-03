# Fast walk of a pc105.tree for every layout in it (same step semantics as ubiquity/keyboard_detector.py).
# Models of what a person sees printed on the keys: strict = plain+Shift; full = plain+Shift+AltGr.
# Prints per layout: share of answer paths that end on the right layout.
import sys, re
from collections import Counter
from functools import lru_cache
from xkbcommon import xkb
tree, model = sys.argv[1], sys.argv[2]
steps = {}; cur = None
for l in open(tree, encoding='utf-8'):
    l = l.rstrip('\n')
    if l.startswith('STEP '): cur = int(l[5:]); steps[cur] = {'press': [], 'codes': {}, 'find': None, 'yes': None, 'no': None, 'map': None}
    elif l.startswith('PRESS '): steps[cur]['press'].append(l[6:].strip())
    elif l.startswith('CODE '): c, n = l[5:].split(); steps[cur]['codes'][int(c)] = int(n)
    elif l.startswith('FINDP ') or l.startswith('FIND '): steps[cur]['find'] = l.split(' ', 1)[1].strip()
    elif l.startswith('YES '): steps[cur]['yes'] = int(l[4:])
    elif l.startswith('NO '): steps[cur]['no'] = int(l[3:])
    elif l.startswith('MAP '): steps[cur]['map'] = l[4:].strip()
ctx = xkb.Context()
def labels_for(layout, variant):
    km = ctx.keymap_new_from_names(layout=layout, variant=variant); lab = {}
    lv = (0, 1) if model == 'strict' else (0, 1, 2)
    for kc in range(9, 120):
        for lvl in lv:
            for s in km.key_get_syms_by_level(kc, 0, lvl):
                ch = xkb.keysym_to_string(s)
                if ch and len(ch) == 1 and ch.isprintable(): lab.setdefault(ch, set()).add(kc - 8)
    return lab
def evaluate(lab):
    @lru_cache(None)
    def out(st):
        s = steps[st]
        if s['map']: return Counter({s['map']: 1})
        if s['find']:
            have = s['find'] in lab
            return out(s['yes'] if have else s['no'])
        r = Counter()
        for sym in s['press']:
            for code in sorted(lab.get(sym, ())):
                if code in s['codes']: r += out(s['codes'][code])
                else: r['WAITS'] += 1
        if not r: r['STUCK'] += 1
        return r
    return out(0)
names = sorted({s['map'] for s in steps.values() if s['map']})
for name in names:
    l, _, v = name.partition(':')
    r = evaluate(labels_for(l, v)); tot = sum(r.values())
    print(f"{name}\t{r.get(name,0)}/{tot}\t{dict(r)}")
