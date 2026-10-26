#!/usr/bin/env python3
"""Reset a running live VM and boot it from the GRUB command line with extra kernel parameters.

  boot_with_params.py VM "keyboard-configuration/layoutcode=be locale=fr_BE.UTF-8"

At the ISO's GRUB menu, `c` opens the GRUB shell (US keymap). The menu's default entry is
`linux /casper/vmlinuz --- quiet splash` + `initrd /casper/initrd`, so we retype it with the
extra parameters placed BEFORE the `---` separator (what follows `---` is copied to the installed
system by the installer; our live-only parameters should not be).
"""
import subprocess, time, sys
VM, PARAMS = sys.argv[1], sys.argv[2]
def rig(*a): return subprocess.run(["python3", "qemu_rig.py", *a], capture_output=True, text=True).stdout
def keys(s, d="0.4"): rig("keys", VM, s, "--delay", d)
def typ(text): rig("type", VM, text, "--as", "us", "--delay", "0.12")
def shot(n): rig("shot", VM, f"boot-{n}.png"); print("shot", f"boot-{n}.png", flush=True)

print(rig("hmp", VM, "system_reset"))
time.sleep(12); shot("1-grub-menu")
keys("c"); time.sleep(3); shot("2-grub-shell")
typ(f"linux /casper/vmlinuz {PARAMS} --- quiet splash\n"); time.sleep(8)
typ("initrd /casper/initrd\n"); time.sleep(15)
shot("3-grub-typed")
typ("boot\n"); time.sleep(5); shot("4-booting")
