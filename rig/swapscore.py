#!/usr/bin/env python3
"""Score one fast-typing block: swapscore.py DIR LABEL PATTERN  (files out-LABEL.txt, keylog-LABEL.txt, state-LABEL.txt).

For every typed line: ok, order (right characters, wrong order), count (a key lost or doubled), other.
For every line of the key log (the device the desktop reads: keyd's virtual keyboard when keyd runs, else the
PS/2 keyboard): were the non-modifier key presses in the order they were sent? That separates "the keys reached
the desktop in order and something above reordered them" from "the keys were already out of order".
Writes score-LABEL.txt and prints its summary line.
"""
import os, re, statistics, sys
sys.path.insert(0, os.path.dirname(__file__))
from swaptest import expect, PATTERNS, MIXED_KEYS

MODS = {"LEFTCTRL", "RIGHTCTRL", "LEFTALT", "RIGHTALT", "LEFTSHIFT", "RIGHTSHIFT", "LEFTMETA", "RIGHTMETA"}
QNAME = {"2": "2", "e": "E", "9": "9", "0": "0", "bracket_left": "LBRACE"}


def sent_keys(pattern):
    keys = [k for k, _ in MIXED_KEYS] if pattern == "mixed" else PATTERNS[pattern][2]
    return [QNAME.get(k, k.upper()) for k in keys]


def classify(line, want):
    if line == want:
        return "ok"
    if sorted(line) == sorted(want):
        return "order"
    if set(line) <= set(want):
        return "count"
    return "other"


def keylog_lines(path):
    rows = []
    for l in open(path, encoding="utf-8", errors="replace"):
        m = re.match(r"^\s*([\d.]+) (.{28}) (\S+)\s+(down|up)\s*$", l.rstrip("\n"))
        if m:
            rows.append((float(m.group(1)), m.group(2).strip(), m.group(3), m.group(4)))
    devs = {r[1] for r in rows}
    dev = next((d for d in devs if "keyd virtual keyboard" in d), None) or next((d for d in devs if "AT Translated" in d), None)
    lines, cur = [], []
    for t, d, k, ud in rows:
        if d != dev or ud != "down":
            continue
        if k == "ENTER":
            lines.append(cur); cur = []
        elif k not in MODS:
            cur.append((t, k))
    return dev, lines


def main(d, label, pattern):
    want = expect(pattern)
    typed = [l.rstrip("\n") for l in open(os.path.join(d, f"out-{label}.txt"), encoding="utf-8", errors="replace")]
    typed = [l for l in typed if l.strip()]
    res = [classify(l, want) for l in typed]
    dev, klines = keylog_lines(os.path.join(d, f"keylog-{label}.txt"))
    sent = sent_keys(pattern)
    korder = [[k for _, k in kl] == sent for kl in klines]
    gaps = [b[0] - a[0] for kl in klines for a, b in zip(kl, kl[1:])]
    state = open(os.path.join(d, f"state-{label}.txt"), encoding="utf-8", errors="replace").read().strip().splitlines()
    n = len(typed)
    summary = (f"{label} [{pattern}] typed lines {n}: ok {res.count('ok')}, order {res.count('order')}, "
               f"count {res.count('count')}, other {res.count('other')} | key log ({dev}): {sum(korder)}/{len(klines)} "
               f"lines in sent order" + (f", key gap median {statistics.median(gaps)*1000:.0f} ms min "
                                          f"{min(gaps)*1000:.0f} ms" if gaps else ""))
    with open(os.path.join(d, f"score-{label}.txt"), "w", encoding="utf-8") as f:
        f.write(summary + "\n")
        f.writelines(s + "\n" for s in state)
        f.write(f"expected: {want}\n")
        for i, (l, r) in enumerate(zip(typed, res)):
            klo = "-" if i >= len(korder) else ("keys in order" if korder[i] else "KEYS OUT OF ORDER: " + " ".join(k for _, k in klines[i]))
            f.write(f"{i+1:3} {r:5} {l}   [{klo}]\n")
    print(summary)


if __name__ == "__main__":
    main(*sys.argv[1:4])
