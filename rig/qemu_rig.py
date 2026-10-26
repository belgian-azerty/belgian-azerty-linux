#!/usr/bin/env python3
"""Tiny QEMU test rig for keyboard-layout experiments.

Boots a live ISO headless, types through raw PS/2 scancodes (QEMU `sendkey`)
and reads the screen back as PNG. Because keys are injected below any host
keyboard driver, whatever the guest prints is decided by the guest alone.

  qemu_rig.py start  NAME --iso FILE [--mem 4096] [--smp 4] [--uefi] [--accel auto|kvm|tcg]
                     [--state vmstate.qcow2 [--loadvm TAG]]                        # resume a saved desktop
                     [--kernel vmlinuz --initrd initrd --append "boot=casper ..."]   # direct kernel boot
                     [--extra-cdrom fix.iso] [--disk disk.qcow2]
                     [--usb stick.img]                       # raw image as a USB stick (boots first)
                     [--uefi [--secboot]]                    # UEFI; --secboot: Secure Boot on, Microsoft keys
  qemu_rig.py shot   NAME OUT.png
  qemu_rig.py keys   NAME "ret ctrl-alt-t alt_r-2"   # QEMU key names, space separated
  qemu_rig.py type   NAME --as be|us "text"          # press the physical keys a BE/US typist would
  qemu_rig.py click  NAME X Y [--w 1280 --h 800] [-n 2] # absolute mouse click (hot-adds a USB tablet)
  qemu_rig.py hmp    NAME "info status"              # any human-monitor command
  qemu_rig.py ocr    NAME OUT.png                    # screenshot + tesseract text
  qemu_rig.py snap   NAME TAG                       # save the running VM (RAM + disks) under TAG
  qemu_rig.py stop   NAME

Snapshots: `--state F.qcow2` adds a hidden qcow2 drive (created if missing, invisible to the guest) that
holds the saved RAM, so a live-ISO session can be saved too. Boot once, `snap NAME desktop`, and later
`start ... --state F.qcow2 --loadvm desktop` comes back at the same desktop in seconds instead of minutes.
A snapshot only fits the exact same command line: same ISO file, --mem, --smp, --cpu, --vga, disks.
"""
import json, os, socket, subprocess, sys, time, argparse

RIG = os.path.dirname(os.path.abspath(__file__))
RUN = os.path.join(RIG, "run")


def paths(name):
    d = os.path.join(RUN, name)
    return d, os.path.join(d, "qmp.sock"), os.path.join(d, "pid"), os.path.join(d, "serial.log")


class QMP:
    def __init__(self, sock_path):
        self.s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.s.connect(sock_path)
        self.f = self.s.makefile("rwb", buffering=0)
        json.loads(self.f.readline())            # greeting
        self.cmd("qmp_capabilities")

    def cmd(self, name, **args):
        msg = {"execute": name}
        if args:
            msg["arguments"] = args
        self.f.write((json.dumps(msg) + "\n").encode())
        while True:
            line = json.loads(self.f.readline())
            if "event" in line:
                continue
            if "error" in line:
                raise RuntimeError(line["error"])
            return line.get("return")

    def hmp(self, text):
        return self.cmd("human-monitor-command", **{"command-line": text})


