"""Drive a VirtualBox VM's keyboard with raw PS/2 set-1 scancodes (bypasses every host keyboard driver).

  py vbkeys.py VM shot out.png
  py vbkeys.py VM type --as us "text"      press the physical keys a US typist would press
  py vbkeys.py VM type --as be "text"      press the physical keys a Belgian typist would press
  py vbkeys.py VM keys "lctrl+lalt+2" "ret" "ralt+e"   combos by US key name
"""
import subprocess, sys, time

VB = r"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

SC = {  # US-position key name -> set-1 make code (list of bytes)
    "esc": [0x01], "1": [0x02], "2": [0x03], "3": [0x04], "4": [0x05], "5": [0x06], "6": [0x07], "7": [0x08],
    "8": [0x09], "9": [0x0a], "0": [0x0b], "minus": [0x0c], "equal": [0x0d], "bksp": [0x0e], "tab": [0x0f],
    "q": [0x10], "w": [0x11], "e": [0x12], "r": [0x13], "t": [0x14], "y": [0x15], "u": [0x16], "i": [0x17],
    "o": [0x18], "p": [0x19], "lbracket": [0x1a], "rbracket": [0x1b], "ret": [0x1c], "lctrl": [0x1d],
    "a": [0x1e], "s": [0x1f], "d": [0x20], "f": [0x21], "g": [0x22], "h": [0x23], "j": [0x24], "k": [0x25],
    "l": [0x26], "semicolon": [0x27], "apostrophe": [0x28], "grave": [0x29], "lshift": [0x2a],
    "backslash": [0x2b], "z": [0x2c], "x": [0x2d], "c": [0x2e], "v": [0x2f], "b": [0x30], "n": [0x31],
    "m": [0x32], "comma": [0x33], "dot": [0x34], "slash": [0x35], "rshift": [0x36], "lalt": [0x38],
    "spc": [0x39], "caps": [0x3a], "less": [0x56],
    "f1": [0x3b], "f2": [0x3c], "f3": [0x3d], "f4": [0x3e], "f5": [0x3f], "f6": [0x40], "f7": [0x41],
    "f8": [0x42], "f9": [0x43], "f10": [0x44],
    "rctrl": [0xe0, 0x1d], "ralt": [0xe0, 0x38], "lwin": [0xe0, 0x5b],
    "up": [0xe0, 0x48], "down": [0xe0, 0x50], "left": [0xe0, 0x4b], "right": [0xe0, 0x4d],
    "home": [0xe0, 0x47], "end": [0xe0, 0x4f], "del": [0xe0, 0x53],
}

def brk(code):
    return code[:-1] + [code[-1] | 0x80]

# US typist: char -> combo
US = {c: c for c in "abcdefghijklmnopqrstuvwxyz0123456789"}
US.update({c.upper(): "lshift+" + c for c in "abcdefghijklmnopqrstuvwxyz"})
US.update({" ": "spc", "\n": "ret", "-": "minus", "=": "equal", "[": "lbracket", "]": "rbracket",
           ";": "semicolon", "'": "apostrophe", "`": "grave", "\\": "backslash", ",": "comma", ".": "dot",
           "/": "slash", "\t": "tab"})
for c, k in zip(")!@#$%^&*(", "0123456789"):
    US[c] = "lshift+" + k
US.update({"_": "lshift+minus", "+": "lshift+equal", "{": "lshift+lbracket", "}": "lshift+rbracket",
           ":": "lshift+semicolon", '"': "lshift+apostrophe", "~": "lshift+grave", "|": "lshift+backslash",
           "<": "lshift+comma", ">": "lshift+dot", "?": "lshift+slash"})

# Belgian typist (Linux "be"): char -> combo, by physical position
BE = {}
for c in "bcdefghijklnoprstuvxy":
    BE[c] = c
BE.update({"a": "q", "z": "w", "q": "a", "w": "z", "m": "semicolon"})
for c in list(BE):
    if c.isalpha():
        BE[c.upper()] = "lshift+" + BE[c]
for d, k in zip("1234567890", "1234567890"):
    BE[d] = "lshift+" + k
BE.update({"&": "1", "é": "2", '"': "3", "'": "4", "(": "5", "§": "6", "è": "7", "!": "8", "ç": "9", "à": "0",
           ")": "minus", "-": "equal", "°": "lshift+minus", "_": "lshift+equal",
           "$": "rbracket", "*": "lshift+rbracket", "ù": "apostrophe", "%": "lshift+apostrophe",
           "µ": "backslash", "£": "lshift+backslash", "<": "less", ">": "lshift+less",
           ",": "m", "?": "lshift+m", ";": "comma", ".": "lshift+comma", ":": "dot", "/": "lshift+dot",
           "=": "slash", "+": "lshift+slash", "²": "grave", " ": "spc", "\n": "ret",
           "|": "ralt+1", "@": "ralt+2", "#": "ralt+3", "{": "ralt+9", "}": "ralt+0", "€": "ralt+e",
           "[": "ralt+lbracket", "]": "ralt+rbracket", "\\": "ralt+less",
           "~": ["ralt+slash", "spc"]})

def combo_bytes(combo):
    parts = combo.split("+")
    seq = []
    for p in parts:
        seq += SC[p]
    for p in reversed(parts):
        seq += brk(SC[p])
    return seq

def send(vm, seq):
    for i in range(0, len(seq), 24):
        chunk = seq[i:i + 24]
        subprocess.run([VB, "controlvm", vm, "keyboardputscancode"] + ["%02x" % b for b in chunk], check=True,
                       stdout=subprocess.DEVNULL)

def main():
    vm, cmd, *rest = sys.argv[1:]
    if cmd == "shot":
        subprocess.run([VB, "controlvm", vm, "screenshotpng", rest[0]], check=True)
    elif cmd == "keys":
        for c in rest:
            send(vm, combo_bytes(c))
            time.sleep(0.08)
    elif cmd == "type":
        assert rest[0] == "--as"
        table = {"us": US, "be": BE}[rest[1]]
        for ch in rest[2]:
            combos = table[ch]
            for c in (combos if isinstance(combos, list) else [combos]):
                send(vm, combo_bytes(c))
            time.sleep(0.03)
    else:
        sys.exit(__doc__)

if __name__ == "__main__":
    main()
