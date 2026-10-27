# Real-hardware test from a live USB: fast typing and the € in VS Code

This test checks two things on a real laptop: whether fast Ctrl+Alt typing swaps characters more often with this
project than without it, and whether VS Code drops the € of Ctrl+Alt+E. Everything runs from a live USB stick:
nothing is installed on the laptop's disk, and Windows is not touched. It takes about 30 minutes; your part is typing
short lines.

It was run once, on 24 October 2026, on a Lenovo ThinkPad T14s with test build 0.9.1 (Zorin OS 18.1 live session,
first X11, then Wayland). The result and a line-by-line reading are in `evidence/t14s/` (`READING.md`). The script was
written for that build and was not run again with 0.9.7.

## Why this test

In the emulator, two characters typed quickly one after the other sometimes arrived in the wrong order (`@€` became
`€@`), and VS Code sometimes dropped the € of Ctrl+Alt+E. The checks before this test showed:

- it never happened with the ibus input method stopped;
- it also happened on stock Linux, without this project (Zorin on Wayland, AltGr, 4 of 5 lines);
- with this project's Ctrl+Alt rules (keyd) it happened more often, because each Ctrl+Alt+key reached the desktop as
  a burst of about eight key events (Ctrl and Alt released, AltGr pressed, the key, then Ctrl and Alt pressed again).
  The keyd patch of 0.9.4, made after this test, brings that down to 2 events per character (HOW-WE-TESTED.md, "The keyd
  patch");
- the cloud emulator runs about 20 times slower than a real laptop, so the problem might be much rarer, or absent,
  at real speed.

Only a real machine answers the question: **at normal typing speed, does it happen, and is it worse with this
project's packages than without them?**

## What you need

- A USB stick of 8 GB or more (it will be erased).
- A Belgian Zorin OS 18.1 ISO, built with `tools/make_belgian_iso.sh` from the official Zorin OS 18.1 Core ISO (see
  `dist/sticks/REBUILD.md`). Below it is called `zorin-belgian.iso`.
- The folder `t14s-test`, with `run-test.sh` and `README.txt` from this repository, plus the three packages from
  `dist/` (`keyd_…deb`, `keyd-belgian-windows_…deb`, `belgian-azerty-windows_…deb`) and `be-azerty-fix.sh` from the
  top of the repository. If the folder also holds a `SHA256SUMS` file for these files, the script checks them with it.
- On Windows: Rufus (rufus.ie), or another tool that writes ISO images.

No BIOS change is needed for this test. (On a PC with BitLocker, have the recovery key at hand before changing any
BIOS setting. The stick also starts with Secure Boot on, so Secure Boot never needs to be turned off.)

## Steps

**1. Make the stick (on Windows, 5 minutes).** Start Rufus, choose the stick and `zorin-belgian.iso`, and keep the
defaults (when Rufus asks, choose "ISO image mode", not "DD"). Start. When Rufus is done, copy the whole `t14s-test`
folder onto the stick, next to the other files.

**2. Start the laptop from the stick (3 minutes).** From Windows: Settings > System > Recovery > Advanced startup >
"Restart now", then "Use a device" and pick the USB stick. Or shut down, press the power button and tap the
boot-menu key (F12 on a ThinkPad) until the boot menu appears, then choose the USB stick. In the Zorin menu, take the
first entry. A disc check runs first ("Checking md5sums", about a minute; let it finish). The desktop comes up with the
Belgian keyboard. (Do not click "Install Zorin OS".) If the laptop refuses to start from USB, "USB boot" is disabled in the
BIOS (on a ThinkPad: F1 at power-on, Startup menu).

**3. Run the test (about 25 minutes).** Press Ctrl+Alt+T for a terminal and type:

```
bash /cdrom/t14s-test/run-test.sh
```

(If the `t14s-test` folder is on a second USB stick instead, the command is
`bash /media/zorin/*/t14s-test/run-test.sh`; open that stick once in Files if the path is not found. The results are
then written to that stick.)

Then follow what it says. In this order, it:

- checks the files, installs the three packages (in the live session only, nothing is written to the laptop's disk)
  and switches everything on;
- writes down the laptop's details (model, keyboard devices, kernel, session type, keyd and ibus state, versions);
- runs a one-line layout check: `azerty`, then Caps Lock on and the top row 1 to 0 (it must give `azerty1234567890`,
  the Windows-style Belgian Caps Lock);
- asks for four blocks of five short lines of `@€@€@€@€@€@€@€@€`, typed as fast as you normally type. Hold the
  modifier key(s) the whole time and press 2, E, 2, E … (eight pairs); do not type a literal 2 or E. (In the first
  run, the old wording "with Ctrl+Alt held, then 2 and E" was read as eight @ followed by the characters 2 and E.)
  The blocks are: A, Left Ctrl + Left Alt (what users will do); B, AltGr; C, AltGr with keyd stopped (stock Linux,
  for comparison); D, Left Ctrl + Left Alt with ibus stopped. The script stops and restarts keyd and ibus itself;
- VS Code (optional): it asks you to connect to Wi-Fi, or to type s to skip. It downloads VS Code and opens an empty
  file; you type five lines with Left Ctrl + Left Alt, save with Ctrl+S and close VS Code;
- switches the session to Wayland: the screen goes black and comes back, a terminal opens by itself and the test
  carries on (the same layout check, four blocks and VS Code);
- writes the results file and lists every anomaly it noticed.

If you need to stop in the middle, press Ctrl+C (keyd and ibus are switched back on by themselves) and run the same
command again later: it carries on where it stopped. `bash /cdrom/t14s-test/run-test.sh --restart` starts from zero.

**4. Keep the result.** At the end the script says where `belgian-t14s-results.txt` is: on the live desktop and on
the stick, in `t14s-test`. Shut down, start Windows, open the stick, folder `t14s-test`, and take that one file. It
is plain text, with no screenshots. If the script says the stick could not be written, save the file from the live
desktop somewhere else before you shut down (a live session forgets everything). The script's last message still
says to send the file "to the thread", which is how the result came back in the first run; send it with your test
report instead.

## How the result is read

Each block line in the result says in how many of the 5 lines everything was right, and separately how many had
swapped order, a dropped or doubled key, or other characters (a shortcut that did not give @ or €). The summary at
the end lists the anomalies.

| Result | Meaning | What was planned next (before the first run) |
|---|---|---|
| A, B, C all 5/5 on Xorg and Wayland | The swap is an emulator artefact at real speed | Release with the known-issue note in the README; no change |
| A worse than C (keyd on worse than stock) | The package makes it worse in real use | No release until fixed: try keyd variants that space the events, or a per-app ibus setting (VS Code) |
| A and C about equal, both with errors | A stock Linux problem (ibus), not this project's | Release with the README note; report to ibus and GNOME with this evidence |
| D 5/5 while A has errors | Confirms ibus as the cause | Same as the row that applies above |
| Only VS Code loses € | Electron + ibus | README note; a per-app setting for VS Code documented as an option |

Dropped or doubled keys are counted separately from order errors, so they do not spoil the result. On Wayland, the
desktop may start ibus again by itself before block D; the result then says so, and that block counts as a second A.

## Not part of this test

- The whole-desktop freeze seen once in the emulator after setting `IBUS_ENABLE_SYNC_MODE=1` for the whole system:
  that setting is **not** shipped and is not used here.
- Installing anything on the laptop's disk.

## Dry runs in the emulator (24 October 2026)

- During the second review: from a read-only FAT stick image next to the ISO. The review found two problems, both
  fixed before the real run: blocks of 24 lines instead of 5 with no safe way to stop (Ctrl+C); and packages missing
  from the folder, VS Code tested only on Wayland, and no advice for PCs with BitLocker.
- After the fixes: from a stick image made like Rufus's ISO mode (FAT32, the ISO's files plus `t14s-test` copied onto
  it), started under UEFI with Secure Boot on, with the earlier two-script version (kept in
  `evidence/raw-logs/fix-round-2/t14s-dryrun/old-two-script-version/`). This found that the stick at /cdrom is
  read-only and owned by root (fixed). Results: `evidence/raw-logs/fix-round-2/t14s-dryrun/`.
- The one-command version: the same stick image, UEFI without Secure Boot, Xorg then Wayland with the automatic
  resume. Results: `evidence/raw-logs/fix-round-2/t14s-dryrun/one-command/`.
