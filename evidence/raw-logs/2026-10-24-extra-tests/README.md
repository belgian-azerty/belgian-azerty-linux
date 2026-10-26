# Extra tests before go/no-go (2026-10-24/25)

Approved by Younes 2026-10-24 20:33Z ("Lets follow your suggestion"). Thread "Run the three extra tests before go/no-go".
Packages and ISO tool unchanged (0.9.3 debs: belgian-azerty-windows 62ddfe6a…, keyd-belgian-windows 7f3c7024…, keyd 4067e4cd…).

1. Full system update, then suspend and resume; the Windows profile must still hold.
2. Boot of the stick image written byte for byte (dd), BIOS and UEFI.
3. Ctrl+Alt in Firefox and an Electron app (VS Code).
Extra (Younes 21:39Z): does installed stock Zorin open the overview on Super too? Pointer with keyd on installed systems.

Where: Mint in cloud QEMU (TCG, no KVM, slow). Zorin on the laptop rig (QEMU+KVM in WSL), Younes's card 22:57Z.

## Key sequence used everywhere (guest-scripts/seq.txt)

Ctrl+Alt on 1 2 3 4 5 6 9 0 E [ ] < , space, the same keys with AltGr, space, Caps Lock 1 2 Caps Lock, space, 1 2.
QEMU key names are US positions, sent as raw scancodes. Expected text, literally:

```
|@#{[^{}€[]\ |@#{[^{}€[]\ 12 &é
```

(`12` with Caps Lock on = Windows-style Caps Lock; `&é` without.)

## Results

