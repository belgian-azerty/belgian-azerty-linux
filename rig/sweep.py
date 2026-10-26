#!/usr/bin/env python3
"""Shortcut sweep. send: press every combo of the matrix with 1.3 s gaps (guest runs sweep-guest.sh LABEL).
compare OFF.txt ON.txt: group keyd-monitor logs by pauses, compare per combo, print a table.
  sweep.py send VM      |   sweep.py compare up/mon-off.txt up/mon-on.txt [--md] [--skip-off=N] [--skip-on=N]
  (--skip-*: number of leading key groups to drop, when something was typed into the recorder before the matrix)"""
import sys, time, os, re, subprocess
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
L = lambda s: s.split()
# (group, combo, expectation) ; expectation: "same" = must reach the desktop unchanged, "altgr" = becomes AltGr+key
REMAP = ["1", "2", "3", "4", "5", "6", "9", "0", "e", "bracket_left", "bracket_right", "apostrophe", "backslash", "slash", "less"]
M = []
for k in REMAP: M.append(("Ctrl+Alt (AltGr table)", f"ctrl-alt-{k}", "altgr"))
for k in REMAP: M.append(("Ctrl+Alt (AltGr table), right Ctrl", f"ctrl_r-alt-{k}", "altgr"))
for k in ["2", "e", "9"]: M.append(("Shift+Ctrl+Alt (AltGr table)", f"shift-ctrl-alt-{k}", "altgr-shift"))
for k in REMAP: M.append(("AltGr", f"alt_r-{k}", "altgr45" if k in ("4", "5") else "same"))
for k in L("a b c d f g h i j k l m n o p q r s t u v w x y z 7 8 minus equal semicolon comma dot grave_accent tab spc ret backspace esc up down left right home end pgup pgdn insert"):
    M.append(("Ctrl+Alt (not in table)", f"ctrl-alt-{k}", "same"))
for k in L("t up down left right 7 8 a"): M.append(("Shift+Ctrl+Alt", f"shift-ctrl-alt-{k}", "same"))
for k in L("a c v x z s y f n o p w q t l r 1 2 3 4 5 6 7 8 9 0 tab pgup pgdn home end"): M.append(("Ctrl", f"ctrl-{k}", "same"))
for k in L("c v t n w z tab"): M.append(("Ctrl+Shift", f"ctrl-shift-{k}", "same"))
for k in L("f2 f4 f10 tab 1 2 e f h"): M.append(("Alt", f"alt-{k}", "same"))
M.append(("Alt", "alt-shift-tab", "same"))
for k in ["meta_l", "meta_l-a", "meta_l-d", "meta_l-e", "meta_l-l", "meta_l-up", "meta_l-down", "meta_l-left", "meta_l-right", "meta_l-tab", "meta_l-1", "meta_l-shift-left"]:
    M.append(("Super", k, "same"))
for k in L("f1 f2 f3 f4 f5 f6 f7"): M.append(("Ctrl+Alt+F (VT switch)", f"ctrl-alt-{k}", "same"))

def is_vt(c): return re.fullmatch(r"ctrl-alt-f\d+", c) is not None and c != "ctrl-alt-f3"

SHOTS = os.environ.get("SWEEP_SHOTS")   # optional folder: screen dump after each VT switch and after each return

def send(vm):
    from qemu_rig import QMP, paths
    q = QMP(paths(vm)[1])
    for i, (g, c, e) in enumerate(M):
        q.hmp(f"sendkey {c} 120"); time.sleep(0.25 * len(c.split("-")) + 1.2)   # QEMU spaces each event ~120 ms
        if is_vt(c):
            if SHOTS: q.hmp(f"screendump {SHOTS}/vt-{c}.ppm")
            q.hmp("sendkey ctrl-alt-f3 120"); time.sleep(3)   # back to the recording console
            if SHOTS: q.hmp(f"screendump {SHOTS}/vt-{c}-back.ppm")
    print(f"sent {len(M)} combos")

def groups(path):
    out, cur = [], []
    for line in open(path, errors="replace"):
        m = re.match(r"^(?:\+(\d+) ms\t)?(.+?)\t[0-9a-f]{4}:[0-9a-f]{4}:[0-9a-f]{8}\t(.+)$", line.rstrip("\n"))
        if not m: continue
        dt, dev, ev = m.groups()
        if "keyboard" not in dev: continue
        if dt is not None and int(dt) > 600 and cur:
            out.append(cur); cur = []
        cur.append(ev)
    if cur: out.append(cur)
    return out

def strip_tail(gs):
    # drop groups belonging to the typed "stopstop" end marker and the start
    return gs

def compare(off, on, md=False, skip_off=0, skip_on=0):
    seq = []
    for g, c, e in M:
        seq.append((g, c, e))
        if is_vt(c): seq.append(("(return)", "ctrl-alt-f3", "same"))
    A, B = groups(off)[skip_off:], groups(on)[skip_on:]   # skip = leading groups typed before the matrix (e.g. a password)
    print(f"groups: off={len(A)} on={len(B)} expected={len(seq)} (+ end marker)")
    rows = []
    for i, (g, c, e) in enumerate(seq):
        a = A[i] if i < len(A) else ["?"]; b = B[i] if i < len(B) else ["?"]
        same = a == b
        if e == "same": ok = same
        elif e.startswith("altgr"):
            ok = ("rightalt down" in b) and not same if e != "altgr45" else ("rightalt down" in b and not same)
        rows.append((g, c, e, ok, " ".join(a), " ".join(b)))
    if md:
        print("| group | combo (QEMU key names) | expected | result | keyd off: events | keyd on: events |")
        print("|---|---|---|---|---|---|")
        for r in rows: print(f"| {r[0]} | `{r[1]}` | {r[2]} | {'PASS' if r[3] else 'FAIL'} | {r[4]} | {r[5]} |")
    else:
        for r in rows: print(("PASS" if r[3] else "FAIL"), r[0], r[1], r[2], "|", r[4], "||", r[5])
    print("PASS", sum(r[3] for r in rows), "FAIL", sum(not r[3] for r in rows))

if __name__ == "__main__":
    if sys.argv[1] == "send": send(sys.argv[2])
    elif sys.argv[1] == "count": print(len(M))
    else:
        opt = lambda n: int(next((a.split("=")[1] for a in sys.argv if a.startswith(n + "=")), 0))
        compare(sys.argv[2], sys.argv[3], "--md" in sys.argv, opt("--skip-off"), opt("--skip-on"))
