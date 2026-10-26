#!/usr/bin/env python3
"""waitchange.py VM REF.png OUT.png [max_s]: wait until the screen differs from REF in >5% of pixels, then settle.py."""
import sys, time, subprocess, os
from PIL import Image, ImageChops
vm, ref, out = sys.argv[1], sys.argv[2], os.path.abspath(sys.argv[3]); mx = float(sys.argv[4]) if len(sys.argv) > 4 else 1200; th = float(sys.argv[5]) if len(sys.argv) > 5 else 0.05
here = os.path.dirname(os.path.abspath(__file__)); t0 = time.time(); r = Image.open(ref).convert("L")
while time.time() - t0 < mx:
    subprocess.run(["python3", os.path.join(here, "qemu_rig.py"), "shot", vm, out], capture_output=True)
    im = Image.open(out).convert("L")
    if im.size != r.size or sum(1 for v in ImageChops.difference(r, im).point(lambda v: 255 if v > 30 else 0).getdata() if v) > th * im.size[0] * im.size[1]:
        print(f"changed after {time.time()-t0:.0f}s", flush=True)
        subprocess.run(["python3", os.path.join(here, "settle.py"), vm, out, str(max(60, mx - (time.time() - t0))), "20"], stderr=subprocess.DEVNULL)
        sys.exit(0)
    time.sleep(15)
print("no change"); 
