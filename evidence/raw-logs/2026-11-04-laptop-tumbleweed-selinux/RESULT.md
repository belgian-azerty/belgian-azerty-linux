# openSUSE Tumbleweed KDE, installed on a virtual disk, SELinux enforcing: 0.9.12-1 and the SELinux fix 0.9.12-2

Run 4 Nov 2026, ~16:45 to 17:05 UTC (laptop clock), same rig and rules as
`../2026-11-03-laptop-emulator-p3/opensuse-leap-16.0/RESULT.md`.
Go: Younes 4 Nov 15:34Z, project chat, "7: go tumbleweed" (relayed by the coordinator: re-download the Tumbleweed ISO,
install on a virtual disk in WSL, test our package with SELinux enforcing; real disk untouched).
Labels: ✔ confirmed, ✱ inferred, ? unknown. Test only: no package or script was changed, nothing was pushed.

## Setup
- ISO `openSUSE-Tumbleweed-DVD-x86_64-Snapshot20261102-Media.iso` (4 634 705 920 bytes), SHA-256 OK against openSUSE's
  `.sha256` file ✔ (`uploads/get-twdvd-output.txt`). Signature not checked.
- Installed with YaST onto `/root/be-rig/p3/tw.qcow2` (30 GB qcow2 in WSL, the VM's only disk, `vda`). System role
  "Desktop with KDE Plasma"; the installer's Security section said "SELinux in 'Enforcing' mode" (shot i16). Keyboard
  left at `us`. A throwaway test user `tester` was created. No real disk was touched.
- Installed system: Tumbleweed 20261102, Plasma 6.8.2 on Wayland, systemd 261.4, xkeyboard-config 2.48,
  libxkbcommon 1.13.2, selinux-policy-targeted 20261019, policycoreutils 3.11; `/sys/fs/selinux/enforce` = 1,
  kernel `security=selinux selinux=1` ✔ (`gtwi-base.txt`, `gtwi-sel1.txt`). `getenforce` is not installed; the scripts
  read `/sys/fs/selinux/enforce` instead.
- Login screen: SDDM 0.21 (`sddm-qt6`) with an **X11** greeter ("Starting X11 session ... sddm-greeter-qt6") ✔
  (`gtwi-greet.txt`, `gtwi-dm.txt`).
- Rig changes inside the VM: sudoers drop-in `zz-rig` (NOPASSWD), PackageKit masked, screen lock off.

## 0.9.12-1 first (does Tumbleweed have the Fedora problem?)
| # | Check | Result | Evidence |
|---|---|---|---|
| A1 | Build the two spec files of the public repo at 4c5244a + the v0.9.12 archive, `rpmbuild -ba` | ✔ exit 0 for both | gtwi-build.txt |
| A2 | `zypper install` the two rpms: keyd 2.6.0-2.1 from Tumbleweed pulled in, keyd active+enabled, `keyd check` "No errors found", 2 keyd virtual devices | ✔ | gtwi-inst.txt |
| A3 | With `/etc/xkb` labelled `etc_t`: `localectl set-x11-keymap be pc105 "" caps:be_windows,be_azerty:accents` and plain `be pc105` | ✔ both exit 0, no AVC: **the Fedora SELinux problem does not happen on Tumbleweed** (same as Leap 16.0) | gtwi-sel1.txt |

## SELinux fix 0.9.12-2 (steps of `research/five-families/selinux-etc-xkb/LAPTOP-TEST-STEPS.md`)
Packages from `research/five-families/selinux-etc-xkb/built/tw/`, `sha256sum -c` OK on the host and in the guest ✔.

| Step | Result | Evidence |
|---|---|---|
| 1 SELinux enforcing | ✔ enforce=1 | selfix-tw-up.txt |
| 2 install (upgrade 0.9.12-1 → -2) | ✔ zypper: belgian-azerty-windows 0.9.12-2, keyd-belgian-windows 0.9.12-1 (keyd 2.6.0 kept) | selfix-tw-up.txt |
| 3 module + labels | ✔ `belgian_azerty_xkb` loaded; labels went `etc_t` → `usr_t` on both files | selfix-tw-up.txt |
| 4 localectl be + both options | ✔ exit 0; `localectl status` and `/etc/vconsole.conf` show `be` + `caps:be_windows,be_azerty:accents` | selfix-tw-up.txt |
| 5 no AVC (xkb/localed) | ✔ none | selfix-tw-up.txt |
| 6 after a **reboot** | ✔ module and labels still there, localectl unchanged, no AVC this boot | selfix-tw-after-reboot.txt |
| 6 login screen (SDDM, X11 greeter), keys typed into the "Other..." username field | Belgian layout ✔ (`az&é`); AltGr+e `€` ✔; Ctrl+Alt+e `€` (keyd) ✔; **Caps Lock Linux-style** (Caps+1 2 e gave `&ÉE`) ✘, the documented X11 limit (the X server reads only `/usr/share/X11/xkb`, which has no `caps:be_windows`); `^` then e gave `e` (no dead keys at the login screen) ✱ stock greeter behaviour | shots r3, r12, r12z; gtwi-greet.txt |
| 6 desktop session after login (KDE Wayland, no user layout set, so the system setting applies) | ✔ KWin keymap `pc_be_inet(evdev)_be_capslock(windows)_be_capslock(windows_accents)`; in Konsole Caps+1 2 e gave `12E`, AltGr+e and Ctrl+Alt+e gave `€` | shot r9; KWin keymap line in gtwi-facts.txt (17:03Z, same session) |
| 7 be-azerty-fix.sh system | not run (the script stops on openSUSE by design, as on Leap) | |
| 8 remove | ✔ package gone, module gone, `/etc/xkb` empty, plain `localectl set-x11-keymap be pc105` exit 0, no AVC. keyd-belgian-windows stays installed (separate package) | selfix-tw-remove.txt, gtwi-facts.txt |

## Findings (no package or script changed)
1. Tumbleweed with SELinux enforcing does **not** need the 0.9.12-2 fix for localectl (A3), but 0.9.12-2 works there
   and its module installs and removes cleanly ✔.
2. The SDDM login screen on Tumbleweed KDE is X11, so it is Belgian with € (AltGr and Ctrl+Alt) but **without our Caps
   Lock option** ✔. Same as the Tumbleweed live test (`../2026-11-03-laptop-emulator-p3/opensuse-tumbleweed/`, T6).
   ✱ A user who types a password with Caps Lock on gets different characters at the login screen than on the desktop.
3. Rig note: QEMU's key name for AltGr is `alt_r`; `ralt-e` sends nothing (first login-screen try, shot r3, and the
   first desktop try in r9 before `alt_r`). Not a guest problem.

## Not tested here
GNOME on Tumbleweed, the text console, disk unlock, typing the full Mint reference text on this install (done on the
Tumbleweed live image earlier).
