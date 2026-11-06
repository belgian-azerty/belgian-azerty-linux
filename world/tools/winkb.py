# Shared helpers for the world prototype: read a Unicode CLDR 43 Windows keyboard file, and ask libxkbcommon what a
# Linux layout types (every key x 6 states, plus accent sequences through the Compose table).
# Used by gen_windows_symbols.py (writes the "(Windows)" layouts) and check_windows_symbols.py (machine check).
import ctypes, re, xml.etree.ElementTree as ET

# ---- CLDR 43 Windows files -----------------------------------------------------------------------------------------
# ISO key positions (CLDR) -> xkb key names (evdev keycodes).
ISO2XKB = {'E00': 'TLDE', 'C12': 'BKSL', 'D13': 'BKSL', 'B00': 'LSGT'}
for i in range(1, 13): ISO2XKB['E%02d' % i] = 'AE%02d' % i
for i in range(1, 13): ISO2XKB['D%02d' % i] = 'AD%02d' % i
for i in range(1, 12): ISO2XKB['C%02d' % i] = 'AC%02d' % i
for i in range(1, 11): ISO2XKB['B%02d' % i] = 'AB%02d' % i
STATES = ['base', 'shift', 'caps', 'capsshift', 'altgr', 'shiftaltgr']
_MODS = {'base': set(), 'shift': {'shift'}, 'caps': {'caps'}, 'capsshift': {'caps', 'shift'},
         'altgr': {'ctrl', 'alt'}, 'shiftaltgr': {'ctrl', 'alt', 'shift'}}

def _unesc(s): return re.sub(r'\\u\{([0-9a-fA-F]+)\}', lambda m: chr(int(m.group(1), 16)), s)

def _matches(attr, want):
    if attr is None: return not want
    for alt in attr.split():
        req, opt = set(), set()
        for m in alt.split('+'):
            (opt if m.endswith('?') else req).add(m.rstrip('?'))
        if 'altR' in req: req = (req - {'altR'}) | {'ctrl', 'alt'}      # Windows AltGr = Ctrl+Alt
        if req <= want <= req | opt: return True
    return False

def read_cldr(path):
    """-> (name, keys {xkbkey: {state: char | 'dead:<c>' | 'str:<s>'}}, transforms {'<dead><c>': result})"""
    root = ET.parse(path).getroot()
    name = root.find('names/name').get('value')
    trans = {_unesc(t.get('from')): _unesc(t.get('to')) for t in root.iter('transform')}
    # a control character is not text (Romanian legacy AltGr+< gives U+001C, Greek Latin ¨ then Y gives U+009F, the
    # Windows-1252 code of Ÿ): such cells and results are left out
    _ctrl = lambda t: any(ord(ch) < 0x20 or 0x7f <= ord(ch) <= 0x9f for ch in t)
    trans = {f: t for f, t in trans.items() if not _ctrl(t)}
    deadc = {k[0] for k in trans if len(k) >= 2}
    keys = {}
    for st in STATES:
        want = _MODS[st]
        cands = [km for km in root.findall('keyMap') if _matches(km.get('modifiers'), want)]
        if not cands and 'caps' in want:          # no Caps Lock table: Caps Lock does nothing on these keys
            cands = [km for km in root.findall('keyMap') if _matches(km.get('modifiers'), want - {'caps'})]
        for km in cands[:1]:
            for m in km.findall('map'):
                k = ISO2XKB.get(m.get('iso'))
                if k is None: continue
                to = _unesc(m.get('to'))
                if len(to) != 1: keys.setdefault(k, {})[st] = 'str:' + to; continue
                if _ctrl(to): continue
                keys.setdefault(k, {})[st] = ('dead:' + to) if (to in deadc and m.get('transform') != 'no') else to
    return name, keys, trans

