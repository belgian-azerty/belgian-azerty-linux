#!/usr/bin/env python3
# Typing plan for the headless-desktop check: every Windows cell (key x 6 states) and accent sequence of one layout,
# with what Windows types (CLDR 43) and what the data step predicts the desktop types with the given xkb layout.
#   python3 -I world/tools/gen_typing_plan.py CLDR_FILE LAYOUT VARIANT OUT.json [XKB_DIR [ACCENT_SPACE_TSV]]
# With ACCENT_SPACE_TSV: predict with the ~/.XCompose that "world-keyboard-windows accent-space on" writes for a user
# with only this layout.
# Presses are [evdev keycode, [held modifiers], caps lock tapped before and after (0/1)], as world/tests/typeall.py
# expects. GTK shows an accent followed by the letter when no Compose rule exists (as in the 28 Oct method).
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import winkb
path, lay, var, out = sys.argv[1:5]; xkbdir = sys.argv[5] if len(sys.argv) > 5 and sys.argv[5] else None
accent = sys.argv[6] if len(sys.argv) > 6 else None
win = winkb.read_cldr(path); name, keys, trans = win
kb = winkb.Keymap(winkb.context(xkbdir), lay, var)
assert kb.ok(), f'cannot load {lay}({var})'
if accent:
    import csv
    from check_accent_space import lines_for
    tab = list(csv.DictReader((l for l in open(accent, encoding='utf-8') if not l.startswith('#')), delimiter='\t', quoting=csv.QUOTE_NONE))
    lines = lines_for({lay if var in ('basic', '') else f'{lay}+{var}'}, tab)
    kb.comp = winkb.compose_table_from_text('include "%L"\n' + ''.join(l + '\n' for l in lines))
    print('accent-space lines:', lines)
MODS = {'base': ([], 0), 'shift': ([42], 0), 'caps': ([], 1), 'capsshift': ([42], 1), 'altgr': ([100], 0), 'shiftaltgr': ([100, 42], 0)}
SPACING = {'ˇ': 'ˇ', '´': '´', '`': '`', '^': '^', '~': '~', '¨': '¨', '˘': '˘', '˙': '˙'}
where = {}
for k, ks in keys.items():
    for st in ('base', 'shift'):
        c = ks.get(st)
        if c and len(c) == 1: where.setdefault(c, (st, k))
where[' '] = ('base', 'SPCE')
ev = lambda k: kb.code(k) - 8
cells = []
for k, ks in sorted(keys.items()):
    if k == 'SPCE': continue
    for st in winkb.STATES:
        w = ks.get(st); x = kb.press(st, k); sym = kb.press_sym(st, k)
        if w and w.startswith('str:'): continue
        if (w or '').startswith('dead:'):
            if st in ('caps', 'capsshift') and ks.get('base' if st == 'caps' else 'shift') == w: continue
            for fr, to in sorted(trans.items()):
                if len(fr) != 2 or fr[0] != w[5:] or fr[1] not in where: continue
                st2, k2 = where[fr[1]]
                if (x or '').startswith('dead:'):
                    got = kb.compose(sym, st2, k2)
                    if got is None: got = SPACING.get(x[5:], x[5:]) + (kb.press(st2, k2) or '')
                else: got = (x or '') + (kb.press(st2, k2) or '')
                cells.append({'what': f'{k} {st} then {fr[1]!r}', 'presses': [[ev(k), *MODS[st]], [ev(k2), *MODS[st2]]], 'win': to, 'lin': got})
            continue
        if w is None and x is None: continue
        if (x or '').startswith('dead:'): continue      # Linux dead key where Windows has a character: not typed alone
        cells.append({'what': f'{k} {st}', 'presses': [[ev(k), *MODS[st]]], 'win': w, 'lin': x})
json.dump({'windows': name, 'linux': f'{lay}({var})', 'cells': cells}, open(out, 'w'), ensure_ascii=False)
print(name, f'{lay}({var})', 'cells', len(cells), 'win!=predicted', sum(c['win'] != c['lin'] for c in cells if c['win'] is not None))
