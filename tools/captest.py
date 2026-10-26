#!/usr/bin/env python3
"""Compare Caps Lock behaviour of XKB option sets with Windows Belgian (Caps = Shift level on the main block except
² and <; Caps+Shift = base level; AltGr and numpad unaffected). Usage: captest.py [--include DIR] OPTS..."""
import sys
from xkbcommon import xkb
KEYS = [(41,"²"),(2,"1"),(3,"2"),(4,"3"),(5,"4"),(6,"5"),(7,"6"),(8,"7"),(9,"8"),(10,"9"),(11,"0"),(12,")"),(13,"-"),
        (16,"a"),(17,"z"),(26,"^"),(27,"$"),(39,"m"),(40,"ù"),(43,"µ"),(86,"<"),(50,","),(51,";"),(52,":"),(53,"="),
        (79,"KP1"),(83,"KP.")]
EXEMPT = {41, 86, 79, 83}
SH, CAPS, ALTGR, NUM = 42, 58, 100, 69
args = sys.argv[1:]; inc = None
if args and args[0] == "--include": inc = args[1]; args = args[2:]
def kmap(opts):
    ctx = xkb.Context(no_default_includes=bool(inc))
    if inc: ctx.include_path_append(inc); ctx.include_path_append("/usr/share/X11/xkb")
    return ctx.keymap_new_from_names(rules="evdev", model="pc105", layout="be", options=opts)
def out(km, keys, lock_caps):
    st = km.state_new()
    st.update_key(NUM + 8, xkb.XKB_KEY_DOWN); st.update_key(NUM + 8, xkb.XKB_KEY_UP)
    if lock_caps: st.update_key(CAPS + 8, xkb.XKB_KEY_DOWN); st.update_key(CAPS + 8, xkb.XKB_KEY_UP)
    for k in keys[:-1]: st.update_key(k + 8, xkb.XKB_KEY_DOWN)
    s = st.key_get_string(keys[-1] + 8) or "·"
    return s if s.isprintable() else "·"
base = kmap("")
def target(code, combo):
    if combo == "caps":       return out(base, [code], False) if code in EXEMPT else out(base, [SH, code], False)
    if combo == "caps+shift": return out(base, [SH, code], False) if code in EXEMPT else out(base, [code], False)
    if combo == "caps+altgr": return out(base, [ALTGR, code], False)
# Reference rows: what Windows does with Caps Lock. For caps+altgr the reference is the layout's own AltGr level
# (Caps Lock must leave AltGr alone, as on Windows); the Windows AltGr symbols themselves differ from Linux on keys 4
# and 5 (Windows { [, Linux ¼ ½), which the keyd rules fix, not this option.
print("key  " + " ".join(f"{n:>4}" for _, n in KEYS))
for combo in ("caps", "caps+shift", "caps+altgr"):
    print(f"expect  {combo:10}: " + " ".join(f"{target(c, combo):>4}" for c, _ in KEYS))
    for opts in args:
        km = kmap(opts if opts != "none" else "")
        mods = {"caps": [], "caps+shift": [SH], "caps+altgr": [ALTGR]}[combo]
        row = []; bad = 0
        for c, _ in KEYS:
            o = out(km, mods + [c], True); ok = o == target(c, combo); bad += not ok
            row.append(f"{o:>4}" if ok else f"{'*'+o:>4}")
        print(f"  {opts:28.28}: " + " ".join(row) + f"   mismatches={bad}")