# ---- libxkbcommon ---------------------------------------------------------------------------------------------------
L = ctypes.CDLL("libxkbcommon.so.0")
class _Names(ctypes.Structure): _fields_ = [(n, ctypes.c_char_p) for n in ("rules", "model", "layout", "variant", "options")]
_P = ctypes.c_void_p
for f, r, a in [
        ("xkb_context_new", _P, [ctypes.c_int]), ("xkb_context_include_path_append", ctypes.c_int, [_P, ctypes.c_char_p]),
        ("xkb_context_include_path_append_default", ctypes.c_int, [_P]),
        ("xkb_keymap_new_from_names", _P, [_P, ctypes.POINTER(_Names), ctypes.c_int]),
        ("xkb_keymap_new_from_string", _P, [_P, ctypes.c_char_p, ctypes.c_int, ctypes.c_int]),
        ("xkb_keymap_unref", None, [_P]), ("xkb_keymap_key_by_name", ctypes.c_uint32, [_P, ctypes.c_char_p]),
        ("xkb_keymap_num_levels_for_key", ctypes.c_uint32, [_P, ctypes.c_uint32, ctypes.c_uint32]),
        ("xkb_keymap_key_get_syms_by_level", ctypes.c_int, [_P, ctypes.c_uint32, ctypes.c_uint32, ctypes.c_uint32,
                                                             ctypes.POINTER(ctypes.POINTER(ctypes.c_uint32))]),
        ("xkb_state_new", _P, [_P]), ("xkb_state_unref", None, [_P]),
        ("xkb_state_update_key", ctypes.c_int, [_P, ctypes.c_uint32, ctypes.c_int]),
        ("xkb_state_key_get_one_sym", ctypes.c_uint32, [_P, ctypes.c_uint32]),
        ("xkb_keysym_to_utf32", ctypes.c_uint32, [ctypes.c_uint32]), ("xkb_utf32_to_keysym", ctypes.c_uint32, [ctypes.c_uint32]),
        ("xkb_keysym_to_upper", ctypes.c_uint32, [ctypes.c_uint32]), ("xkb_keysym_to_lower", ctypes.c_uint32, [ctypes.c_uint32]),
        ("xkb_keysym_get_name", ctypes.c_int, [ctypes.c_uint32, ctypes.c_char_p, ctypes.c_size_t]),
        ("xkb_keysym_from_name", ctypes.c_uint32, [ctypes.c_char_p, ctypes.c_int]),
        ("xkb_compose_table_new_from_locale", _P, [_P, ctypes.c_char_p, ctypes.c_int]),
        ("xkb_compose_table_new_from_buffer", _P, [_P, ctypes.c_char_p, ctypes.c_size_t, ctypes.c_char_p, ctypes.c_int, ctypes.c_int]),
        ("xkb_compose_state_new", _P, [_P, ctypes.c_int]), ("xkb_compose_state_unref", None, [_P]),
        ("xkb_compose_state_feed", ctypes.c_int, [_P, ctypes.c_uint32]),
        ("xkb_compose_state_get_status", ctypes.c_int, [_P]),
        ("xkb_compose_state_get_utf8", ctypes.c_int, [_P, ctypes.c_char_p, ctypes.c_size_t])]:
    fn = getattr(L, f); fn.restype = r; fn.argtypes = a
_buf = ctypes.create_string_buffer(128)
DEAD = {'`': 'grave', '´': 'acute', '^': 'circumflex', '~': 'tilde', '¨': 'diaeresis', '¸': 'cedilla', 'ˇ': 'caron',
        '˘': 'breve', '°': 'abovering', '˝': 'doubleacute', '˛': 'ogonek', '˙': 'abovedot', '¯': 'macron'}
DEADNAME = {v: k for k, v in DEAD.items()}

def context(extra_dir=None):
    ctx = L.xkb_context_new(1)                     # XKB_CONTEXT_NO_DEFAULT_INCLUDES: our folder first, then the system
    if extra_dir: L.xkb_context_include_path_append(ctx, extra_dir.encode())
    L.xkb_context_include_path_append_default(ctx)
    return ctx

def sym_name(ks):
    L.xkb_keysym_get_name(ks, _buf, 128); return _buf.value.decode()

def char_to_sym(c):
    """Windows cell -> keysym name ('dead:´' -> dead_acute)."""
    if c.startswith('dead:'):
        n = DEAD.get(c[5:]); return ('dead_' + n) if n else None
    if c.startswith('str:') or len(c) != 1: return None
    return sym_name(L.xkb_utf32_to_keysym(ord(c)))

def sym_char(ks):
    u = L.xkb_keysym_to_utf32(ks)
    if u: return chr(u) if u >= 32 else None
    n = sym_name(ks)
    if n.startswith('dead_'): return 'dead:' + DEADNAME.get(n[5:], n[5:])
    return None

SHIFT, CAPS, RALT = 50, 66, 108                    # evdev + 8
_HOLD = {'base': [], 'shift': [SHIFT], 'caps': ['C'], 'capsshift': ['C', SHIFT], 'altgr': [RALT], 'shiftaltgr': [RALT, SHIFT]}

