#!/usr/bin/env python3
# Machine check of accent-space: for every layout of the table, the ~/.XCompose that "world-keyboard-windows
# accent-space on" writes for a user with only that layout (from accent-space.tsv, same rule as the command), loaded
# the way GTK and libxkbcommon load it (include "%L" = Linux's normal table). Then every Windows cell and accent
# sequence is typed again (as in check_windows_symbols.py) and compared with the result without the file.
#   python3 -I world/tools/check_accent_space.py world/layouts.tsv world/cldr-43 world/xkb [FILE_FROM_COMMAND...]
# The Linux layouts of world/stock-accent.tsv (next to layouts.tsv) are checked too.
# With FILE_FROM_COMMAND (files the real command wrote, named <id>.XCompose), those files are checked instead.
# Exit 1 when the file makes any result worse, or an accent + Space result is still not like Windows.
import csv, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import winkb

def lines_for(ids, tab):
    want = {}; clash = set()
    for r in tab:
        if r['id'] not in ids: continue
        k = r['keysym']
        if k in want and want[k][0] != r['windows']: clash.add(k)
        want.setdefault(k, (r['windows'], r['linux'], r['line']))
    return sorted(line for k, (w, lin, line) in want.items() if k not in clash and w != lin)

def main(table, cldrdir, xkbdir, *given):
    tab = list(csv.DictReader((l for l in open(os.path.join(xkbdir, 'accent-space.tsv'), encoding='utf-8')
                               if not l.startswith('#')), delimiter='\t', quoting=csv.QUOTE_NONE))
    files = {os.path.basename(g)[:-len('.XCompose')]: open(g, encoding='utf-8').read() for g in given}
    fail = False; total = [0, 0, 0]
    from gen_accent_space import entries
    stock = os.path.join(os.path.dirname(os.path.abspath(table)), 'stock-accent.tsv')
    for cf, kb, lid, is_stock in entries(table, xkbdir, stock if os.path.exists(stock) else None):
        lines = lines_for({lid}, tab)
        text = files.get(lid) if files else 'include "%L"\n' + ''.join(l + '\n' for l in lines)
        if text is None: continue
        win = winkb.read_cldr(os.path.join(cldrdir, cf))
        cells, before = winkb.compare(win, kb)
        kb.comp = winkb.compose_table_from_text(text)
        _, after = winkb.compare(win, kb)
        key = lambda d: (d['kind'], d['key'], d['state'], d.get('then'))
        b = {key(d): d for d in before}; a = {key(d): d for d in after}
        worse = [d for k, d in a.items() if k not in b or b[k]['linux'] != d['linux']]
        # accent + Space on keys where Linux has an accent key (the Polish ~, a plain key on purpose, is not one)
        space_left = [d for d in after if d.get('then') == ' ' and d['linux'] is not None]
        fixed = len([k for k in b if k not in a])
        total[0] += cells; total[1] += cells - len(before); total[2] += cells - len(after)
        print(f"{lid:<16} {len(lines)} line(s); like Windows {cells - len(before)}/{cells} -> {cells - len(after)}/{cells} "
              f"(fixed {fixed}), accent + Space left {len(space_left)}, worse {len(worse)}")
        for d in space_left + worse:
            print(f"    {'WORSE' if d in worse else 'left'}: {d['key']} {d['state']} then {d.get('then')!r}: Windows {d['windows']} / here {d['linux']}")
        if worse or space_left: fail = True
    print(f"all: like Windows {total[1]}/{total[0]} without the file, {total[2]}/{total[0]} with it")
    # a user with every layout at once: keys where the layouts disagree stay as on Linux
    print('every layout at once:', lines_for({r['id'] for r in tab}, tab) or 'no line')
    sys.exit(1 if fail else 0)

if __name__ == '__main__':
    main(*sys.argv[1:])
