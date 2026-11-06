#!/usr/bin/env python3
# Write the "(Windows)" layouts of the world prototype: for each row of a layout table (layouts.tsv), a new xkb section
# that includes the Linux layout unchanged and then redefines only the keys where Windows types something else
# (Unicode CLDR 43 Windows data). The Linux layout itself is never changed; the new layout has its own name
# (for example de_windows), so it sits next to the Linux one and next to the Belgian package.
#   python3 -I world/tools/gen_windows_symbols.py world/layouts.tsv world/cldr-43 OUT_SYMBOLS_DIR
# Writes OUT_SYMBOLS_DIR/<out_layout> (one file per layout name) and prints what it changed. A key whose Caps Lock
# behaviour cannot be expressed with the stock xkb key types is left as on Linux and reported.
import csv, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import winkb

SEMI, FOUR, PLUS = 'FOUR_LEVEL_SEMIALPHABETIC', 'FOUR_LEVEL', 'FOUR_LEVEL_PLUS_LOCK'
CELL = {'base': 0, 'shift': 1, 'altgr': 2, 'shiftaltgr': 3}

def has_case(symname):
    c = winkb.sym_char(winkb.L.xkb_keysym_from_name(symname.encode(), 0)) if symname != 'NoSymbol' else None
    return bool(c) and len(c) == 1 and c.lower() != c.upper()

def case_unknown_here(symname):
    """A letter (by Unicode) whose case this libxkbcommon does not know. Newer versions do (Georgian since libxkbcommon
    1.8 or so: Caps Lock then gives Mtavruli capitals), so such a key gets an explicit Caps Lock level when Windows says
    Caps Lock leaves it alone; otherwise the layout would change with the library."""
    if symname == 'NoSymbol' or not has_case(symname): return False
    ks = winkb.L.xkb_keysym_from_name(symname.encode(), 0)
    return winkb.L.xkb_keysym_to_upper(ks) == ks and winkb.L.xkb_keysym_to_lower(ks) == ks

def dead_ok(dsym, trans, dchar):
    """True when Linux's Compose table gives Windows's result for every 'accent then character' of this dead key."""
    ks = winkb.L.xkb_keysym_from_name(dsym.encode(), 0); bad = []
    for fr, to in trans.items():
        if len(fr) != 2 or fr[0] != dchar: continue
        got = winkb.compose_syms(ks, winkb.L.xkb_utf32_to_keysym(ord(fr[1])))
        if got != to: bad.append(f'{fr[1]}->{to} (Linux {got})')
    return bad

def plan_key(w, lin_levels, lin_typed, trans, win_rule=False):
    """w: Windows cells of one key; lin_levels: Linux keysym names per level; lin_typed: Linux char per state.
    -> (type, [syms], notes) or None when Linux already types every Windows cell."""
    diff = [st for st in winkb.STATES if w.get(st) and not w[st].startswith('str:') and w[st] != lin_typed[st]]
    if not diff and any(case_unknown_here(x) for x in lin_levels[:2]) and any(w.get(st) for st in ('caps', 'capsshift', 'base')):
        diff = ['caps']                                          # same today, but not with a newer libxkbcommon (above)
    if not diff: return None
    lv = list(lin_levels)                      # what Linux types now with Base, Shift, AltGr, Shift+AltGr
    syms = list(lv); notes = []; kept = set()
    for st, i in CELL.items():
        c = w.get(st)
        if c is None or c.startswith('str:'): continue          # Windows has nothing here: keep Linux's character
        s = winkb.char_to_sym(c)
        if s is None: notes.append(f'{st}: no keysym for {c!r}, kept Linux'); kept.add(st); continue
        if c.startswith('dead:') and s.startswith('dead_') and not (lin_typed[st] or '').startswith('dead:'):
            bad = dead_ok(s, trans, c[5:])
            if bad and win_rule:   # rule windows, step B: the accent key as on Windows; accent-space gives Windows's results
                notes.append(f'{st}: accent key {c[5:]} as on Windows; Linux accent table differs on {len(bad)} '
                             f'sequences (e.g. {", ".join(bad[:3])}): accent-space gives the Windows results')
                bad = []
            if bad:      # a new dead key whose Linux results differ from Windows would be worse than Linux's plain key
                notes.append(f'{st}: Windows accent key {c[5:]} not made, Linux Compose differs on {len(bad)} '
                             f'sequences (e.g. {", ".join(bad[:3])}); kept Linux {lin_typed[st]!r}')
                kept.add(st); kept.add('capsshift' if st == 'shift' else 'caps' if st == 'base' else st)
                continue
        syms[i] = s
    if set(diff) <= kept: return ('skip', notes)
    wb, ws, wc, wcs = (w.get(k) for k in ('base', 'shift', 'caps', 'capsshift'))
    if wc is None: wc, wcs = wb, ws                              # no Caps Lock table: Caps Lock changes nothing
    if (wc, wcs) == (ws, wb): typ = SEMI                         # Caps Lock acts like Shift (CAPLOK)
    elif (wc, wcs) == (wb, ws):                                  # Caps Lock does nothing on this key
        typ = PLUS if any(has_case(x) for x in syms) else FOUR   # a letter needs Lock consumed, or it is capitalised
        if typ == PLUS: syms.append(syms[0])
    elif wcs == ws and wc and not wc.startswith('str:') and winkb.char_to_sym(wc):
        typ = PLUS; syms.append(winkb.char_to_sym(wc))           # Caps Lock gives its own character
    else:
        typ = SEMI; notes.append(f'Caps Lock {wc!r}/{wcs!r} not expressible, Lock acts like Shift')
    return typ, syms, diff, notes

