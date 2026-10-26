#!/usr/bin/env python3
"""Full key table for an XKB layout, computed with libxkbcommon (no VM needed).

For every physical key of a pc105 keyboard and every modifier combination a
Belgian typist uses, print the character produced and whether Ctrl/Alt are
"consumed" (consumed = the toolkit treats the result as text, not a shortcut).

  keytable.py --layout be [--options lv3:ctrlalt_switch] [--include DIR] [--csv out.csv]
  keytable.py --compare be be:lv3:ctrlalt_switch fr us        # side by side
"""
import argparse, csv, sys
from xkbcommon import xkb

# evdev keycodes (linux/input-event-codes.h) of the keys that matter, with the US legend
KEYS = [  # (evdev code, name, US legend)
    (41, "TLDE", "`"), (2, "AE01", "1"), (3, "AE02", "2"), (4, "AE03", "3"), (5, "AE04", "4"), (6, "AE05", "5"),
    (7, "AE06", "6"), (8, "AE07", "7"), (9, "AE08", "8"), (10, "AE09", "9"), (11, "AE10", "0"), (12, "AE11", "-"),
    (13, "AE12", "="),
    (16, "AD01", "q"), (17, "AD02", "w"), (18, "AD03", "e"), (19, "AD04", "r"), (20, "AD05", "t"), (21, "AD06", "y"),
    (22, "AD07", "u"), (23, "AD08", "i"), (24, "AD09", "o"), (25, "AD10", "p"), (26, "AD11", "["), (27, "AD12", "]"),
    (30, "AC01", "a"), (31, "AC02", "s"), (32, "AC03", "d"), (33, "AC04", "f"), (34, "AC05", "g"), (35, "AC06", "h"),
    (36, "AC07", "j"), (37, "AC08", "k"), (38, "AC09", "l"), (39, "AC10", ";"), (40, "AC11", "'"), (43, "BKSL", "\\"),
    (86, "LSGT", "<"), (44, "AB01", "z"), (45, "AB02", "x"), (46, "AB03", "c"), (47, "AB04", "v"), (48, "AB05", "b"),
    (49, "AB06", "n"), (50, "AB07", "m"), (51, "AB08", ","), (52, "AB09", "."), (53, "AB10", "/"), (57, "SPCE", " "),
]
MOD_KEYS = {"Shift": 42, "AltGr": 100, "LCtrl": 29, "LAlt": 56, "Caps": 58}
COMBOS = [(), ("Shift",), ("AltGr",), ("Shift", "AltGr"), ("LCtrl", "LAlt"), ("Shift", "LCtrl", "LAlt"),
          ("Caps",), ("Caps", "AltGr"), ("Caps", "LCtrl", "LAlt")]

DEAD = {"dead_circumflex": "^(dead)", "dead_diaeresis": "¨(dead)", "dead_grave": "`(dead)", "dead_tilde": "~(dead)",
        "dead_acute": "´(dead)"}


def load(spec, include):
    """spec = 'be' or 'be:opt1,opt2' or 'be(variant):opts'"""
    layout, _, options = spec.partition(":")
    variant = ""
    if "(" in layout:
        layout, variant = layout[:-1].split("(")
    ctx = xkb.Context(no_default_includes=bool(include))
    if include:
        ctx.include_path_append(include)
        ctx.include_path_append_default()
    return ctx.keymap_new_from_names(rules="evdev", model="pc105", layout=layout, variant=variant, options=options)


def press(keymap, code, mods):
    st = keymap.state_new()
    for m in mods:
        if m == "Caps":                       # toggle: press and release
            st.update_key(MOD_KEYS[m] + 8, xkb.XKB_KEY_DOWN); st.update_key(MOD_KEYS[m] + 8, xkb.XKB_KEY_UP)
        else:
            st.update_key(MOD_KEYS[m] + 8, xkb.XKB_KEY_DOWN)
    kc = code + 8
    syms = st.key_get_syms(kc)
    name = xkb.keysym_get_name(syms[0]) if syms else ""
    txt = st.key_get_string(kc)
    if name in DEAD:
        txt = DEAD[name]
    elif not txt.isprintable() or txt == "":
        txt = "·" if name in ("", "NoSymbol") else f"<{name}>"
    # which of Control / Mod1(Alt) remain unconsumed -> toolkit sees a shortcut, not text
    ctrl = keymap.mod_get_index("Control"); alt = keymap.mod_get_index("Mod1")
    left = []
    if "LCtrl" in mods and st.mod_index_is_active(ctrl, xkb.XKB_STATE_MODS_EFFECTIVE) and not st.mod_index_is_consumed(kc, ctrl):
        left.append("Ctrl")
    if "LAlt" in mods and st.mod_index_is_active(alt, xkb.XKB_STATE_MODS_EFFECTIVE) and not st.mod_index_is_consumed(kc, alt):
        left.append("Alt")
    return txt + ("" if not left else " [" + "+".join(left) + " not consumed]")


def table(spec, include):
    km = load(spec, include)
    rows = []
    for code, name, legend in KEYS:
        rows.append([name, legend] + [press(km, code, c) for c in COMBOS])
    return rows


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--layout", default="be"); p.add_argument("--options", default="")
    p.add_argument("--include"); p.add_argument("--csv"); p.add_argument("--compare", nargs="*")
    a = p.parse_args()
    hdr = ["key", "US legend"] + ["+".join(c) or "plain" for c in COMBOS]
    if a.compare:
        specs = a.compare
        tabs = {s: table(s, a.include) for s in specs}
        print("key   | combo               | " + " | ".join(f"{s:<22}" for s in specs))
        for i, (code, name, legend) in enumerate(KEYS):
            for j, c in enumerate(COMBOS):
                vals = [tabs[s][i][2 + j] for s in specs]
                if len(set(vals)) == 1 and not a.csv:
                    continue  # identical everywhere: skip in the diff view
                print(f"{name:<5} | {('+'.join(c) or 'plain'):<19} | " + " | ".join(f"{v:<22}" for v in vals))
        return
    spec = a.layout + (":" + a.options if a.options else "")
    rows = table(spec, a.include)
    if a.csv:
        with open(a.csv, "w", newline="") as f:
            w = csv.writer(f); w.writerow(hdr); w.writerows(rows)
        print("wrote", a.csv)
    print(f"{'key':<5} {'US':<3} " + " ".join(f"{h:<18}" for h in hdr[2:]))
    for r in rows:
        print(f"{r[0]:<5} {r[1]:<3} " + " ".join(f"{v:<18}" for v in r[2:]))


if __name__ == "__main__":
    main()
