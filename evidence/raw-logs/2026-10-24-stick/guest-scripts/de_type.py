#!/usr/bin/env python3
"""de_type.py VM "text": press the physical keys a German QWERTZ typist would (QEMU key names = US positions)."""
import subprocess, sys
vm, text = sys.argv[1], sys.argv[2]
M = {' ': 'spc', '.': 'dot', ':': 'shift-dot', '/': 'shift-7', '-': 'slash', '_': 'shift-slash', '>': 'shift-less',
     '<': 'less', '&': 'shift-6', '=': 'shift-0', '\n': 'ret', ',': 'comma', ';': 'shift-comma', '|': 'alt_r-less',
     '"': 'shift-2', "'": 'shift-backslash', '~': 'alt_r-bracket_right', '*': 'shift-bracket_right', '+': 'bracket_right'}
keys = []
for c in text:
    if c in M: keys.append(M[c])
    elif c.isdigit(): keys.append(c)
    elif c.isalpha():
        k = {'y': 'z', 'z': 'y'}.get(c.lower(), c.lower())
        keys.append(('shift-' if c.isupper() else '') + k)
    else: sys.exit('no German key for %r' % c)
subprocess.run(['python3', 'qemu_rig.py', 'keys', vm, ' '.join(keys), '--delay', '0.12'], check=True)