def main(table, cldrdir, outdir):
    ctx = winkb.context()
    rows = list(csv.DictReader(open(table, encoding='utf-8'), delimiter='\t'))
    files = {}
    for r in rows:
        win = winkb.read_cldr(os.path.join(cldrdir, r['cldr_file']))
        kb = winkb.Keymap(ctx, r['base_layout'], r['base_variant'])
        if not kb.ok(): sys.exit(f"cannot load Linux layout {r['base_layout']}({r['base_variant']})")
        lines = []; changed = 0
        # rule "windows" (Younes 5 Nov): Windows wins where the two differ; the Linux layout stays next to it unchanged.
        # Keys with more on level 5 and up are rewritten too, and Right Alt becomes AltGr when the Windows layout has
        # AltGr characters and the Linux layout has no AltGr (Russian, Kazakh, Thai...), as on Windows.
        win_rule = r.get('rule') == 'windows'
        has_altgr = any(ks.get('altgr') or ks.get('shiftaltgr') for ks in win[1].values())
        if win_rule and has_altgr and winkb.sym_name(kb.press_sym('base', 'RALT')) != 'ISO_Level3_Shift':
            kb = winkb.Keymap(ctx, r['base_layout'], r['base_variant'], 'lv3:ralt_switch')
            lines.append('    include "level3(ralt_switch)"   // Right Alt is AltGr, as on Windows')
        for key in sorted(win[1], key=lambda k: (k[:2] != 'TL', k)):
            if key not in ('TLDE', 'LSGT', 'BKSL') and not key[:2] in ('AE', 'AD', 'AC', 'AB'): continue
            w = win[1][key]
            typed = {st: kb.press(st, key) for st in winkb.STATES}
            now = [winkb.sym_name(kb.press_sym(st, key)) if kb.press_sym(st, key) else 'NoSymbol'
                   for st in ('base', 'shift', 'altgr', 'shiftaltgr')]
            p = plan_key(w, now, typed, win[2], win_rule)
            if p is None: continue
            extra = [x for x in kb.levels(key)[4:] if x != 'NoSymbol']
            if extra and p[0] != 'skip' and not set(extra) <= set(p[1]) and not win_rule:
                # Linux puts more on this key (levels 5 and up, e.g. Right Ctrl on Canadian Multilingual) than a
                # four-level key can hold: rewriting it would take those characters away, so it stays as on Linux
                print(f"  NOTE {r['out_layout']}({r['out_variant']}) {key}: Linux has {', '.join(extra)} on level 5 and up, "
                      f"key left as on Linux")
                continue
            if p[0] == 'skip':
                for n in p[1]: print(f"  NOTE {r['out_layout']}({r['out_variant']}) {key}: {n}")
                continue
            typ, syms, diff, notes = p; changed += 1
            why = '; '.join(f"{st}: Windows {w[st]} / Linux {typed[st]}" for st in diff if w.get(st) != typed[st]) or \
                  f"Caps Lock keeps {w.get('caps') or w.get('base')} as on Windows (made explicit: newer libxkbcommon would capitalise it)"
            lines.append(f'    // {why}' + (f'  [{"; ".join(notes)}]' if notes else ''))
            lines.append(f'    key <{key}> {{ type[Group1] = "{typ}", symbols[Group1] = [ {", ".join(syms)} ] }};')
            for n in notes: print(f"  NOTE {r['out_layout']}({r['out_variant']}) {key}: {n}")
        files.setdefault(r['out_layout'], []).append((r, win[0], changed, lines))
        print(f"{r['out_layout']}({r['out_variant']}): {changed} keys changed on top of {r['base_layout']}({r['base_variant'] or 'default'}), from \"{win[0]}\"")
    for lay, secs in files.items():   # the first section is the layout itself for desktops (no variant): keep it "basic"
        if secs[0][0]['out_variant'] != 'basic': sys.exit(f"{lay}: first row must have out_variant basic, not {secs[0][0]['out_variant']}")
    os.makedirs(outdir, exist_ok=True)
    for lay, secs in files.items():
        out = [f'// {lay}: keyboard layouts that type like Windows, generated by world/tools/gen_windows_symbols.py',
               '// from Unicode CLDR 43 Windows keyboard data. Do not edit by hand: change the generator and run it again.',
               '// Each section includes the Linux layout unchanged and redefines only the keys where Windows differs.',
               '// CLDR data: Copyright (c) Unicode, Inc., Unicode License (world/cldr-43/LICENSE.txt).',
               '// Part of the world prototype of belgian-azerty-linux; not released.']
        for i, (r, wname, changed, lines) in enumerate(secs):
            out += ['', ('default ' if i == 0 else '') + 'partial alphanumeric_keys',
                    f'xkb_symbols "{r["out_variant"]}" {{',
                    f'    include "{r["base_layout"]}' + (f'({r["base_variant"]})' if r["base_variant"] else '') + '"',
                    f'    name[Group1] = "{r["description"]}";',
                    f'    // Windows layout: "{wname}" (CLDR {r["cldr_file"]}); {changed} keys differ from Linux']
            out += lines + ['};']
        with open(os.path.join(outdir, lay), 'w', encoding='utf-8') as f: f.write('\n'.join(out) + '\n')
    write_registry(files, os.path.join(os.path.dirname(os.path.abspath(outdir)), 'rules', 'evdev.xml'))

