#!/usr/bin/env python3
"""Timed key bursts into a QEMU guest through QMP input-send-event (key down and key up as separate events), for the
ibus-skip test. Written again for 0.9.5; the swap thread's swaptest.py stayed on the laptop. Run from rig/.
  burst.py NAME altgr|ctrlalt --lines 20 --pairs 8 --gap 0.03 [--overlap]   modifier held, 2 E 2 E ... then Enter
  burst.py NAME dead                       slow dead-key line: ^e ¨e AltGr+ù e  AltGr+µ e  AltGr+= n  ^ space  Ctrl+Alt+ù e
  burst.py NAME text --text "..."          plain keys, QEMU names separated by spaces, then Enter
Expected text: altgr/ctrlalt '@€' x pairs; dead 'êëéèñ^é'.
"""
import argparse, os, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path[:0] = [HERE, os.path.join(HERE, "..", "..", "rig")]   # qemu_rig.py next to it, or in the project rig/
import qemu_rig as R


def ev(q, events):
    q.cmd("input-send-event", events=[{"type": "key", "data": {"down": d, "key": {"type": "qcode", "data": k}}} for k, d in events])


def tap(q, k, mods=(), t=0.08):
    ev(q, [(m, True) for m in mods]); time.sleep(0.02)
    ev(q, [(k, True)]); time.sleep(t); ev(q, [(k, False)]); time.sleep(0.02)
    ev(q, [(m, False) for m in mods]); time.sleep(t)


def line(q, mods, keys, gap, overlap):
    hold = gap * 1.5 if overlap else gap * 0.5      # overlap: next key goes down before this one is up
    tl = []
    for i, k in enumerate(keys):
        tl.append((i * gap, k, True)); tl.append((i * gap + hold, k, False))
    tl.sort(key=lambda x: (x[0], not x[2]))
    ev(q, [(m, True) for m in mods]); time.sleep(0.05)
    t0 = time.monotonic()
    for t, k, d in tl:
        w = t0 + t - time.monotonic()
        if w > 0: time.sleep(w)
        ev(q, [(k, d)])
    time.sleep(0.05); ev(q, [(m, False) for m in mods]); time.sleep(0.15)
    tap(q, "ret"); time.sleep(0.4)


p = argparse.ArgumentParser(); p.add_argument("name"); p.add_argument("kind", choices=["altgr", "ctrlalt", "dead", "text"])
p.add_argument("--lines", type=int, default=20); p.add_argument("--pairs", type=int, default=8)
p.add_argument("--gap", type=float, default=0.03); p.add_argument("--overlap", action="store_true"); p.add_argument("--text", default="")
a = p.parse_args()
q = R.QMP(R.paths(a.name)[1])
if a.kind in ("altgr", "ctrlalt"):
    mods = ["alt_r"] if a.kind == "altgr" else ["ctrl", "alt"]
    for _ in range(a.lines):
        line(q, mods, ["2", "e"] * a.pairs, a.gap, a.overlap)
elif a.kind == "dead":
    for _ in range(a.lines):
        tap(q, "bracket_left"); tap(q, "e")                       # ^ e  -> ê
        tap(q, "bracket_left", ["shift"]); tap(q, "e")            # ¨ e  -> ë
        tap(q, "apostrophe", ["alt_r"]); tap(q, "e")              # ´ e  -> é
        tap(q, "backslash", ["alt_r"]); tap(q, "e")               # ` e  -> è
        tap(q, "slash", ["alt_r"]); tap(q, "n")                   # ~ n  -> ñ
        tap(q, "bracket_left"); tap(q, "spc")                     # ^ space -> ^
        tap(q, "apostrophe", ["ctrl", "alt"]); tap(q, "e")        # Ctrl+Alt+ù e -> é (through keyd)
        tap(q, "ret"); time.sleep(0.4)
else:
    for k in a.text.split():
        mods, _, key = k.rpartition("-")
        tap(q, key, [m for m in mods.split("-") if m])
    tap(q, "ret")
print("sent", a.kind, a.lines if a.kind != "text" else "")
