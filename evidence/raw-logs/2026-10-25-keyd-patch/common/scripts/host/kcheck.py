#!/usr/bin/env python3
"""kcheck.py KEYLOG [KEYLOG...]: per typed line (split at ENTER), what keyd's virtual keyboard sent compared with what
the PS/2 keyboard received. Per line: RIGHTALT downs, Ctrl/Alt events between the first and last symbol key, events
per symbol, largest gap between keyd output events inside the line, largest input->output delay of a key press."""
import re, sys

MODS = {"LEFTCTRL", "RIGHTCTRL", "LEFTALT", "RIGHTALT", "LEFTSHIFT", "RIGHTSHIFT", "LEFTMETA", "RIGHTMETA"}


def rows(path):
    out = []
    for l in open(path, encoding="utf-8", errors="replace"):
        m = re.match(r"^\s*([\d.]+) (.{28}) (\S+)\s+(down|up)\s*$", l.rstrip("\n"))
        if m:
            out.append((float(m.group(1)), m.group(2).strip(), m.group(3), m.group(4)))
    return out


def split(evs):
    lines, cur = [], []
    for e in evs:
        cur.append(e)
        if e[2] == "ENTER" and e[3] == "down":
            lines.append(cur); cur = []
    return lines


def main(paths):
    bad = 0
    for p in paths:
        r = rows(p)
        devs = sorted({x[1] for x in r})
        kd = next((d for d in devs if "keyd virtual keyboard" in d), None)
        inp = next((d for d in devs if "AT Translated" in d), None)
        print(f"# {p}: devices {devs}")
        if not kd:
            print("  no keyd virtual keyboard events"); continue
        outl = split([x for x in r if x[1] == kd]); inl = split([x for x in r if x[1] == inp])
        for i, ol in enumerate(outl):
            while ol and ol[0][2] == "ENTER" and ol[0][3] == "up":   # release of the previous line's Enter
                ol = ol[1:]
            body = [e for e in ol if e[2] != "ENTER"]
            sym = [j for j, e in enumerate(body) if e[2] not in MODS]
            if not sym:
                print(f"  line {i+1}: no symbol keys"); continue
            a, b = sym[0], sym[-1]
            span = body[a:b + 1]
            mods_in = [f"{e[2]} {e[3]}" for e in span if e[2] in MODS]
            nsym = sum(1 for e in span if e[2] not in MODS and e[3] == "down")
            ra = sum(1 for e in body if e[2] == "RIGHTALT" and e[3] == "down")
            gaps = [y[0] - x[0] for x, y in zip(ol, ol[1:])]
            mg = max(gaps) if gaps else 0
            lat = ""
            if i < len(inl):
                ind = [e for e in inl[i] if e[2] not in MODS and e[3] == "down"]
                outd = [e for e in ol if e[2] not in MODS and e[3] == "down"]
                if len(ind) == len(outd):
                    d = [o[0] - n[0] for n, o in zip(ind, outd)]
                    lat = f", in->out delay max {max(d)*1000:.0f} ms"
                else:
                    lat = f", input/output key count differ ({len(ind)}/{len(outd)})"
            first = " ".join(f"{e[2]}:{e[3][0]}" for e in body[:a])
            flag = "" if (not mods_in and mg <= 0.3) else "  <-- CHECK"
            bad += bool(flag)
            print(f"  line {i+1}: RIGHTALT down x{ra}, before 1st symbol [{first}], {nsym} symbols, "
                  f"{len(span)} events in symbol span ({len(span)/max(nsym,1):.2f}/symbol), Ctrl/Alt events inside: "
                  f"{len(mods_in)}{' ' + ','.join(mods_in[:6]) if mods_in else ''}, max gap {mg*1000:.0f} ms{lat}{flag}")
    print(f"lines flagged: {bad}")


if __name__ == "__main__":
    main(sys.argv[1:])
