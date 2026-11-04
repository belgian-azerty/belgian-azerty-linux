# SELinux route A, step 2: 0.9.12-2 (belgian_azerty_xkb module) on the laptop emulator, SELinux enforcing

Run 4 Nov 2026, ~03:05 to 03:33 UTC (laptop clock). Go: Younes "go" 02:33Z in "Design the cross-Linux keyboard fix"
(relayed by the coordinator); steps from `research/five-families/selinux-etc-xkb/LAPTOP-TEST-STEPS.md`. Test only,
nothing pushed. Packages from the project library `built/f45/` and `built/leap16/`, `sha256sum -c` OK on the host and
in the guest ✔. Labels: ✔ confirmed, ✱ inferred, ? unknown.

| Step | Fedora 45 Workstation live (fresh install of the 3 rpms) | Leap 16.0 GNOME, installed on a virtual disk (upgrade 0.9.12-1 → -2) |
|---|---|---|
| 1 getenforce | ✔ Enforcing | ✔ enforce=1 |
| 2 install | ✔ dnf: keyd 2.6.0-1, keyd-belgian-windows 0.9.12-1, belgian-azerty-windows 0.9.12-2 | ✔ zypper: belgian-azerty-windows 0.9.12-1 → 0.9.12-2 (keyd 2.5.0 from Backports kept) |
| 3 module + labels | ✔ `belgian_azerty_xkb` loaded; `usr_t` on `/etc/xkb/rules/evdev` and `/etc/xkb/symbols/be_capslock` (before: no files) | ✔ module loaded; labels went `etc_t` → `usr_t` |
| 4 localectl be + both options | ✔ exit 0, status and `/etc/vconsole.conf` show `be` + `caps:be_windows,be_azerty:accents` | ✔ same |
| 5 no AVC (xkb/localed) | ✔ none in the journal since the step began | ✔ none |
| 6 login screen | ✔ via **log out** (live session, no reboot possible): GDM typed `az&é 12E €€` for keys q w 1 2, Caps+1 2 e, AltGr+e, Ctrl+Alt+e = Belgian, Caps as on Windows, € (keyd). Before the fix (0.9.12-1) the same test gave US (`../fedora-45/`, shot g3) | ✔ after a **reboot**: same `az&é 12E €€`, module and labels still there, no AVC this boot |
| 6 accents at the login screen | ✘ / ? dead keys do not compose in GDM at all: `^`+e, AltGr+ù then e, Shift+AltGr+ù then e all gave `e` (Leap, shot r5); stock behaviour of the greeter ✱, not our option | same ✱ (Leap tested) |
| 7 be-azerty-fix.sh system (optional) | ✔ main at 02fcede: "system default written by systemd-localed (layouts: be; options: be_azerty:accents)", GDM follows vconsole.conf, keyd running; exit 0; no AVC. (Its default for GNOME is CAPS=linux, so it set only the accents option.) | not run (the script stops on openSUSE by design) |
| 8 remove | ✔ package gone, module gone, `/etc/xkb` empty, plain `localectl set-x11-keymap be pc105` exit 0, no AVC | ✔ same |

Side result (no fix needed there): Leap 16.0 with SELinux enforcing **did not** show the Fedora problem with the
old 0.9.12-1: `localectl` worked with `/etc/xkb` labelled `etc_t` ✔ (`../opensuse-leap-16.0/`, gleap-sel1.txt).
✱ Its policy (selinux-policy-targeted 20250627) or systemd 257's localed differs from Fedora's; not looked into.

Evidence: `uploads/selfix-*.txt` (full command output), shots s7 (Fedora GDM), r4/r5 (Leap GDM).
