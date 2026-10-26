# Zorin 18.1 in VirtualBox on the T14s (2026-10-25 ~11:48-12:20Z), summary

Thread "Test Zorin in VirtualBox on the laptop". Younes's go: 11:41Z ("You may test zorin in virtual box on my computer
Yes"), card 11:45Z "Build it on the laptop", "go" 11:48Z, "A" 11:56Z (build-tool workaround below).
Copied from the laptop session's report. The RAW FILES (build.log, tools-wsl.diff, content/, shots/, uploads/, VBox.log,
showvminfo, commands, README.txt) are in the LAPTOP folder `evidence\raw-logs\2026-10-25-zorin-vbox\`, untracked,
not yet in this cloud folder: the next mirror must copy them here. Verify against those files.

## Image tested: a LOCAL REBUILD of the 0.9.4.1 Zorin stick, not the published image
- The published image (6553975b7b6601cc98199d7b4536e0e779f89453bbf7cf91b2aca1d164dc4549) existed only on a finished cloud
  thread's scratch disk; it could not be copied.
- Rebuilt in WSL on the laptop: `MENU=b PACKAGES=dist tools/make_belgian_iso.sh` from the stock Zorin 18.1 Core ISO
  44649b97bd307fc4c8529205d098ebbf98575a1e1ba2ee7d7005b697af1721d5 (verified), kit zvb-kit.tgz
  3d5b5e68bc05f8bb865be4ca53de24d1c41b7670bda23234a68548ff64b0b233 (copy in <project>-zorin-vbox-kit/;
  tool files unchanged since 2026-10-24 17:42Z, i.e. the same as for the cloud build at 02:55Z).
- Laptop stick sha256 8c0e89c5e4bda5968f6491ab6c49e96d3f3e2229d7452be6c341ba9567f22fac (3,915,448,320 bytes, the same
  size as the cloud stick). Hashes differ because mksquashfs and xorriso record the build time.
- Content check: the three debs in /belgian/ match 33321c63… (belgian-azerty-windows 0.9.4.1), 7343a82c…
  (keyd-belgian-windows 0.9.4.1), 946cc443… (keyd 2.5.0-5~ubuntu24.04.2); 12 boot entries patched; md5sum.txt self-check
  passed; layer listing, grub.cfg, md5sum.txt saved in content/.
- Workaround (Younes "A"): the laptop's WSL kernel 6.18.33.1-microsoft has no zstd squashfs (CONFIG_SQUASHFS_ZSTD not
  set; dmesg: Filesystem uses "zstd" compression), so build-layer.sh's `mount -o loop,ro filesystem.squashfs` fails.
  In a COPY (tools-wsl/), the lower dir is unpacked with `unsquashfs -q -d "$W/lower" "$SQ"` instead (2 lines,
  tools-wsl.diff). Kit and project tools unchanged. Same as LESSONS.md line ~402 already noted for the laptop.

## VirtualBox
7.2.10, Windows 11, VT-x unavailable (memory integrity on) -> Hyper-V/NEM ("Attempting fall back to NEM").
VM be-zorin-vbox: 4 GB, 2 vCPU, EFI, VMSVGA, PS/2 keyboard, NAT, DVD only, NO disk, no snapshots, no saved state.
Keys injected as raw PS/2 scancodes (rig/vbkeys.py, bypasses the Windows keyboard driver). Desktop stable ~6 min.

| Check | Expected | Got | Raw file (laptop) |
|---|---|---|---|
| Stick build (workaround A) | exit 0, 3 lines | exit 0, all 3 lines | build.log, tools-wsl.diff |
| Debs in /belgian/ | 3 hashes | 3 match | content/belgian-debs.sha256 |
| Boot menu (UEFI) | counts down, Nederlands + period | counted down, booted with no key | shots/b-boot-*, probe cmdline |
| Ctrl+Alt+T | terminal opens | opened, no click needed | shots/c0-terminal.png |
| keyd / packages | active; 0.9.4.1, 2.5.0-5~ubuntu24.04.2 | same | uploads/probe.txt |
| be-azerty-fix check | no cross | no cross | uploads/probe.txt |
| Session type | note | X11 (Zorin live session) | uploads/probe.txt |
| Terminal, seq.txt | `|@#{[^{}€[]\ |@#{[^{}€[]\ 12 &é` | exact, byte for byte | uploads/vbox-term(-od).txt |
| Plain letters | `azerty qwerty AZERTY é&ç` | exact | uploads/vbox-letters(-od).txt |
| GTK Text Editor, seq.txt | same line | exact (saved + uploaded) | uploads/vbox-gtk(-od).txt, shots/c7, c10 |
| Caps Lock on + a, off + a | `Aa` | `Aa` | uploads/vbox-caps(-od).txt |
| Pointer click | menu opens | NOT DONE | - |

Seq line = Ctrl+Alt 1 2 3 4 5 6 9 0 E [ ] < (Ctrl+Alt as AltGr), the same with AltGr, then Caps on + 1 2 (Windows Caps
gives 12), Caps off + 1 2 (&é).

## Unexpected / notes
1. Zstd squashfs not readable by the WSL kernel (above).
2. setxkbmap shows layout `be,us`; GNOME input source is be only; typing right. Same as the cloud QEMU run of the cloud
   stick (2026-10-25-sticks-0.9.4/zorin-0.9.4.1-uefi-default-probe.txt also shows `be,us`), so not VirtualBox-specific.
3. belgian-stick-live.service `inactive` though its log shows it ran at boot; the cloud probe also shows `inactive`
   (oneshot service, finished). Not checked further.
4. GNOME Text Editor menus in English in a Dutch session (translation of that app, not keyboard).
5. Pointer check not done: VBoxManage cannot click, and the computer-use request to click inside the VirtualBox window
   was declined at the approval prompt; no other route tried.

## Not covered
Wayland (Zorin's live session is X11), install from the stick, BIOS boot, physical typing by Younes (keys were
injected scancodes), VirtualBox older than 7.2.10, Guest Additions.

## Left on the laptop
`zvb\zorin-belgian-stick.iso` (3.9 GB, local rebuild, for a possible rerun) in the project folder, kept out of git by two
local lines in .git/info/exclude (`zvb/`, `belgian-azerty-zorin-vbox-kit/`). VM powered off and unregistered (it had no
disk). Servers 8020/8021 stopped. Nothing installed on Windows or in WSL. No commits. WSL scratch /root/be-rig/zvb/
(kit + tools-wsl copy; the WSL stick copy was deleted after the Windows copy was verified).
