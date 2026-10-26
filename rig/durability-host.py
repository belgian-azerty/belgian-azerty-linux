#!/usr/bin/env python3
"""Host side of serve/durability-guest.sh. Usage: durability-host.py VM [password]
Starts the guest script in the focused gnome-terminal, then for each up/dur-step-N signal types one probe line:
label | plain: azerty é | AltGr+2 e | LCtrl+LAlt+2 e. The guest closes the apps it opens, so the terminal keeps
the focus. Ends when up/dur-done appears; results in up/zi-zdur.txt."""
import os, sys, time, subprocess
HERE = os.path.dirname(os.path.abspath(__file__)); UP = os.path.join(HERE, "..", "up")
vm = sys.argv[1]; pw = sys.argv[2] if len(sys.argv) > 2 else "azerty"
def rig(*a): subprocess.run([sys.executable, os.path.join(HERE, "qemu_rig.py"), *a], check=True, stdout=subprocess.DEVNULL)
def typ(s): rig("type", vm, "--as", "be", s)
def keys(k): rig("keys", vm, k, "--delay", "0.3")
for f in os.listdir(UP):
    if f.startswith("dur-"): os.remove(os.path.join(UP, f))
typ("bash /tmp/durability-guest.sh\n"); time.sleep(4); typ(pw + "\n")
n, t0 = 1, time.time()
while True:
    if os.path.exists(os.path.join(UP, "dur-done")): print("guest finished"); break
    p = os.path.join(UP, f"dur-step-{n}")
    if not os.path.exists(p):
        if time.time() - t0 > 1800: sys.exit(f"timeout waiting for step {n}")
        time.sleep(2); continue
    time.sleep(1); label = open(p).read().strip(); print(f"step {n}: {label}", flush=True)
    typ(f"{label} | plain: azerty é | AltGr+2 e: "); keys("alt_r-2 alt_r-e")
    typ(" | LCtrl+LAlt+2 e: "); keys("ctrl-alt-2 ctrl-alt-e"); keys("ret")
    n += 1; t0 = time.time()
