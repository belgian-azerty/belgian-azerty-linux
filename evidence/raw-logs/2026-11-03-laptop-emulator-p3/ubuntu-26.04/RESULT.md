# Ubuntu 26.04.1 live, laptop emulator: 0.9.11 then 0.9.12 (point 3a)

Run 3 Nov 2026, ~22:05 to 23:31 UTC (laptop clock), on the T14s QEMU+KVM rig in WSL (`/root/be-rig/p3`, own work
dir). Go: Younes in thread, "Doe maar al punten 2, 3, 5" (21:52Z) and "ok" for the ISO download (21:56Z).
Labels: ✔ confirmed (seen in the files here), ✱ inferred, ? unknown.

## Setup
- ISO `ubuntu-26.04.1-desktop-amd64.iso` (6 482 409 472 bytes) from releases.ubuntu.com/26.04, SHA256 OK against
  their SHA256SUMS ✔ (`scripts/get-ubuntu.sh`).
- VM: q35, UEFI (OVMF, no Secure Boot), 6 GB, 4 CPUs, `-vga std`, QEMU user network. Live session "Try Ubuntu",
  user `ubuntu`, GNOME Shell 50.1 on **Wayland** ✔ (`g26-diag.txt`, `g26-base.txt`).
- Packages: `github-release-0.9.11/*_all.deb` and `github-release-0.9.12/*_all.deb` from this folder, checked against
  their SHA256SUMS on the host and again in the guest ✔. keyd from Ubuntu's own archive: 2.5.0-5 ✔.
- Keys are injected as PS/2 scancodes by QEMU (`qemu_rig.py`); the typed text is written by `cat` in the GNOME
  terminal and uploaded (`uploads/typed-*.txt`, `uploads/acc-*.txt`).

## Results
| # | Check | Result | Evidence |
|---|---|---|---|
| U1 | Stock state: xkb-data 2.46-2, rules file really in `/usr/share/xkeyboard-config-2`, no keyd | ✔ | g26-base.txt |
| U2 | keyd 2.5.0 + 0.9.11 install: diversion on the real name `/usr/share/xkeyboard-config-2/rules/evdev`, our rules once (1 block, 2 marker lines), `dpkg -V xkb-data` clean, keyd active+enabled, 2 keyd virtual devices | ✔ | g26-apt.txt |
| U3 | Upgrade 0.9.11 → 0.9.12: same state, no doubled rules | ✔ | g26-up912.txt |
| U4 | `apt-get install --reinstall xkb-data` with 0.9.12: our trigger ran, rules still once, diversion kept | ✔ | g26-xkbre.txt |
| U5 | libxkbcommon 1.13.1 resolves `caps:be_windows,be_azerty:accents` to `be_capslock(windows)+be_capslock(windows_accents)` | ✔ | g26-diag.txt |
| U6 | Typing in the GNOME terminal (Wayland), after the options were active: plain row, Ctrl+Alt row (keyd), AltGr row, Caps rows, RCtrl+LAlt, 8× Ctrl+Alt 2 e in order | ✔ identical, character for character, to the Mint reference `review/mint/typed-m-caps-term.txt` | typed-u26term2.txt, typed-u26relogin.txt |
| U7 | Shift+AltGr accents: ´+e = é, `+a = à, ~+n = ñ; accent then space = `'` (standard Linux, as documented) | ✔ | acc-u26c.txt, acc-u26relogin.txt |
| U8 | Log out, log in again at the GDM login screen ("Not listed?", user ubuntu): keymap has our options at once, typing and accents as U6/U7 | ✔ | g26-fresh.txt, typed-u26relogin.txt |

## Finding (not a package bug, but it matters for be-azerty-fix and the handleiding)
- **GNOME 50.1 does not apply a change of `xkb-options` alone to the running session.** The first typing run
  (`typed-u26term.txt`) still had Linux Caps Lock (Caps+1 gave `&`, Caps+é gave `É`) although gsettings showed our
  options. The keymap GNOME sends to Wayland programs had no options at all, not even a standard one (`kpdl:comma`)
  ✔ (`g26-diag5.txt`). After a change of the input sources, or after a new login, the options were in the keymap ✔
  (`g26-diag6.txt`, `g26-fresh.txt`). In our test the sources were set 2 s before the options, so the rebuild came
  before the options ✔.
- ✱ So a user who switches the options on while logged in sees the effect only after logging out and in (or after
  switching layout). Whether be-azerty-fix already says "log out and in" on GNOME 50 was not checked here ?.
  Owner of any wording or code change: a cloud thread, not this one (no scripts changed here).

## Rig notes (not about our packages)
- The first boot showed a black screen with a cursor on VT1 (GDM greeter started at 22:12); the autologin desktop was
  on VT2 (Ctrl+Alt+F2) ✔ (shots b5, b8). Cause not looked into ?.
- The Ubuntu live session adds `('ibus','mozc-jp')` as a second input source at login ✔ (g26-base.txt, g26-fresh.txt).
- `timeout` without `--foreground` stopped `xkbcli dump-keymap-wayland` (state T) in the terminal; fixed in diag5.
- QEMU key name `a` is the AZERTY `q` key (known); `acc-u26b.txt` pressed the wrong key, `acc-u26c.txt` is correct.

## Not tested here
The Ubuntu login screen with a Belgian system layout (system layout stayed `us`), a real installation, Ubuntu on X11,
other programs than the GNOME terminal, the text console. Live session only; nothing installed on a real disk.
