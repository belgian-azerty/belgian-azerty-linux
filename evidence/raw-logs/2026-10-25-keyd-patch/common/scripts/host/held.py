#!/usr/bin/env python3
"""held.py VM KEY [KEY...]: hold left Ctrl + left Alt, tap each QEMU key (70 ms down, 150 ms apart), release."""
import sys, time
sys.path.insert(0, __import__("os").path.dirname(__file__))
from swaptest import Typist

t = Typist(sys.argv[1])
t.send("ctrl", True); time.sleep(0.03); t.send("alt", True); time.sleep(0.05)
for k in sys.argv[2:]:
    t.send(k, True); time.sleep(0.07); t.send(k, False); time.sleep(0.15)
t.send("alt", False); time.sleep(0.02); t.send("ctrl", False)
print("sent Ctrl+Alt held +", " ".join(sys.argv[2:]))
