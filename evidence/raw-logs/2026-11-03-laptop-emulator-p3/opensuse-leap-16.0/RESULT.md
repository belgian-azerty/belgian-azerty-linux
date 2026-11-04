# openSUSE Leap 16.0 GNOME, installed on a virtual disk: packages built from main 4c5244a (point 3b, Leap)

Run 4 Nov 2026, ~01:55 to 03:20 UTC (laptop clock), same rig and rules as `../ubuntu-26.04/RESULT.md`.
Go: Younes "ja" (01:50Z) for the ISO download and the install on a virtual disk. Labels: ✔ confirmed, ✱ inferred, ? unknown.

## Setup
- ISO `Leap-16.0-offline-installer-x86_64.install.iso` (4 538 236 928 bytes), SHA-512 OK against openSUSE's
  `.sha512` file ✔ (Leap 16.0 publishes SHA-512, not SHA-256; the first check failed for that reason only).
  Signature not checked.
- Installed with the Agama installer onto `/root/be-rig/p3/leap16.qcow2` (30 GB qcow2 in WSL, the VM's only disk,
  `vda`). Patterns: GNOME Desktop (Wayland), SELinux Support (default), Software Management. Keyboard left at `us`.
  A throwaway test user `tester` was created. No real disk was touched.
- Installed system: GNOME on Wayland, GDM, **SELinux enforcing** (`enforce=1`, `security=selinux`), systemd 257.13,
  xkeyboard-config 2.44, libxkbcommon 1.8.0 ✔ (`gleap-base.txt`).
- Rig changes inside the VM: sudoers drop-in `zz-rig` (NOPASSWD), PackageKit masked (it held the zypper lock and made
  the first build fail, `gleap-build-try1.txt`), screen lock off.
- Build: the openSUSE spec files at 4c5244a + the v0.9.12 archive, `rpmbuild -ba` exit 0 for both ✔ (`gleap-build.txt`).

## Results
| # | Check | Result | Evidence |
|---|---|---|---|
| L1 | `zypper install` our rpms: keyd **2.5.0** from Backports (`bp160`) pulled in automatically; `/etc/xkb` files present; keyd active+enabled, 2 keyd virtual devices | ✔ (keyd 2.5.0 has no `check` command) | gleap-inst.txt |
| L2 | `localectl set-x11-keymap be pc105 "" caps:be_windows,be_azerty:accents` with SELinux enforcing and `/etc/xkb` labelled `etc_t` | ✔ exit 0, no AVC: **the Fedora SELinux problem does not happen on Leap 16.0** | gleap-sel1.txt, gleap-sys.txt |
| L3 | Typing in the GNOME terminal (options set as user: options, then sources): identical to the Mint reference; Shift+AltGr é à ñ | ✔ | typed-leapterm.txt, acc-leapterm.txt |
| L4 | Login screen (GDM) after reboot: `az&é 12E €€` = Belgian, Caps as on Windows, € via AltGr and via Ctrl+Alt (keyd) | ✔ | shot r2 |
| L5 | Dead keys at the login screen: `^`+e gives `e` (no composing at all in GDM) | stock greeter behaviour ✱ | shot r5 |
| L6 | SELinux fix 0.9.12-2 on this VM | see `../selinux-fix-0.9.12-2/RESULT.md` | |

## Not tested here
KDE on Leap, removal/upgrade beyond the 0.9.12-2 test, the text console, disk unlock.
