#!/usr/bin/env python3
# Machine check of the world prototype: for every row of the layout table, type every Windows cell (key x 6 states)
# and every accent sequence on
#   (1) the stock Linux layout,
#   (2) the new "(Windows)" layout as libxkbcommon builds it (Wayland desktops: GNOME, KDE),
#   (3) the new layout as xkbcomp builds it (the X11 server: Cinnamon, Xfce, MATE), read back into libxkbcommon,
# and compare with Windows (Unicode CLDR 43). Also checks that every character Linux has where Windows has nothing
# is still there (nothing taken away), and that the Linux layout itself is unchanged. Rows with rule "windows" follow
# Windows where the two differ: those cells are listed as "only on the Linux layout", not counted as lost.
#   python3 -I world/tools/check_windows_symbols.py world/layouts.tsv world/cldr-43 world/xkb [results.json]
# Exit code 1 when a new layout types something Windows does not on a key, or loses a Linux character.
import csv, json, os, subprocess, sys, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import winkb

def xkbcomp_keymap(xkbdir, layout, variant):
    """Compile with xkbcomp (as the X server does) and load its output into libxkbcommon."""
    src = ('xkb_keymap {\n  xkb_keycodes { include "evdev+aliases(qwerty)" };\n  xkb_types { include "complete" };\n'
           '  xkb_compat { include "complete" };\n'
           f'  xkb_symbols {{ include "pc+{layout}({variant})+inet(evdev)" }};\n'
           '  xkb_geometry { include "pc(pc105)" };\n};\n')
    with tempfile.TemporaryDirectory() as t:
        open(os.path.join(t, 'in.xkb'), 'w').write(src)
        r = subprocess.run(['xkbcomp', '-w', '0', f'-I{xkbdir}', '-I/usr/share/X11/xkb', '-xkb',
                            os.path.join(t, 'in.xkb'), os.path.join(t, 'out.xkb')], capture_output=True, text=True)
        if r.returncode: return None, r.stderr.strip()
        text = open(os.path.join(t, 'out.xkb'), 'rb').read()
    km = winkb.Keymap.__new__(winkb.Keymap)
    km.ctx = winkb.context(); km.comp = winkb.L.xkb_compose_table_new_from_locale(km.ctx, b"en_US.UTF-8", 0)
    km.km = winkb.L.xkb_keymap_new_from_string(km.ctx, text, 1, 0)
    return km, ''

def summary(cells, diffs):
    k = [d for d in diffs if d['kind'] == 'key']; a = [d for d in diffs if d['kind'] != 'key']
    return {'cells': cells, 'same_as_windows': cells - len(diffs), 'key_diffs': len(k), 'accent_diffs': len(a)}

def main(table, cldrdir, xkbdir, out=None):
    rows = list(csv.DictReader(open(table, encoding='utf-8'), delimiter='\t'))
    stock = winkb.context(); ours = winkb.context(xkbdir)
    report = []; fail = False
    for r in rows:
        win = winkb.read_cldr(os.path.join(cldrdir, r['cldr_file']))
        base = winkb.Keymap(stock, r['base_layout'], r['base_variant'])
        new = winkb.Keymap(ours, r['out_layout'], r['out_variant'])
        x11, err = xkbcomp_keymap(xkbdir, r['out_layout'], r['out_variant'])
        res = {'layout': f"{r['out_layout']}({r['out_variant']})", 'windows': win[0], 'linux': f"{r['base_layout']}({r['base_variant']})"}
        if not new.ok() or x11 is None or not x11.ok():
            res['error'] = 'does not compile: ' + (err or 'libxkbcommon'); report.append(res); fail = True; continue
        for tag, kb in (('stock_linux', base), ('new_wayland', new), ('new_x11', x11)):
            cells, diffs = winkb.compare(win, kb)
            res[tag] = summary(cells, diffs)
            if tag != 'stock_linux': res[tag + '_left'] = [f"{d['key']} {d['state']}" + (f" then {d['then']!r}" if d['kind'] == 'accent' else '')
                                                           + f": Windows {d['windows']} / here {d['linux']}" for d in diffs]
        # nothing taken away: where Windows has no character, the new layout types what Linux types
        lost = []; keys = win[1]
        for key in sorted(set(keys) | {'TLDE', 'LSGT', 'BKSL'}):
            if key == 'SPCE': continue
            for st in winkb.STATES:
                w = keys.get(key, {}).get(st)
                if w and not w.startswith('str:'): continue
                for tag, kb in (('wayland', new), ('x11', x11)):
                    a, b = base.press(st, key), kb.press(st, key)
                    if a != b: lost.append(f'{tag} {key} {st}: Linux {a} / new {b}')
        # keys with more than four levels on Linux (Right Ctrl level 5 and up): those characters stay on the key
        for key in sorted(set(keys) | {'TLDE', 'LSGT', 'BKSL'}):
            if key == 'SPCE' or not base.code(key): continue
            extra = {x for x in base.levels(key)[4:] if x != 'NoSymbol'}
            for tag, kb in (('wayland', new), ('x11', x11)):
                gone = extra - set(kb.levels(key))
                if gone: lost.append(f'{tag} {key} level 5+: Linux {", ".join(sorted(gone))} gone')
        if r.get('rule') == 'windows':
            # rule "windows": where Windows puts something else, the new layout follows Windows; what Linux had there
            # is still on the Linux layout, which stays next to it. Reported, not an error.
            res['only_on_the_linux_layout'] = lost; lost = []
        res['linux_characters_lost'] = lost
        # X11 and Wayland must agree on every cell
        res['x11_equals_wayland'] = res['new_wayland_left'] == res['new_x11_left']
        if res['new_wayland']['key_diffs'] or res['new_x11']['key_diffs'] or lost or not res['x11_equals_wayland']: fail = True
        report.append(res)
        s, n = res['stock_linux'], res['new_wayland']
        print(f"{res['layout']:<22} Windows \"{win[0]}\": stock Linux {s['same_as_windows']}/{s['cells']} -> new "
              f"{n['same_as_windows']}/{n['cells']} (X11 {res['new_x11']['same_as_windows']}), keys left {n['key_diffs']}, "
              f"accents left {n['accent_diffs']}, Linux characters lost {len(lost)}, X11=Wayland {res['x11_equals_wayland']}"
              + (f", only on the Linux layout {len(res['only_on_the_linux_layout'])}" if 'only_on_the_linux_layout' in res else ''))
        for x in res['new_wayland_left']: print('    left:', x)
        for x in lost: print('    LOST:', x)
        for x in res.get('only_on_the_linux_layout', []): print('    only on the Linux layout:', x)
    if out: json.dump(report, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    sys.exit(1 if fail else 0)

if __name__ == '__main__':
    main(*sys.argv[1:5])
