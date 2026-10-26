# VS Code with and without the ibus skip (laptop, 25 Oct 2026)

Question: does VS Code started with `GTK_IM_MODULE=gtk-im-context-simple` (what `be-azerty-fix ibus-skip on ...`
does) avoid the lost/extra € of fast Ctrl+Alt typing that stock VS Code shows with ibus?

**Answer: yes.** With the skip, all 73 very fast lines came out exactly right on Mint 22.3 and Zorin 18.1. With stock
ibus only 15 (Mint) and 20 (Zorin) of 73 were right; many Enter presses became an extra €.

- Where: laptop rig (QEMU + KVM in WSL 2 on the T14s), live sessions, X11, one pass per distro. Emulator, keys sent
  faster than people type; the counts compare the two settings, not real-world rates.
- Packages: release 0.9.6 from `dist/` at the time (belgian-azerty-windows a81642c5..., keyd-belgian-windows 0.9.6,
  keyd 2.5.0-5~ubuntu24.04.2). VS Code 1.143.1 (commit e646868), Microsoft's .deb from
  update.code.visualstudio.com, installed inside the live VMs only.
- Approved by Younes 2026-10-25 19:31Z ("Run it to see if it fixes").
- Runbook and guest script: `next-0.9.5/vscode-bundle/` (RUNBOOK-VSCODE.md, v.sh, measure-vsc.sh). The laptop used
  v2.sh = v.sh with the menu file name com.microsoft.VSCode.desktop (see the bug below).
- Files here: `SUMMARY.txt` (written by the thread after the run), `SCORES.txt` (the score and environment lines).
- Raw files (uploads, scores.txt, v2.sh, charcount.py, four screenshots): **laptop only**,
  `C:\Users\<you>\zorin and Mint keyboard driver resolution\ibus-auto-test\results-vscode\`, local commit 773f114, to
  be pulled at mirror v8. Until then the laptop claims are ◐ (same rule as REVIEW-3 R3-23).

## Bug found in 0.9.6 (and 0.9.6.1 as built)

Current VS Code's menu file is **`/usr/share/applications/com.microsoft.VSCode.desktop`** (it was `code.desktop`
before). The short name `vscode` in `be-azerty-fix.sh` (`skip_resolve`, line 504) only tries `code code-oss codium`,
so `be-azerty-fix ibus-skip on vscode` prints "✘ code: no menu file code.desktop found" and changes nothing.

**Workaround (works in 0.9.6, used for the skip runs):**

```
be-azerty-fix ibus-skip on com.microsoft.VSCode
```

then close every VS Code window and start it again from the menu. Undo: `be-azerty-fix ibus-skip off com.microsoft.VSCode`.

The ready one-line fix and the README texts for either choice are in `next-0.9.5/vscode-fix/`.

## Other observations
- Every VS Code start showed GNOME's "Choose password for new keyring" (cancelled); the first start showed the
  Copilot sign-in screen. No keys went astray.
- Not tested: installed system, Wayland, real hardware, VS Code from Snap or Flatpak, VSCodium, other Electron apps.

## Laptop raw files (pulled at mirror v8, 2026-10-26)

- `laptop-0.9.6/`: the 0.9.6 VS Code run, from the laptop's `ibus-auto-test\results-vscode\` (commit 773f114): six screenshots and `up-vsc/`.
- `laptop-0.9.7/`: the 0.9.7-logic run, from `ibus-auto-test\results-vscode-097\` (commits 0f5023e, 0d32145): `NOTE.md`, `mint/`, `zorin/`, next to `SUMMARY.txt`.
- The test inputs on the laptop (`ibus-auto-test\vscode\`) are byte-identical to `next-0.9.5/vscode-bundle/` and `next-0.9.7-vscode/laptop/v3.sh` (commits f22eed1, 6f8bf77).