def start(a):
    d, sock, pid, serial = paths(a.name)
    os.makedirs(d, exist_ok=True)
    accel = a.accel
    if accel == "auto":   # hardware virtualisation when the host offers it, software emulation otherwise
        accel = "kvm" if os.access("/dev/kvm", os.R_OK | os.W_OK) else "tcg"
    cmd = ["qemu-system-x86_64", "-name", a.name,
           "-machine", "pc-q35-8.2" + (",smm=on" if a.secboot else ""), "-accel", accel, "-cpu", a.cpu, "-smp", str(a.smp), "-m", str(a.mem),
           *([] if a.usb else ["-boot", "d" if a.iso else "c"]),
           "-vga", a.vga, "-display", "none",
           "-usb", "-device", "usb-tablet",      # absolute pointer, so `click X Y` lands exactly
           "-serial", f"file:{serial}",
           "-qmp", f"unix:{sock},server,nowait",
           "-daemonize", "-pidfile", pid]
    if a.iso:
        cmd += ["-cdrom", a.iso]
    if a.secboot:   # like a real laptop: Secure Boot on with the Microsoft keys (shim + signed GRUB and kernel)
        vars_ = os.path.join(d, "OVMF_VARS.fd")
        if not os.path.exists(vars_):
            subprocess.check_call(["cp", "/usr/share/OVMF/OVMF_VARS_4M.ms.fd", vars_])
        cmd += ["-global", "driver=cfi.pflash01,property=secure,value=on",
                "-drive", "if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd",
                "-drive", f"if=pflash,format=raw,unit=1,file={vars_}"]
    elif a.uefi:
        cmd += ["-bios", "/usr/share/ovmf/OVMF.fd"]
    if a.usb:       # a USB stick (raw image, e.g. made like Rufus does), first in the boot order
        cmd += ["-device", "qemu-xhci,id=xhci", "-drive", f"if=none,id=usbstick,format=raw,file={os.path.abspath(a.usb)}",
                "-device", "usb-storage,bus=xhci.0,drive=usbstick,bootindex=0"]
    if a.kernel:   # direct kernel boot: deterministic kernel command line, no GRUB/isolinux editing
        cmd += ["-kernel", a.kernel, "-initrd", a.initrd, "-append", a.append]
    for extra in a.extra_cdrom:
        cmd += ["-drive", f"file={extra},media=cdrom,readonly=on"]
    for disk in a.disk:
        cmd += ["-drive", f"file={disk},format=qcow2,if=virtio"]
    if a.state:
        if not os.path.exists(a.state):
            subprocess.check_call(["qemu-img", "create", "-q", "-f", "qcow2", a.state, "1G"])
        cmd += ["-drive", f"file={os.path.abspath(a.state)},format=qcow2,if=none,id=vmstate"]
    if a.loadvm:
        cmd += ["-loadvm", a.loadvm]
    t0 = time.time()
    subprocess.check_call(cmd)
    print(f"started {a.name} ({accel}) in {time.time() - t0:.1f}s: pid {open(pid).read().strip()}, qmp {sock}")


def snap(a):
    _, sock, _, _ = paths(a.name)
    t0 = time.time()
    out = QMP(sock).hmp(f"savevm {a.tag}")
    if out:
        sys.exit(f"savevm failed: {out}")
    print(f"saved {a.name} as {a.tag} in {time.time() - t0:.1f}s")


def stop(a):
    d, sock, pid, _ = paths(a.name)
    try:
        QMP(sock).cmd("quit")
    except Exception as e:
        print("quit failed:", e)
        try:
            os.kill(int(open(pid).read()), 9)
        except Exception:
            pass
    print("stopped", a.name)


def shot(a, out=None):
    _, sock, _, _ = paths(a.name)
    out = os.path.abspath(out or a.out)   # QEMU daemonizes into /, so relative paths land there
    q = QMP(sock)
    try:
        q.cmd("screendump", filename=out, format="png")
    except RuntimeError:
        ppm = out + ".ppm"
        q.cmd("screendump", filename=ppm)
        subprocess.check_call(["convert", ppm, out])
        os.remove(ppm)
    time.sleep(0.3)
    print("screenshot", out)
    return out


def keys(a, seq=None, delay=None):
    _, sock, _, _ = paths(a.name)
    q = QMP(sock)
    seq = seq if seq is not None else a.seq.split()
    delay = delay if delay is not None else a.delay
    for k in seq:
        q.hmp(f"sendkey {k}")
        time.sleep(delay)


