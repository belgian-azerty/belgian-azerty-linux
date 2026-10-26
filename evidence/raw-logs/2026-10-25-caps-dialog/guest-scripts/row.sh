#!/bin/bash
# type the probe row: a A é 2 è 7 à 0 ù %   (physical keys q, 2, 7, 0, apostrophe; plain then Shift), then Enter
python3 <workdir>/work/rig/qemu_rig.py keys z "q shift-q spc 2 shift-2 spc 7 shift-7 spc 0 shift-0 spc apostrophe shift-apostrophe ret" --delay 0.6
