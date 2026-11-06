#!/usr/bin/env python3
# Accent then Space for the world prototype: for every layout of the table, every accent key of the new layout and
# what Windows types for "accent then Space" (Unicode CLDR 43), next to what Linux's own accent table (Compose,
# en_US.UTF-8) types. world-keyboard-windows accent-space reads this table and writes a per-user ~/.XCompose with the
# lines where Windows differs, for the layouts that user has.
#   python3 -I world/tools/gen_accent_space.py world/layouts.tsv world/cldr-43 world/xkb OUT.tsv [world/stock-accent.tsv]
# stock-accent.tsv: Linux's own layouts that already type like Windows except accent then Space (checked here: the
# run stops if any key differs); they get accent-space lines too, without a new layout.
# Since 5 Nov (step B) every accent sequence, not only accent then Space. Columns: id (as desktops name it: layout, or
# layout+variant), sequence (keysym, keysym), windows, linux, line (the Compose line that makes Windows's result; only
# rows where windows and linux differ are listed), kind (dead or shared, see table())
import csv, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import winkb

def entries(tab, xkbdir, stock=None):
    """(cldr_file, keymap, desktop id) for our layouts and for the Linux layouts of stock-accent.tsv"""
    ctx = winkb.context(xkbdir)
    for r in csv.DictReader(open(tab, encoding='utf-8'), delimiter='\t'):
        lid = r['out_layout'] if r['out_variant'] == 'basic' else f"{r['out_layout']}+{r['out_variant']}"
        yield r['cldr_file'], winkb.Keymap(ctx, r['out_layout'], r['out_variant']), lid, False
    if stock:
        sctx = winkb.context()
        for r in csv.DictReader(open(stock, encoding='utf-8'), delimiter='\t'):
            yield r['cldr_file'], winkb.Keymap(sctx, r['layout'], r['variant']), r['layout'] + (f"+{r['variant']}" if r['variant'] else ''), True

def _esc(t): return t.replace('\\', '\\\\').replace('"', '\\"')

def table(tab, cldrdir, xkbdir, stock=None):
    """Rows (id, sequence, windows, linux, line, kind). kind: dead (an accent key of the layout: the line where Windows
    gives something else than Linux's accent table), shared (sequence "K *", windows = an accent: on Windows this cell
    is another accent than the one keysym K stands for on this layout, for example Greek ΄ and ΅ are both dead_acute;
    one keysym can give only one set of results, so that cell keeps Linux's results; the checker lists it).
    Plain keys are not made accent keys: GNOME's text input (GTK, Mutter) starts an accent sequence only on a real
    accent key, so lines for a plain key do nothing there (GNOME typing test, 5 Nov 2026)."""
    out = []
    for cf, kb, lid, is_stock in entries(tab, xkbdir, stock):
        name, keys, trans = winkb.read_cldr(os.path.join(cldrdir, cf))
        if not kb.ok(): sys.exit(f"cannot load {lid}")
        if is_stock:
            bad = [d for d in winkb.compare((name, keys, trans), kb)[1] if d['kind'] != 'accent' or d['then'] != ' ']
            if bad: sys.exit(f'{lid}: Linux layout differs from Windows "{name}" on more than accent then Space ({len(bad)})')
        where = {}
        for k, ks in keys.items():
            for st in ('base', 'shift'):
                c = ks.get(st)
                if c and len(c) == 1: where.setdefault(c, (st, k))
        where[' '] = ('base', 'SPCE')
        cells = {}                                   # Linux accent keysym -> [(Windows accent, native, order)]
        for i, (k, ks) in enumerate(sorted(keys.items())):
            for j, st in enumerate(winkb.STATES):
                w = ks.get(st) or ''
                if not w.startswith('dead:'): continue
                if st in ('caps', 'capsshift') and ks.get('base' if st == 'caps' else 'shift') == w: continue
                sym = kb.press_sym(st, k)
                if not (winkb.sym_char(sym) or '').startswith('dead:'): continue   # a plain key: not an accent key here
                n = winkb.sym_name(sym)
                cells.setdefault(n, []).append((w[5:], winkb.char_to_sym(w) != n, (j, i), sym))
        for n, cs in sorted(cells.items()):
            d, _, _, sym = min(cs, key=lambda x: (x[1], x[2]))  # the accent this keysym gives: Windows's own, else the first
            for c2 in sorted({x[0] for x in cs} - {d}): out.append((lid, f'{n} *', c2, '', '', 'shared'))
            for c, (st2, k2) in sorted(where.items()):
                to = trans.get(d + c)
                if to is None: continue                  # unmatched after an accent key: as on Linux
                s2 = winkb.sym_name(kb.press_sym(st2, k2)) if c != ' ' else 'space'
                if s2 == 'NoSymbol': continue
                lin = winkb.compose_syms(sym, winkb.L.xkb_keysym_from_name(s2.encode(), 0)) or ''
                one = winkb.char_to_sym(to) if len(to) == 1 else None
                out.append((lid, f'{n} {s2}', to, lin, f'<{n}> <{s2}> : "{_esc(to)}"' + (f' {one}' if one else ''), 'dead'))
    # a sequence where Windows equals Linux stays listed when another layout differs on it: a user with both layouts
    # then keeps Linux's result (the command leaves a sequence alone when the user's layouts disagree)
    needed = {x[1] for x in out if x[5] == 'dead' and x[2] != x[3]}
    return [x for x in out if x[5] == 'shared' or x[2] != x[3] or x[1] in needed]

if __name__ == '__main__':
    tab, cldr, xkb, dest = sys.argv[1:5]
    t = table(tab, cldr, xkb, sys.argv[5] if len(sys.argv) > 5 else None)
    with open(dest, 'w', encoding='utf-8') as f:
        f.write('# world-keyboard-windows: accent then Space, Windows (CLDR 43) and Linux (Compose en_US.UTF-8). '
                'Generated by world/tools/gen_accent_space.py; do not edit by hand.\n')
        f.write('id\tsequence\twindows\tlinux\tline\tkind\n')
        for row in t: f.write('\t'.join(row) + '\n')
    diff = [x for x in t if x[5] == 'dead' and x[2] != x[3]]
    print(f'{len(t)} rows over {len({x[0] for x in t})} layouts; Windows differs from Linux on {len(diff)} sequences, '
          f'{len([x for x in t if x[5] == "shared"])} cells share an accent key:',
          ', '.join(sorted({f"{x[1]} -> {x[2]}" for x in diff if x[1].endswith(' space')})))
