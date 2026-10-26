#!/usr/bin/env python3
"""In a live desktop that is already up: open a terminal (Ctrl+Alt+T), print the layout the
session really has, then type a test string on Belgian key positions and screenshot the result.

  test_gui_layout.py VM TAG
"""
import subprocess, time, sys
VM, TAG = sys.argv[1], sys.argv[2]
def rig(*a): return subprocess.run(["python3", "qemu_rig.py", *a], capture_output=True, text=True).stdout
def keys(s, d="0.4"): rig("keys", VM, s, "--delay", d)
def typ(mode, text): rig("type", VM, text, "--as", mode, "--delay", "0.15")
def shot(n): rig("shot", VM, f"{TAG}-{n}.png"); print("shot", f"{TAG}-{n}.png", flush=True)

keys("ctrl-alt-t"); time.sleep(40); shot("1-terminal")
typ("us", "clear; setxkbmap -query; grep XKB /etc/default/keyboard; tr ' ' '\\n' </proc/cmdline | grep -E 'layout|locale'; gsettings get org.mate.peripherals-keyboard-xkb.kbd layouts 2>/dev/null\n")
time.sleep(12); shot("2-query")
typ("us", "echo BE-typed: "); typ("be", "azerty 123 é@#{}[]|\\~ \n"); time.sleep(6); shot("3-typed-as-be")