# Which QEMU key (named after the US legend of that physical key) a typist presses
# for a character, on a Belgian keyboard vs a US keyboard. Only the characters we
# need for tests. QEMU key names: 0-9, a-z, minus, equal, bracket_left, bracket_right,
# semicolon, apostrophe, grave_accent, backslash, comma, dot, slash, less, spc, ret.
BE = {}
for ch, key in zip("azertyuiop", "qwertyuiop"): BE[ch] = key
for ch, key in zip("qsdfghjklm", "asdfghjkl;"): BE[ch] = key.replace(";", "semicolon")
for ch, key in zip("wxcvbn", "zxcvbn"): BE[ch] = key
for ch, key in zip("&é\"'(§è!çà", "1234567890"): BE[ch] = key
for ch, key in zip("1234567890", "1234567890"): BE[ch] = "shift-" + key
BE.update({
    ")": "minus", "°": "shift-minus", "-": "equal", "_": "shift-equal",
    "^": "bracket_left", "$": "bracket_right", "*": "shift-bracket_right",
    "ù": "apostrophe", "%": "shift-apostrophe", "µ": "backslash", "£": "shift-backslash",
    ",": "comma", "?": "shift-comma", ";": "dot", ".": "shift-dot", ":": "slash", "/": "shift-slash",
    "=": "equal" if False else "slash",  # placeholder, fixed below
    "<": "less", ">": "shift-less", "²": "grave_accent", "³": "shift-grave_accent",
    " ": "spc", "\n": "ret",
    # AltGr (right Alt) symbols
    "|": "alt_r-1", "@": "alt_r-2", "#": "alt_r-3", "{": "alt_r-9", "}": "alt_r-0",
    "[": "alt_r-bracket_left", "]": "alt_r-bracket_right", "\\": "alt_r-less",
    "~": "alt_r-slash", "€": "alt_r-e",
})
# On a Belgian keyboard the key right of ù/% ... is  = / + (AB10 is the key right of :/ ).
# Physical layout bottom row: w x c v b n , ; : =   -> QEMU names z x c v b n comma dot slash  (= is on slash's right)
# QEMU has no separate name for AB10 on a 102-key layout; it is the US "slash" key? No:
# US bottom row: z x c v b n , . /   (9 keys)   BE bottom row: w x c v b n , ; : =  (10 keys)
# BE's ',' sits on US 'm', ';' on US ',', ':' on US '.', '=' on US '/'.
BE[","] = "m"; BE["?"] = "shift-m"; BE[";"] = "comma"; BE["."] = "shift-comma"
BE[":"] = "dot"; BE["/"] = "shift-dot"; BE["="] = "slash"; BE["+"] = "shift-slash"; BE["~"] = "alt_r-slash"
for ch in "AZERTYUIOPQSDFGHJKLMWXCVBN":
    BE[ch] = "shift-" + BE[ch.lower()]

US = {}
for ch in "abcdefghijklmnopqrstuvwxyz0123456789":
    US[ch] = ch
for ch in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
    US[ch] = "shift-" + ch.lower()
US.update({"-": "minus", "=": "equal", "[": "bracket_left", "]": "bracket_right", ";": "semicolon",
           "'": "apostrophe", "`": "grave_accent", "\\": "backslash", ",": "comma", ".": "dot",
           "/": "slash", " ": "spc", "\n": "ret", "_": "shift-minus", "+": "shift-equal",
           "{": "shift-bracket_left", "}": "shift-bracket_right", ":": "shift-semicolon",
           "\"": "shift-apostrophe", "~": "shift-grave_accent", "|": "shift-backslash",
           "<": "shift-comma", ">": "shift-dot", "?": "shift-slash", "!": "shift-1", "@": "shift-2",
           "#": "shift-3", "$": "shift-4", "%": "shift-5", "^": "shift-6", "&": "shift-7",
           "*": "shift-8", "(": "shift-9", ")": "shift-0"})


def type_text(a):
    table = BE if a.as_ == "be" else US
    seq = []
    for ch in a.text:
        if ch not in table:
            sys.exit(f"no key for {ch!r} in {a.as_} table")
        seq.append(table[ch])
    keys(a, seq, a.delay)


def ocr(a):
    out = shot(a, a.out)
    txt = subprocess.run(["tesseract", out, "-", "--psm", "6"], capture_output=True, text=True).stdout
    print(txt)


def _shot_img(q, path):
    try:
        q.cmd("screendump", filename=path, format="png")
    except RuntimeError:
        q.cmd("screendump", filename=path + ".ppm"); subprocess.check_call(["convert", path + ".ppm", path])
    time.sleep(0.3)
    from PIL import Image
    return Image.open(path).convert("RGB")


def _cursor_pos(before, after, ignore=64):
    """Top-left corner of what changed between two screenshots (the arrow's tip), ignoring the home corner."""
    from PIL import ImageChops
    d = ImageChops.difference(before, after).convert("L").point(lambda v: 255 if v > 40 else 0)
    px = d.load(); W, H = d.size
    best = None
    for y in range(H):
        for x in range(W):
            if px[x, y] and not (x < ignore and y < ignore):
                if best is None or (y, x) < best:
                    best = (y, x)
                break
        if best is not None and y > best[0] + 2:
            break
    return None if best is None else (best[1], best[0])


