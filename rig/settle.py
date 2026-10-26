#!/usr/bin/env python3
"""settle.py VM OUT.png [max_s] [interval_s]: wait until the guest screen stops changing (two shots
interval_s apart differ in <0.2% of pixels and the screen is not all black), then keep the last shot."""
import sys, time, subprocess, os
from PIL import Image, ImageChops
vm, out = sys.argv[1], os.path.abspath(sys.argv[2])
mx = float(sys.argv[3]) if len(sys.argv) > 3 else 900; iv = float(sys.argv[4]) if len(sys.argv) > 4 else 20
here = os.path.dirname(os.path.abspath(__file__)); t0 = time.time(); prev = None
while True:
    subprocess.run(["python3", os.path.join(here, "qemu_rig.py"), "shot", vm, out], capture_output=True)
    im = Image.open(out).convert("L")
    nonblack = sum(1 for v in im.getdata() if v > 20) / (im.size[0] * im.size[1])
    if prev is not None and prev.size == im.size and nonblack > 0.02:
        d = ImageChops.difference(prev, im).point(lambda v: 255 if v > 30 else 0)
        frac = sum(1 for v in d.getdata() if v) / (im.size[0] * im.size[1])
        if frac < 0.002:
            print(f"settled after {time.time()-t0:.0f}s size={im.size}"); break
    if time.time() - t0 > mx:
        print(f"timeout after {mx:.0f}s nonblack={nonblack:.2f}"); break
    prev = im; time.sleep(iv)