| Test | Distro, how | Result | Literal output / file |
|---|---|---|---|
| 2 dd boot UEFI | Mint, 16 GB raw image dd'd from the stick ISO, OVMF | PASS: GRUB menu B, Nederlands > Period, live desktop, `be-azerty-fix check` 14 ✔ 0 ✘ | `|@#{[^{}€[]\ |@#{[^{}€[]\ 12 &é` mint/mint-dd-uefi-terminal.txt, -probe.txt, dd-boot/*.png |
| 2 dd boot BIOS | Mint, fresh dd copy, SeaBIOS | PASS: isolinux menu, default entry ran by itself (locale=nl_BE belgian.keyboard=be belgian.decimal=period), check 14 ✔ 0 ✘ | `|@#{[^{}€[]\ |@#{[^{}€[]\ 12 &é` mint/mint-dd-bios-terminal.txt, -probe.txt |
| 3 Firefox | Mint, stock Firefox, test page ff.html, 0.3 s per key | Symbols all right; plain-key tail reordered by ibus under load | `|@#{[^{}€[]\ |@#{[^{}€[]\ 1é2 &` mint/mint-ff-1.txt |
| 3 Firefox | same, 0.8 s per key, plus address bar | PASS | `|@#{[^{}€[]\ |@#{[^{}€[]\ 12 &é @€`, address bar `@€{}\` mint/mint-ff-2.txt |
| 3 Firefox shortcut | Ctrl + physical A key (= Belgian Q) | Firefox quit: shortcuts follow the Belgian letter, as on Windows | mint-firefox-run1-then-ctrlq-quits.png |
| 3 VS Code 1.143.1 | Mint, first run, 0.8 s, VS Code "not responding" under TCG | One Ctrl+Alt pair swapped (`{€}` for `{}€`) | mint/mint-vscode-1.txt |
| 3 VS Code | clean relaunch (--disable-extensions), 1.5 s and 0.5 s | PASS both | mint/mint-vscode-3.txt, -4.txt |
| 3 VS Code shortcut | Ctrl + physical Q key (= Belgian A) then x | Text replaced by `x`: select-all follows the Belgian letter | mint/mint-vscode-5-selectall.txt |
| 1 update (live) | Mint live, 590 packages | NOT POSSIBLE: live overlay /cow is 4.9 GB RAM, full at package 577 ("Geen ruimte meer over") even with firmware and modules moved out. Emulator/live limit, not our packages | mint/mint-update-failed.log, mint-room.log |
| Install from the stick | Mint, automatic install (ubiquity --automatic, preseed nl_BE / be) from the dd stick, BIOS | PASS: stick hook installed our 3 packages into the target (apt rc=0, evdev diversion added); first start ran our one-time setup (all ✔, initramfs rebuilt; took ~23 min under TCG, Mint 22.3 uses dracut) | mint/mint-install.log, mint-inst-boot1.txt |
| Installed, first start | Mint, installed | PASS: check all ✔, typing exact | `|@#{[^{}€[]\ |@#{[^{}€[]\ 12 &é` mint/mint-inst-boot1-typed.txt |
| 1 Full update | Mint installed, `apt full-upgrade` | PASS: 472 upgraded + 32 new, rc 0. Includes keyboard-configuration + console-setup 1.226ubuntu1.1, Cinnamon 6.6.9, Muffin 6.6.3, kernel 7.0.0-38, Firefox 158. No newer xkb-data (2.41-2ubuntu1.1). /etc/default/keyboard kept caps:be_windows | mint/mint-inst-update.log, -upgradable.txt |
| 1 After reboot | Mint, kernel 7.0.0-38 | PASS: check all ✔; diversion of rules/evdev in place (our rule in evdev, not in evdev.distrib); `dpkg -V xkb-data keyboard-configuration` clean; keyd active + enabled | `|@#{[^{}€[]\ |@#{[^{}€[]\ 12 &é` mint/mint-inst-after-update*.txt |
| 1 Suspend/resume, virtio-vga | Mint | Emulator display stayed "not active" after wake and the guest did not answer (no upload); powered off. Same as on Zorin; emulator display issue, not our packages | mint/mint-installed-resume-virtio-vga-display-inactive.png |
| 1 Suspend/resume, std VGA | Mint | PASS: `PM: suspend entry (deep)` / `Waking up from system sleep state S3` / `suspend exit`; lock screen unlocked by typing the password (after a wrong try with Caps Lock on/off in the field); check all ✔, keyd active; pointer clicks work (first click right after unlock was ignored once) | `|@#{[^{}€[]\ |@#{[^{}€[]\ 12 &é aAé2ù%` mint/mint-inst-after-resume*.txt |
| Caps after lock screen | Mint X11 (cinnamon-screensaver) | No desync: after toggling Caps in the password field, a A é 2 ù % correct | same file |
| 1–3 Zorin | laptop rig, 0.9.3 | UEFI + BIOS boots, Brave, VS Code, install, update (413 + 39), reboot, suspend/resume (std VGA) all PASS; Firefox not tested (Terms of Use dialog). Caps Lock finding on Wayland, see zorin/README.md | zorin/README.md |
| Super key | Zorin installed, ours and stock | Opens the Activities overview on both; super-hotkey=false, overlay-key='Super_L'. Stock behaviour, let go per Younes 21:39Z | zorin/README.md, super-key/zorin-super-hotkey-static.txt |

## Notes

- The swapped/reordered cases only happen when the emulator is overloaded (VS Code "not responding", 0.3 s bursts). It is the known ibus fast-typing reorder (research/FAST-TYPING-SWAPS.md), not a wrong symbol. Every symbol itself was right in every run.
- casper adds a third partition (13.1 GB ext4, /var/log persistence) to a writable dd stick on first live boot. Stock casper behaviour. dd-boot/casper-change.txt.
- The stick build is not byte-reproducible (hashes differ per build) while the debs inside are identical. dd-boot/stick-sha256.txt.
- Mint UEFI GRUB has no countdown; stock Mint the same.
- Cinnamon crashed once (llvmpipe segfault under TCG, 10 GB VM); restarted with LP_NUM_THREADS=0. Emulator only.

## Files

- Packages on every tested system: 0.9.3 (from the stick); 0.9.4/0.9.4.1 was not put on these systems.
- Pointer: the QEMU tablet is a weak stand-in for a real touchpad; it only shows that keyd does not take the pointer away.
- guest-scripts/: helpers run inside the guests (t.sh typing capture, p.sh probe, ff.html Firefox page, settings.json VS Code, upg.sh live update, upg2.sh installed update, room.sh, inst.sh + mint.preseed automatic install, password masked).
- mint/, zorin/, dd-boot/, super-key/.
