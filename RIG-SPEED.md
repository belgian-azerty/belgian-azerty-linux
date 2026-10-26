# Test speed: cloud emulator compared with hardware acceleration (measured 23 October 2026)

Most tests of this project ran in QEMU virtual machines. This page compares the two places they ran, and explains
the setup of the faster one.

## Why the cloud emulator is slow

The cloud machine has no `/dev/kvm`, so QEMU emulates the whole processor in software (TCG). Everything inside the
virtual machine runs several times slower than on a normal PC. An install took more than an hour.

## Measured: same ISO, same virtual machine size, same scripts

Linux Mint 22.3 Cinnamon live ISO (sha256 a081ab20…, checked), 4 GB RAM, 4 virtual CPUs, `--vga virtio`, QEMU 8.2.2
in both places.

| | Cloud, software emulation (`--cpu Nehalem`) | Test laptop (Lenovo ThinkPad T14s), QEMU with KVM inside WSL 2 (`--cpu host`) |
|---|---|---|
| Cold boot to a stable Cinnamon desktop (including the ~10 s boot-menu countdown) | desktop at ~525 s, stable at ~555-570 s (**~9 min 15 s**) | **88 s** |
| Save the running desktop (`snap`, savevm) | 39 s, state file 3.8 GB | 11.8 s, state file 3.8 GB |
| Reload the saved desktop (`start ... --loadvm desktop`) | **18 s** (a later run with the final script: 32 s) | **15 s** |
| Still working after the reload (terminal, typed `echo ...`) | yes. Ctrl+Alt+T sent in the first seconds was lost; a click on the panel's terminal icon worked | yes. Ctrl+Alt+T worked; the screensaver had come on, and one Esc woke it (the snapshot was taken after 15 minutes idle) |

So the laptop boots about **6 times faster**. Every step inside the virtual machine also runs at hardware speed
there (typing, starting apps, shortcut checks, reboots), so an install should take roughly 10-15 minutes instead of
more than an hour. That install time is an **estimate**, not measured. A saved desktop reloads in 15-32 s in both
places; that helps in the cloud too, but everything after the reload still runs at emulator speed there.

The laptop's raw speed report and screenshots stay private, because they contain Windows paths; the numbers above
are copied from them. The cloud numbers come from a run of `rig/boottime.py`; its screenshots were not kept.

## The laptop setup

- Windows 11 with WSL 2 running Ubuntu 24.04. WSL 2 offers `/dev/kvm` (nested virtualisation), so QEMU inside it can
  use hardware acceleration.
- With Windows' Memory integrity (Core isolation) on, VirtualBox only gets the slower Hyper-V path ("fall back to
  NEM"). It does not stop WSL's KVM.
- Changed on the laptop: the WSL memory limit in `%UserProfile%\.wslconfig`, from 6 GB to 12 GB (a backup
  `.wslconfig.bak` was kept). QEMU 8.2.2, qemu-utils and python3-pil were installed **inside WSL Ubuntu only**. In
  WSL, `/root/be-rig/` holds `iso/` (the ISOs), `rig/` (a copy of the scripts) and the saved virtual machine states.
- To undo it: copy `.wslconfig.bak` back; in WSL, `apt-get remove -y qemu-system-x86 qemu-utils python3-pil` and
  `rm -rf /root/be-rig`.
- Limits: the laptop must be on and awake, and a running virtual machine uses 4-6 GB of the 12 GB WSL limit.

## Script changes (in `rig/`)

- `qemu_rig.py`: `--accel auto` (the default) uses KVM when `/dev/kvm` is usable, otherwise software emulation, so
  the same command works in the cloud and on the laptop. The machine type is pinned to `pc-q35-8.2` so that saved
  states stay loadable. New: `--state F.qcow2` (a hidden drive that stores the saved memory, so that live-ISO
  sessions can be saved), `--loadvm TAG` and `snap NAME TAG`. A saved state only works with exactly the same command
  line (same ISO file, memory, CPUs, CPU type, graphics, disks), so states cannot be moved between the cloud
  (`--cpu Nehalem`) and the laptop (`--cpu host`).
- `boottime.py VM OUTDIR [max_s] [interval_s]`: takes screenshots until the screen stops changing and prints the
  seconds. (The first version never stopped on Mint's dark wallpaper; its threshold was fixed after the measurement
  above.)
- `wsl-setup.sh [mint] [zorin]`: one command, run as root inside WSL. It installs what is missing, copies the
  scripts to `/root/be-rig/rig`, and downloads and checks the ISOs. It is safe to run again; run it at the start of
  every session, so that the copy in WSL matches the repository. Tested in the cloud with the KVM check bypassed
  (the cloud has no KVM): install path, copy, checksum skip and the error for an unknown ISO. The format of Zorin's
  checksum line was checked; the Zorin download itself was not run.
- `ci/boot-smoke.yml`: a **draft, never run**. GitHub's free Linux runners give `/dev/kvm` to **public**
  repositories (4 virtual CPUs, 16 GB, 14 GB disk). Private repositories get 2 virtual CPUs and 8 GB, and KVM is not
  documented there. It waits until the repository is public.

## How the tests were run after this

1. Heavy runs (installs, shortcut checks, durability, reboots, fast typing): on the laptop, QEMU with KVM in WSL.
2. Every run, cloud or laptop: boot once, `snap NAME desktop` right after the desktop appears (before the
   screensaver starts), then `--loadvm desktop` for each further test instead of booting again.
3. Cloud emulation only for short checks while the laptop was not available.
4. Later: GitHub Actions on the public repository for automatic boot-and-type checks (the draft above).

Not chosen: VirtualBox without a window on Windows. It only gets the Hyper-V path while Memory integrity is on, and
restoring a saved state froze a virtual machine there on 23 October; making it faster would mean switching off a
Windows security feature. QEMU with WHPX directly on Windows would also work, but it needs QEMU installed on Windows
and changes to the scripts, for no gain over WSL.
