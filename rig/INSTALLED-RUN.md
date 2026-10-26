# How the installed, encrypted Zorin test was run (test build 0.9.1, 24 October 2026)

This is the procedure that was followed for the test on an **installed, encrypted** Zorin OS 18.1: install from the
Belgian stick, reboot, the Belgian unlock prompt, login, the packages, another reboot, a typing probe, the durability
checks and a log out and in. It ran in QEMU with KVM inside WSL 2 on the test laptop (`RIG-SPEED.md`), and was the
last check the second review asked for before the 0.9.1 test build was accepted. The results are in
`evidence/raw-logs/installed-run-2026-10-24/`.

## Ground rules

- Nothing is installed on Windows. Inside WSL, `rig/wsl-setup.sh` installs only what is missing from
  `qemu-system-x86 qemu-utils python3-pil xorriso imagemagick`.
- One virtual machine at a time. If the laptop goes to sleep, stop and keep the disk image: the run can continue.
- Keep raw text logs; screenshots stay inside WSL (`/root/be-rig/shots/`).
- Below, `$R` is the folder that holds this repository (on Windows, seen from WSL as `/mnt/c/Users/<you>/...`).

## Steps

1. `wsl -d Ubuntu-24.04 -u root -- bash "$R/rig/wsl-setup.sh" zorin`
   (copies the scripts to `/root/be-rig/rig`, downloads and checks `Zorin-OS-18.1-Core-64-bit.iso`).
2. In WSL: `cd /root/be-rig && mkdir -p serve up shots && bash "$R/tools/make_belgian_iso.sh" iso/Zorin-OS-18.1-Core-64-bit.iso iso/zorin-belgian.iso`.
   It must end without an error (it checks `md5sum.txt` itself). Record `sha256sum iso/zorin-belgian.iso`.
3. Serve the files to the virtual machine: copy `$R/dist/*.deb`, `$R/be-azerty-fix.sh`, `$R/rig/kbstate.sh` and
   `$R/rig/durability-guest.sh` into `/root/be-rig/serve/`, and copy `keyd_2.5.0-5~ubuntu24.04.1_amd64.deb` (the keyd
   package of that test build) also as `keyd_backport_amd64.deb` (a `~` typed into the virtual machine is a dead key).
   Start `python3 -m http.server 8000 --bind 127.0.0.1 --directory /root/be-rig/serve &` and
   `python3 rig/upload_server.py /root/be-rig/up &` (port 8001).
   The virtual machine reaches them as `http://10.0.2.2:8000` and `:8001`.
4. `qemu-img create -f qcow2 zi.qcow2 40G`, then
   `python3 rig/qemu_rig.py start zi --iso iso/zorin-belgian.iso --disk zi.qcow2 --mem 6144 --smp 4 --cpu host --vga virtio`
   (BIOS boot, as in the first installed run). Use `shot`/`ocr` to see the screen and `type --as be` / `keys` /
   `click` to act on it.
5. Install from the live desktop ("Install Zorin OS"): note which keyboard layout the installer's keyboard page
   preselects (expected: Belgian). Choose "Erase disk", Advanced features: **LVM + encryption**, security key
   `azerty@é` typed with `type --as be`. User `test`, password `azerty`, no automatic login. Reboot when done
   (to eject the ISO, restart the virtual machine with `--disk zi.qcow2` only).
6. First boot: at the unlock prompt type `azerty@é` + Enter with `type --as be`, and record whether it unlocks at the
   first try. Log in at the login screen with `azerty` (the default session is Wayland). Open a terminal (Ctrl+Alt+T).
7. In the virtual machine: `cd /tmp && wget -q http://10.0.2.2:8000/{keyd_backport_amd64.deb,keyd-belgian-windows_0.9.1_all.deb,belgian-azerty-windows_0.9.1_all.deb,kbstate.sh,durability-guest.sh}`
   then `sudo apt-get install -y ./keyd_backport_amd64.deb ./keyd-belgian-windows_0.9.1_all.deb ./belgian-azerty-windows_0.9.1_all.deb`
   then `sudo be-azerty-fix system 2>&1 | tee /tmp/fix-system.log` (this rebuilds the initramfs). Upload logs with
   `wget -q --post-file=FILE http://10.0.2.2:8001/NAME -O /dev/null`. Check that
   `dpkg -s belgian-azerty-windows | grep Maintainer` says
   `Belgian AZERTY for Linux maintainers <linuxbelgiumkeyboard.rc0g4@aleeas.com>` (the Maintainer field of that test
   build).
8. Reboot the virtual machine. Unlock prompt again with `azerty@é` (now with the rebuilt initramfs), login, terminal.
9. Probe: `bash rig/short-probe.sh zi inst-after-reboot` (the terminal must have the focus; it needs
   `/tmp/kbstate.sh` in the virtual machine; result in `up/typed-inst-after-reboot.txt`).
   Expected: `azerty é`, AltGr 2 e `@€`, Ctrl+Alt 2 e `@€`, Caps row `²123°_%?.A` (Caps Lock acts like Shift on the
   main block except ² and <, as on Windows), numpad 1, decimal key, 5 gives `1.5` (press Num Lock first if it gives
   arrow codes).
10. Durability: `python3 rig/durability-host.py zi azerty` (guest script in `/tmp/durability-guest.sh`; results in
    `up/zi-zdur.txt`, about 15 minutes with KVM). Every line must show `azerty é | @€ | @€`, except C1 (keyd
    stopped: Ctrl+Alt gives `é`).
11. Log out (top-right menu), log in again with `azerty`, open a terminal, `bash rig/short-probe.sh zi inst-relogin`.
12. `sudo be-azerty-fix check | tee /tmp/check.log` and upload it.

## What was kept

Everything from `/root/be-rig/up/`, plus a short `run-notes.txt` (timings, sha256 of the Belgian ISO, what the
installer's keyboard page showed, the unlock result for each boot, anything unexpected, the exact commands), went
into `evidence/raw-logs/installed-run-2026-10-24/`. The disk image `zi.qcow2` stayed in WSL.
