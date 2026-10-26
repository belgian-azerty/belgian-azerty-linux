#!/usr/bin/env python3
"""Fast-typing order test: press keys with exact timing through QMP input-send-event (down/up events one by one).

QEMU delivers the events to the guest's PS/2 keyboard in exactly this order, so if the guest shows the characters
in another order, the guest software reordered them (keyd, the compositor, ibus or the toolkit), never the "finger".

  swaptest.py lines NAME PATTERN N GAP_MS [--hold MS] [--roll]    # type N lines + Enter each
  swaptest.py expect PATTERN                                      # print the line the guest should show

PATTERN
  altgr     AltGr held for the whole line, then 2 e 2 e ... (8 pairs)       -> @€@€@€@€@€@€@€@€
  ctrlalt   left Ctrl + left Alt held for the whole line, then 2 e ...      -> same (needs keyd)
  altgr1    AltGr pressed and released around every key                      -> same
  ctrlalt1  Ctrl+Alt pressed and released around every key                   -> same (needs keyd)
  plain     a z e r t y u i o p q s d f g h (Belgian legends, no modifier)  -> azertyuiopqsdfgh
  mixed     a @ z € e { r } (AltGr only on the symbols, AltGr up between)    -> a@z€e{r}a@z€e{r}
  dead      ^ (dead key) then e, 8 times                                    -> êêêêêêêê
GAP_MS = time from one key press to the next; --hold = how long a key stays down (default 0.6 x gap);
--roll = press the next key before releasing the previous one (fast typists do this; hold becomes 1.5 x gap).
"""
import sys, time, argparse
sys.path.insert(0, __import__("os").path.dirname(__file__))
from qemu_rig import QMP, paths

PAIRS = 8
PATTERNS = {
    # name: (held modifiers for the whole line, per-key modifiers, keys, expected text)
    "altgr":    (["alt_r"], [], ["2", "e"] * PAIRS, "@€" * PAIRS),
    "ctrlalt":  (["ctrl", "alt"], [], ["2", "e"] * PAIRS, "@€" * PAIRS),
    "altgr1":   ([], ["alt_r"], ["2", "e"] * PAIRS, "@€" * PAIRS),
    "ctrlalt1": ([], ["ctrl", "alt"], ["2", "e"] * PAIRS, "@€" * PAIRS),
    "plain":    ([], [], list("qwertyuiopasdfgh"), "azertyuiopqsdfgh"),
    "dead":     ([], [], ["bracket_left", "e"] * PAIRS, "ê" * PAIRS),     # dead circumflex, then e
}
MIXED_KEYS = [("q", []), ("2", ["alt_r"]), ("w", []), ("e", ["alt_r"]), ("e", []), ("9", ["alt_r"]), ("r", []),
              ("0", ["alt_r"])] * 2
MIXED_TEXT = "a@z€e{r}" * 2


def ev(key, down):
    return {"type": "key", "data": {"down": down, "key": {"type": "qcode", "data": key}}}


class Typist:
    def __init__(self, name):
        self.q = QMP(paths(name)[1])

    def send(self, key, down):
        self.q.cmd("input-send-event", events=[ev(key, down)])


def wait_until(t):
    while True:
        d = t - time.perf_counter()
        if d <= 0:
            return
        time.sleep(min(d, 0.002) if d < 0.004 else d - 0.002)


def line(t, pattern, gap, hold, roll):
    """Schedule every down/up event of one line on a timeline, then play it in time order."""
    g, h = gap / 1000, hold / 1000
    sched = []   # (time, seq, key, down)
    if pattern == "mixed":
        held, keys = [], MIXED_KEYS
    else:
        held, per, ks, _ = PATTERNS[pattern]
        keys = [(k, per) for k in ks]
    now = 0.0
    for m in held:
        sched.append((now, len(sched), m, True)); now += 0.03
    for k, mods in keys:
        if mods:   # modifiers go down just before the key and up just after it
            for m in mods:
                sched.append((now, len(sched), m, True)); now += min(0.02, g / 4)
            sched.append((now, len(sched), k, True))
            up = now + min(h, g * 0.6)
            sched.append((up, len(sched), k, False))
            for m in reversed(mods):
                up += 0.01; sched.append((up, len(sched), m, False))
            now = up + max(0.0, g - (up - now))
        else:
            sched.append((now, len(sched), k, True))
            sched.append((now + h, len(sched), k, False))
            now += g
    end = max(s[0] for s in sched) + 0.03
    for m in reversed(held):
        sched.append((end, len(sched), m, False)); end += 0.01
    end += 0.05
    sched.append((end, len(sched), "ret", True)); sched.append((end + 0.05, len(sched), "ret", False))
    sched.sort()
    t0 = time.perf_counter()
    for at, _, k, down in sched:
        wait_until(t0 + at)
        t.send(k, down)
    return time.perf_counter() - t0


def expect(pattern):
    return MIXED_TEXT if pattern == "mixed" else PATTERNS[pattern][3]


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("lines"); s.add_argument("name"); s.add_argument("pattern", choices=list(PATTERNS) + ["mixed"])
    s.add_argument("n", type=int); s.add_argument("gap", type=float)
    s.add_argument("--hold", type=float); s.add_argument("--roll", action="store_true")
    s.add_argument("--pause", type=float, default=0.6, help="seconds between lines")
    s = sub.add_parser("expect"); s.add_argument("pattern")
    a = p.parse_args()
    if a.cmd == "expect":
        print(expect(a.pattern)); sys.exit()
    hold = a.hold if a.hold else (a.gap * 1.5 if a.roll else a.gap * 0.6)
    t = Typist(a.name)
    for i in range(a.n):
        dur = line(t, a.pattern, a.gap, hold, a.roll)
        time.sleep(a.pause)
    print(f"typed {a.n} lines of {a.pattern} gap {a.gap} ms hold {hold:.0f} ms{' roll' if a.roll else ''}, last line {dur:.2f} s")
