# Walk Ubiquity's keyboard detector (its own code, unchanged) with a model keyboard built from an XKB layout.
# A PRESS step branches over every listed symbol printed on the keyboard; FINDP = symbol on level 1-2, FIND = level 1-3.
import sys, importlib.util
from xkbcommon import xkb
spec = importlib.util.spec_from_file_location('kd', sys.argv[1]); kd = importlib.util.module_from_spec(spec); spec.loader.exec_module(kd)
TREE = sys.argv[2]; LAYOUT = sys.argv[3]; VARIANT = sys.argv[4] if len(sys.argv) > 4 else ''
# MODEL: strict = only plain+Shift printed; full = plain, Shift, AltGr all printed; be-caps = plain+Shift + the AltGr signs engraved on Belgian key caps
MODEL = sys.argv[5] if len(sys.argv) > 5 else 'strict'
# AltGr signs engraved on Belgian key caps, with their key (evdev code)
BE_CAPS = {'|': 2, '@': 3, '#': 4, '^': 7, '{': 10, '}': 11, '[': 26, ']': 27, '´': 40, '`': 43, '\\': 86, '~': 53, '€': 18}
ctx = xkb.Context(); km = ctx.keymap_new_from_names(layout=LAYOUT, variant=VARIANT)
labels = {}  # evdev code -> {level: char}
for kc in range(9, 120):
    for lvl in range(3):
        syms = km.key_get_syms_by_level(kc, 0, lvl)
        for s in syms:
            ch = xkb.keysym_to_string(s)
            if ch and len(ch) == 1 and ch.isprintable():
                labels.setdefault(kc - 8, {}).setdefault(lvl, ch)
def keys_with(ch, levels):
    if MODEL == 'full': levels = (0, 1, 2)
    out = [c for c, l in labels.items() if any(l.get(v) == ch for v in levels)]
    if MODEL == 'be-caps' and ch in BE_CAPS and labels.get(BE_CAPS[ch], {}).get(2) == ch and BE_CAPS[ch] not in out: out.append(BE_CAPS[ch])
    return out
def new_det():
    d = kd.KeyboardDetector.__new__(kd.KeyboardDetector)
    d.current_step = -1; d.fp = open(TREE); d.keycodes = {}; d.symbols = []; d.present = d.not_present = -1; d.result = ''
    return d
results = []
def walk(path):
    d = new_det(); r = d.read_step(0); trail = []
    for choice in path:
        trail.append(choice)
        try:
            r = d.read_step(choice[1])
        except Exception as e:
            results.append((trail, 'EXCEPTION ' + repr(e))); return
    D = kd.KeyboardDetector
    if r == D.RESULT:
        results.append((trail, d.result)); return
    if r == D.PRESS_KEY:
        opts = []
        for sym in d.symbols:
            for code in keys_with(sym, (0, 1)):
                if code in d.keycodes: opts.append(('press %s (key %d)' % (sym, code), d.keycodes[code]))
                else: opts.append(('press %s (key %d) -> ignored, window waits' % (sym, code), None))
        if not opts:
            results.append((trail, 'STUCK: none of %s is on this keyboard' % ' '.join(d.symbols))); return
        for o in opts:
            if o[1] is None: results.append((trail + [o], 'WAITS (keycode not in tree)'))
            else: walk(path + [o])
        return
    if r in (D.KEY_PRESENT, D.KEY_PRESENT_P):
        lv = (0, 1) if r == D.KEY_PRESENT_P else (0, 1, 2)
        have = bool(keys_with(d.symbols[0], lv))
        walk(path + [('has %s? %s' % (d.symbols[0], 'yes' if have else 'no'), d.present if have else d.not_present)])
        return
    results.append((trail, 'UNKNOWN step type %r (symbols %r)' % (r, d.symbols)))
walk([])
from collections import Counter
print('layout', LAYOUT, VARIANT, MODEL, '->', dict(Counter(r for _, r in results)))
if '-v' in sys.argv[6:] or (len(sys.argv) > 5 and '-v' in sys.argv):
    for t, r in results: print('  ', ' | '.join(c[0] for c in t), '=>', r)