def _rel_move(q, dx, dy, step=40):
    while dx or dy:
        sx = max(-step, min(step, dx)); sy = max(-step, min(step, dy))
        q.hmp(f"mouse_move {sx} {sy}"); dx -= sx; dy -= sy
        time.sleep(0.12)


def click(a):
    """Click at pixel (x, y). With a USB tablet (start adds one) the move is absolute. Otherwise the
    PS/2 mouse is homed to the top-left corner and moved by trial: move, screenshot, find the arrow,
    correct, up to 5 rounds. Needs a still screen for the fallback."""
    _, sock, _, _ = paths(a.name)
    q = QMP(sock)
    tmp = os.path.join(RUN, a.name)
    try:
        X = int(a.x * 32767 / a.w); Y = int(a.y * 32767 / a.h)
        q.cmd("input-send-event", events=[{"type": "abs", "data": {"axis": "x", "value": X}},
                                          {"type": "abs", "data": {"axis": "y", "value": Y}}])
    except RuntimeError:
        for _ in range(3):
            q.hmp("mouse_move -4000 -4000"); time.sleep(0.2)
        base = _shot_img(q, os.path.join(tmp, "cur0.png"))
        req = [a.x, a.y]
        for i in range(5):
            _rel_move(q, req[0], req[1]); time.sleep(3)
            got = _cursor_pos(base, _shot_img(q, os.path.join(tmp, "cur1.png")))
            if got is None:
                print("cursor not found; assuming it landed"); break
            ex, ey = a.x - got[0], a.y - got[1]
            print(f"round {i}: at {got}, error ({ex},{ey})")
            if abs(ex) <= 2 and abs(ey) <= 2:
                break
            req = [req[0] + ex, req[1] + ey]
            for _ in range(3):
                q.hmp("mouse_move -4000 -4000"); time.sleep(0.2)
    time.sleep(0.3)
    for _ in range(a.n):
        q.hmp("mouse_button 1"); time.sleep(0.1)
        q.hmp("mouse_button 0"); time.sleep(0.15)
    print("clicked", a.x, a.y)


def hmp(a):
    _, sock, _, _ = paths(a.name)
    print(QMP(sock).hmp(a.text))


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("start"); s.add_argument("name"); s.add_argument("--iso")  # omit to boot from --disk
    s.add_argument("--mem", type=int, default=4096); s.add_argument("--smp", type=int, default=4)
    s.add_argument("--uefi", action="store_true"); s.add_argument("--vga", default="std"); s.add_argument("--cpu", default="max")
    s.add_argument("--kernel"); s.add_argument("--initrd"); s.add_argument("--append", default="")
    s.add_argument("--extra-cdrom", action="append", default=[]); s.add_argument("--disk", action="append", default=[])
    s.add_argument("--accel", default="auto", choices=["auto", "kvm", "tcg"])
    s.add_argument("--usb"); s.add_argument("--secboot", action="store_true")
    s.add_argument("--state"); s.add_argument("--loadvm")
    s.set_defaults(fn=start)
    s = sub.add_parser("snap"); s.add_argument("name"); s.add_argument("tag"); s.set_defaults(fn=snap)
    s = sub.add_parser("stop"); s.add_argument("name"); s.set_defaults(fn=stop)
    s = sub.add_parser("shot"); s.add_argument("name"); s.add_argument("out"); s.set_defaults(fn=shot)
    s = sub.add_parser("ocr"); s.add_argument("name"); s.add_argument("out"); s.set_defaults(fn=ocr)
    s = sub.add_parser("keys"); s.add_argument("name"); s.add_argument("seq")
    s.add_argument("--delay", type=float, default=0.15); s.set_defaults(fn=keys)
    s = sub.add_parser("type"); s.add_argument("name"); s.add_argument("text")
    s.add_argument("--as", dest="as_", choices=["be", "us"], default="be")
    s.add_argument("--delay", type=float, default=0.12); s.set_defaults(fn=type_text)
    s = sub.add_parser("click"); s.add_argument("name"); s.add_argument("x", type=int); s.add_argument("y", type=int)
    s.add_argument("--w", type=int, default=1280); s.add_argument("--h", type=int, default=800)
    s.add_argument("--step", type=int, default=4); s.add_argument("-n", type=int, default=1); s.set_defaults(fn=click)
    s = sub.add_parser("hmp"); s.add_argument("name"); s.add_argument("text"); s.set_defaults(fn=hmp)
    a = p.parse_args()
    a.fn(a)
