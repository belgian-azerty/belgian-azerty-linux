#!/usr/bin/env python3
"""boottime.py VM OUTDIR [max_s] [interval_s]: screenshot every interval_s (default 15) (OUTDIR/t0123.png), stop once three shots in a row are
the same (<0.2% pixels differ) on a screen that is not a dark boot splash. Prints the elapsed seconds of the first of those shots."""
import sys, time, subprocess, os
from PIL import Image, ImageChops
vm, outdir = sys.argv[1], os.path.abspath(sys.argv[2]); mx = float(sys.argv[3]) if len(sys.argv) > 3 else 1500
iv = float(sys.argv[4]) if len(sys.argv) > 4 else 15
os.makedirs(outdir, exist_ok=True)
here = os.path.dirname(os.path.abspath(__file__)); t0 = time.time(); hist = []
while time.time() - t0 < mx:
    el = time.time() - t0; out = os.path.join(outdir, f"t{el:04.0f}.png")
    subprocess.run(["python3", os.path.join(here, "qemu_rig.py"), "shot", vm, out], capture_output=True)
    if os.path.exists(out):
        im = Image.open(out).convert("L"); im.thumbnail((640, 400))
        n = im.size[0] * im.size[1]
        bright = sum(im.histogram()[41:]) / n          # Mint's dark wallpaper scores ~0.27, a boot splash ~0.01
        same = bool(hist) and hist[-1][1].size == im.size and \
            ImageChops.difference(hist[-1][1], im).point(lambda v: 255 if v > 30 else 0).histogram()[255] < 0.002 * n
        hist = (hist + [(el, im)]) if same else [(el, im)]
        print(f"{el:5.0f}s bright={bright:.2f} same={same}", flush=True)
        if len(hist) >= 3 and bright > 0.15:
            print(f"STABLE since {hist[0][0]:.0f}s"); sys.exit(0)
    time.sleep(max(0, iv - (time.time() - t0 - el)))
print("TIMEOUT"); sys.exit(1)
