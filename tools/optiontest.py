#!/usr/bin/env python3
"""Which keys and levels do our XKB options change? Prints every difference between two keymaps, as
"KEY LEVEL: before -> after". Levels: base, shift, altgr, shift+altgr. Usage:
  optiontest.py [--include DIR] LAYOUT[:VARIANT] OPTIONS [LAYOUT[:VARIANT] OPTIONS]
The second keymap defaults to the same layout with no options."""
import sys
from xkbcommon import xkb
SH, ALTGR = 42, 100
LEVELS = {"base": [], "shift": [SH], "altgr": [ALTGR], "shift+altgr": [ALTGR, SH]}
NAMES = {41: "TLDE", 43: "BKSL", 86: "LSGT", 57: "SPCE"}
NAMES.update({c: "AE%02d" % (c - 1) for c in range(2, 14)}); NAMES.update({c: "AD%02d" % (c - 15) for c in range(16, 28)})
NAMES.update({c: "AC%02d" % (c - 29) for c in range(30, 41)}); NAMES.update({c: "AB%02d" % (c - 43) for c in range(44, 54)})
args = sys.argv[1:]; inc = None
if args and args[0] == "--include": inc = args[1]; args = args[2:]
def kmap(lv, opts):
    lay, _, var = lv.partition(":")
    ctx = xkb.Context(no_default_includes=bool(inc))
    if inc: ctx.include_path_append(inc); ctx.include_path_append("/usr/share/X11/xkb")
    return ctx.keymap_new_from_names(rules="evdev", model="pc105", layout=lay, variant=var, options=opts)
def sym(km, code, mods):
    st = km.state_new()
    for m in mods: st.update_key(m + 8, xkb.XKB_KEY_DOWN)
    return xkb.keysym_get_name(st.key_get_one_sym(code + 8))
new = kmap(args[0], args[1]); old = kmap(*(args[2:4] if len(args) >= 4 else (args[0], "")))
n = 0
for code, name in sorted(NAMES.items()):
    for lv, mods in LEVELS.items():
        a, b = sym(old, code, mods), sym(new, code, mods)
        if a != b: print(f"{name} {lv}: {a} -> {b}"); n += 1
print(f"differences: {n}")