def write_registry(files, path):
    """The list desktops read to show and accept layouts (libxkbregistry reads rules/evdev.xml in every keyboard folder,
    so this file only lists our layouts and xkb-data's own list stays untouched)."""
    from xml.sax.saxutils import escape as e
    x = ['<?xml version="1.0" encoding="UTF-8"?>', '<!DOCTYPE xkbConfigRegistry SYSTEM "xkb.dtd">',
         '<!-- world-keyboard-windows: generated by world/tools/gen_windows_symbols.py. Only our layouts; the system list stays as it is. -->',
         '<xkbConfigRegistry version="1.1">', '  <layoutList>']
    for lay, secs in files.items():
        def item(r, name, ind):
            cc = ''.join(f'<iso3166Id>{c}</iso3166Id>' for c in r['countries'].split(',') if c)
            ll = ''.join(f'<iso639Id>{c}</iso639Id>' for c in r['languages'].split(',') if c)
            return [f'{ind}<configItem>', f'{ind}  <name>{e(name)}</name>', f'{ind}  <shortDescription>{e(r["short"])}</shortDescription>',
                    f'{ind}  <description>{e(r["description"])}</description>',
                    # an empty list breaks the whole file for libxkbregistry (the DTD wants one id or more): leave it out
                    *([f'{ind}  <countryList>{cc}</countryList>'] if cc else []),
                    *([f'{ind}  <languageList>{ll}</languageList>'] if ll else []), f'{ind}</configItem>']
        first = secs[0][0]
        x += ['    <layout>'] + item(first, lay, '      ')
        if secs[1:]:
            x += ['      <variantList>']
            for r, *_ in secs[1:]:
                x += ['        <variant>'] + item(r, r['out_variant'], '          ') + ['        </variant>']
            x += ['      </variantList>']
        x += ['    </layout>']
    x += ['  </layoutList>', '</xkbConfigRegistry>']
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f: f.write('\n'.join(x) + '\n')

if __name__ == '__main__':
    main(*sys.argv[1:4])
