# openSUSE Tumbleweed KDE live, laptop emulator: packages built from main 4c5244a (point 3b, Tumbleweed)

Run 4 Nov 2026, ~01:18 to 01:35 UTC (laptop clock), same rig and rules as `../ubuntu-26.04/RESULT.md`.
Go: Younes "Ja" (01:14Z) for the ISO download. Labels: ✔ confirmed, ✱ inferred, ? unknown.

## Setup
- ISO `openSUSE-Tumbleweed-KDE-Live-x86_64-Current.iso` = Snapshot20261102 (1 279 391 744 bytes) from
  download.opensuse.org, SHA256 OK against openSUSE's `.sha256` file ✔ (`tw-kde.sha256`; its signature not checked).
- VM: q35, UEFI, 7 GB, 4 CPUs. Live user `linux` (autologin, passwordless sudo). Plasma 6.8.2, KWin on **Wayland**;
  login screen SDDM 0.21 with an **X11** (Xorg) greeter ✔ (`gtw-dm.txt`). systemd 261.4, xkeyboard-config 2.48,
  libxkbcommon 1.13.2 ✔.
- **The live image runs AppArmor, not SELinux** (no `/sys/fs/selinux`, LSM list without selinux) ✔ (`gtw-base.txt`).
  ✱ An installed Tumbleweed uses SELinux by default, so the Fedora finding (`../fedora-45/RESULT.md`, F5-F7) was
  **not** tested here ?.
- `rpm -V xkeyboard-config` already shows mtime (`T`) differences on the stock live image, the same list before and
  after our install ✔ (live-image artefact, not ours).
- Build: the two spec files of the public repo at 4c5244a (raw.githubusercontent.com) and the v0.9.12 archive, built
  with `rpmbuild -ba` (`_topdir /tmp/rpmbuild`); both exit 0 ✔ (`gtw-build.txt`, with SHA256 of the rpms).

## Results
| # | Check | Result | Evidence |
|---|---|---|---|
| T1 | `zypper install --allow-unsigned-rpm` our two rpms: keyd 2.6.0-2.1 from Tumbleweed pulled in; `/etc/xkb` files present; keyd active+enabled, `keyd check` "No errors found", 2 keyd virtual devices | ✔ | gtw-inst.txt |
| T2 | libxkbcommon resolves both options from `/etc/xkb` | ✔ | gtw-inst.txt |
| T3 | `sudo localectl set-x11-keymap be pc105 "" caps:be_windows,be_azerty:accents` | ✔ exit 0 (no SELinux in this live image) | gtw-sys.txt |
| T4 | Plasma user options in `~/.config/kxkbrc` (LayoutList=be, Options=both): **not applied in the running session** (reloadConfig signal and KWin reconfigure tried); applied after logging out and in: KWin keymap `pc_be_inet(evdev)_be_capslock(windows)_be_capslock(windows_accents)` | ✔ after relogin | gtw-kde.txt, gtw-kde2.txt, gtw-relogin.txt |
| T5 | Typing in Konsole (KDE Wayland) after relogin: identical, character for character, to the Mint reference; Shift+AltGr é à ñ | ✔ | typed-twterm.txt, acc-twterm.txt |
| T6 | Login screen (SDDM, X11 greeter) after T3: Belgian layout ✔ (`az&é`), AltGr+e and Ctrl+Alt+e give `€` (keyd) ✔, but **Caps Lock is Linux-style** (Caps+1 2 é gave `&ÉE`) ✘ | as documented: an X11 server does not read `/etc/xkb` | shot t6 |

## Findings (no package or script changed here)
1. **Login screen on openSUSE KDE (SDDM on Xorg): Belgian yes, our Caps Lock option no** ✔. This matches the documented
   limit ("not read by a pure X11 session"), but it means the login screen differs from the desktop. ✱ Typing a
   password with Caps Lock on gives different characters there than in the session.
2. ✱ For KDE users the handleiding should say: after setting the options, log out and in (same as GNOME 50, see the
   Ubuntu finding). How a user sets them in KDE (the options are not in System Settings) is not documented yet ?.
3. SELinux on an installed Tumbleweed and on Leap 16.0: not tested; the Fedora SELinux problem may apply ?.

## Not tested here
Installed Tumbleweed (SELinux), GNOME on Tumbleweed, upgrade/removal on a desktop, the text console.