class Keymap:
    def __init__(self, ctx, layout, variant='', options=''):
        self.ctx = ctx
        self.km = L.xkb_keymap_new_from_names(ctx, ctypes.byref(_Names(b"evdev", b"pc105", layout.encode(),
                                                                       variant.encode(), options.encode())), 0)
        self.comp = L.xkb_compose_table_new_from_locale(ctx, b"en_US.UTF-8", 0)
    def ok(self): return bool(self.km)
    def code(self, key): return L.xkb_keymap_key_by_name(self.km, key.encode())
    def levels(self, key):
        """keysym names per shift level of group 1 ('NoSymbol' when empty)"""
        kc = self.code(key); out = []
        for lv in range(L.xkb_keymap_num_levels_for_key(self.km, kc, 0)):
            p = ctypes.POINTER(ctypes.c_uint32)()
            n = L.xkb_keymap_key_get_syms_by_level(self.km, kc, 0, lv, ctypes.byref(p))
            out.append(sym_name(p[0]) if n >= 1 else 'NoSymbol')
        return out
    def press_sym(self, state, key):
        st = L.xkb_state_new(self.km)
        for k in _HOLD[state]:
            if k == 'C': L.xkb_state_update_key(st, CAPS, 1); L.xkb_state_update_key(st, CAPS, 0)
            else: L.xkb_state_update_key(st, k, 1)
        ks = L.xkb_state_key_get_one_sym(st, self.code(key)); L.xkb_state_unref(st)
        return ks
    def press(self, state, key): return sym_char(self.press_sym(state, key))
    def compose(self, deadsym, state2, key2):
        cs = L.xkb_compose_state_new(self.comp, 0)
        L.xkb_compose_state_feed(cs, deadsym); L.xkb_compose_state_feed(cs, self.press_sym(state2, key2))
        out = None
        if L.xkb_compose_state_get_status(cs) == 2:            # XKB_COMPOSE_COMPOSED
            L.xkb_compose_state_get_utf8(cs, _buf, 128); out = _buf.value.decode()
        L.xkb_compose_state_unref(cs)
        return out
    def __del__(self):
        if getattr(self, 'km', None): L.xkb_keymap_unref(self.km)

def compare(win, kb):
    """Every Windows cell (key x state) and accent sequence, typed on keymap kb.
    -> list of dicts {kind: key|accent, key, state, windows, linux}"""
    name, keys, trans = win
    diffs = []; cells = 0
    where = {}
    for k, ks in keys.items():
        for st in ('base', 'shift'):
            c = ks.get(st)
            if c and len(c) == 1: where.setdefault(c, (st, k))
    where[' '] = ('base', 'SPCE')                       # accent then Space gives the accent itself on Windows
    for k, ks in sorted(keys.items()):
        for st in STATES:
            w = ks.get(st)
            if w is None or w.startswith('str:'): continue
            cells += 1; x = kb.press(st, k)
            if x != w: diffs.append({'kind': 'deadkey' if w.startswith('dead:') else 'key', 'key': k, 'state': st, 'windows': w, 'linux': x})
    for k, ks in sorted(keys.items()):
        for st in STATES:
            w = ks.get(st)
            if not (w or '').startswith('dead:'): continue
            if st in ('caps', 'capsshift') and ks.get('base' if st == 'caps' else 'shift') == w: continue  # same as base/shift
            ks_lin = kb.press_sym(st, k)
            for fr, to in sorted(trans.items()):
                if len(fr) != 2 or fr[0] != w[5:] or fr[1] not in where: continue
                cells += 1
                got = kb.compose(ks_lin, *where[fr[1]]) if (sym_char(ks_lin) or '').startswith('dead:') else None
                if got != to: diffs.append({'kind': 'accent', 'key': k, 'state': st, 'then': fr[1], 'windows': to, 'linux': got})
    return cells, diffs

def compose_table_from_text(text):
    """A compose table from the text of a Compose file (like ~/.XCompose; include "%L" loads the system table)."""
    b = text.encode()
    t = L.xkb_compose_table_new_from_buffer(L.xkb_context_new(0), b, len(b), b"en_US.UTF-8", 1, 0)
    if not t: raise ValueError('compose text does not load')
    return t

_comp_ctx = None
def compose_syms(deadsym, sym2):
    """Compose result (en_US.UTF-8 table) of dead key keysym then keysym, or None."""
    global _comp_ctx
    if _comp_ctx is None: _comp_ctx = L.xkb_compose_table_new_from_locale(L.xkb_context_new(0), b"en_US.UTF-8", 0)
    cs = L.xkb_compose_state_new(_comp_ctx, 0)
    L.xkb_compose_state_feed(cs, deadsym); L.xkb_compose_state_feed(cs, sym2)
    out = None
    if L.xkb_compose_state_get_status(cs) == 2:
        L.xkb_compose_state_get_utf8(cs, _buf, 128); out = _buf.value.decode()
    L.xkb_compose_state_unref(cs)
    return out
