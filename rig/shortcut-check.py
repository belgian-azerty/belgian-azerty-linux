#!/usr/bin/env python3
"""shortcut-check.py VM STEP: hold left Ctrl + left Alt, tap the keys of STEP, release. Used to check that a keyd build
which keeps AltGr down between symbols still gives a following Ctrl+Alt shortcut its real Ctrl+Alt:
  right  -> 2 then Right  (@, then Ctrl+Alt+Right: next workspace on GNOME/Cinnamon)
  left   -> e then Left   (€, then Ctrl+Alt+Left: previous workspace)
  term   -> 2 then t      (@, then Ctrl+Alt+T: opens a terminal)
  sym    -> 2 e 2 e       (@€@€ only)
Take a screenshot (and keep a kernel key log in the guest) between steps to see what the desktop did."""
import sys, time
sys.path.insert(0, __import__("os").path.dirname(__file__))
from swaptest import Typist

STEPS = {"right": ["2", "right"], "left": ["e", "left"], "term": ["2", "t"], "sym": ["2", "e", "2", "e"]}
t = Typist(sys.argv[1])
t.send("ctrl", True); time.sleep(0.03); t.send("alt", True); time.sleep(0.05)
for k in STEPS[sys.argv[2]]:
    t.send(k, True); time.sleep(0.07); t.send(k, False); time.sleep(0.15)
t.send("alt", False); time.sleep(0.02); t.send("ctrl", False)
print("sent Ctrl+Alt +", " ".join(STEPS[sys.argv[2]]))
