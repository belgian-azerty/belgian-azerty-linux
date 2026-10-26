#!/usr/bin/env python3
"""Log every key event the guest kernel receives, from every keyboard device, to stdout.
Run as root:  python3 keylog.py > /tmp/keylog.txt
Shows exactly what VirtualBox delivered (a phantom LEFTCTRL next to RIGHTALT = Windows AltGr leak)."""
import os, re, select, struct, sys, time

NAMES = {1: "ESC", 2: "1", 3: "2", 4: "3", 5: "4", 6: "5", 7: "6", 8: "7", 9: "8", 10: "9", 11: "0", 12: "MINUS",
         13: "EQUAL", 14: "BKSP", 15: "TAB", 16: "Q", 17: "W", 18: "E", 19: "R", 20: "T", 21: "Y", 22: "U", 23: "I",
         24: "O", 25: "P", 26: "LBRACE", 27: "RBRACE", 28: "ENTER", 29: "LEFTCTRL", 30: "A", 31: "S", 32: "D", 33: "F",
         34: "G", 35: "H", 36: "J", 37: "K", 38: "L", 39: "SEMICOLON", 40: "APOSTROPHE", 41: "GRAVE", 42: "LEFTSHIFT",
         43: "BACKSLASH", 44: "Z", 45: "X", 46: "C", 47: "V", 48: "B", 49: "N", 50: "M", 51: "COMMA", 52: "DOT",
         53: "SLASH", 54: "RIGHTSHIFT", 56: "LEFTALT", 57: "SPACE", 58: "CAPSLOCK", 86: "102ND", 97: "RIGHTCTRL",
         100: "RIGHTALT", 125: "LEFTMETA", 126: "RIGHTMETA"}
FMT = "llHHi"
SZ = struct.calcsize(FMT)

def keyboards():
    devs = open("/proc/bus/input/devices").read().split("\n\n")
    out = {}
    for d in devs:
        name = re.search(r'N: Name="(.*)"', d)
        h = re.search(r"H: Handlers=(.*)", d)
        if not (name and h):
            continue
        ev = re.search(r"\bevent(\d+)\b", h.group(1))
        if ev and ("kbd" in h.group(1) or "keyd" in name.group(1).lower()):
            out["/dev/input/event" + ev.group(1)] = name.group(1)
    return out

fds = {}
for path, name in keyboards().items():
    try:
        fds[os.open(path, os.O_RDONLY | os.O_NONBLOCK)] = name
    except OSError as e:
        print("skip", path, e, flush=True)
print("watching:", ", ".join(sorted(set(fds.values()))), flush=True)
t0 = time.time()
while True:
    r, _, _ = select.select(list(fds), [], [], 1.0)
    for fd in r:
        data = os.read(fd, SZ * 64)
        for i in range(0, len(data), SZ):
            sec, usec, typ, code, val = struct.unpack(FMT, data[i:i + SZ])
            if typ == 1 and val in (0, 1):
                print("%8.3f %-28s %-11s %s" % (sec + usec / 1e6 - t0, fds[fd][:28], NAMES.get(code, code),
                                                 "down" if val else "up"), flush=True)
