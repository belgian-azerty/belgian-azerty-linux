# Fedora 45 Workstation live, laptop emulator: packages built from main 4c5244a (point 3b, Fedora)

Run 3-4 Nov 2026, ~23:50 to 00:33 UTC (laptop clock), same rig and rules as `../ubuntu-26.04/RESULT.md`.
Go: Younes "ja" (23:43Z) for the ISO download. Labels: ✔ confirmed, ✱ inferred, ? unknown.

## Setup
- ISO `Fedora-Workstation-Live-45-1.4.x86_64.iso` (2 925 092 864 bytes) from dl.fedoraproject.org, SHA256 OK against
  `Fedora-Workstation-45-1.4-x86_64-CHECKSUM` ✔. The GPG signature of that CHECKSUM file was **not** checked.
- VM: q35, UEFI, 7 GB, 4 CPUs. Live user `liveuser`, GNOME Shell **51.0** on Wayland, SELinux **enforcing** ✔
  (`gfed-base.txt`, `gfed-diag.txt`). xkeyboard-config 2.48, libxkbcommon 1.13.1, systemd 262.1 ✔.
- Rig changes inside the throwaway VM: sudo asked for liveuser's (empty) password, so a sudoers drop-in
  `/etc/sudoers.d/zz-rig` (NOPASSWD) was added for the scripts (shot f12).
- Build: the three spec files of the public repo at commit 4c5244a (fetched from raw.githubusercontent.com), built
  with `spectool -g -R` + `rpmbuild -ba`, `_topdir /tmp/rpmbuild`. The documented `git clone` filled the live overlay
  ("No space left on device", `gfed-build-try1.txt`); that is a live-session limit, not a fault of the steps ✱.
  Sources fetched by spectool: keyd-2.6.0.tar.gz (GitHub rvaiya/keyd) and belgian-azerty-linux-0.9.12.tar.gz (tag
  v0.9.12). All three builds exit 0 ✔ (`gfed-build.txt`, with SHA256 of every rpm).

## Results
| # | Check | Result | Evidence |
|---|---|---|---|
| F1 | `dnf install` keyd-2.6.0 + belgian-azerty-windows + keyd-belgian-windows 0.9.12: `/etc/xkb/rules/evdev` and `/etc/xkb/symbols/be_capslock` present, `rpm -V xkeyboard-config` clean, keyd active+enabled, `keyd check` "No errors found", 2 keyd virtual devices | ✔ | gfed-inst.txt |
| F2 | libxkbcommon picks up `/etc/xkb`: `pc+be+inet(evdev)+be_capslock(windows)+be_capslock(windows_accents)` | ✔ | gfed-inst.txt |
| F3 | GNOME user options (gsettings, options first, then sources): compositor keymap has both options | ✔ | gfed-opts.txt |
| F4 | Typing in the GNOME terminal (Wayland): identical, character for character, to the Mint reference; Shift+AltGr é à ñ | ✔ | typed-fedterm.txt, acc-fedterm.txt |
| F5 | **`sudo localectl set-x11-keymap be pc105 "" caps:be_windows,be_azerty:accents` (the documented system step) fails**: "Specified keymap cannot be compiled, refusing as invalid" | ✘ | gfed-sys.txt |
| F6 | With our package installed, localed refuses **every** X11 keymap, also plain `be pc105` and `us pc105`; with `/etc/xkb` moved aside both work | ✘ / ✔ | gfed-diag.txt, gfed-diag2.txt |
| F7 | Cause: SELinux. `avc: denied { map } ... comm="systemd-localed" path="/etc/xkb/rules/evdev" scontext=system_u:system_r:systemd_localed_t tcontext=system_u:object_r:etc_t`. With `setenforce 0` the same command works; localed run by hand (not in its own SELinux domain) also works | ✔ | gfed-diag3.txt |
| F8 | Login screen (GDM) after that: US layout, no options (typed `qw12`, Caps `12E`, AltGr+e `e`). `/etc/X11/xorg.conf.d/00-keyboard.conf` and `/etc/vconsole.conf` say `be` + our options (written during the permissive moment), but `localectl status` shows "X11 Layout: (unset)" because localed cannot compile it when it starts | ✔ observed | gfed-ls.txt, shot g3 |

## Findings for a cloud thread (no package or script changed here)
1. **SELinux blocks systemd-localed from mapping `/etc/xkb/rules/evdev` (type `etc_t`)** on Fedora 45 with SELinux
   enforcing (the default). While our package is installed, `localectl set-x11-keymap` fails for any layout, the
   login screen cannot get Belgian through localed, and ✱ anything else that uses localed for the system keyboard
   (GNOME Settings' login-screen layout, `be-azerty-fix.sh system` on Fedora, which uses localectl) fails the same
   way. The test containers had no SELinux, which ✱ explains why the cloud tests passed.
   ✱ The system's own rules (`usr_t`) are mapped fine, so possible directions are a file context for `/etc/xkb` that
   localed may map, or a small policy module; which one is right is not checked here ?.
2. ✱ The denial is type-based (`etc_t`), so an installed Fedora (not live) is expected to behave the same; not run ?.
3. The documented `git clone` of the whole repository may be large for small disks or live sessions (a sparse or
   archive download of `packaging/` would be lighter). Minor.

## Not tested here
KDE on Fedora, an installed Fedora, Fedora 44, the text console, the upgrade/removal cycle on a desktop (done in
containers), `be-azerty-fix.sh` on Fedora (would hit F5 ✱).
