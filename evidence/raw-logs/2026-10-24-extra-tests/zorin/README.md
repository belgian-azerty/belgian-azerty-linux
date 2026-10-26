# Zorin 18.1 extra tests (laptop rig, QEMU+KVM in WSL), 2026-10-25 night

Written in the cloud from the laptop session's progress notes (2026-10-25 ~01:10-04:55Z), because the laptop session
stopped at a permission prompt while writing its own report. The raw files (typed captures, screenshots, logs,
caps-desync-*.txt, caps-desync-recovery-steps.txt, the laptop README) are ONLY in the laptop folder
`C:\Users\<you>\zorin and Mint keyboard driver resolution\evidence\raw-logs\2026-10-24-extra-tests\zorin\` (and `dd-boot\`,
`super-key\`), uncommitted. Bring them in at mirror v6. Update 2026-10-25 11:20Z: the laptop session finished after all and wrote its own report as `zorin\README.txt` there (same results as below; laptop VM disks ~40 GB kept until Younes decides). Until then, the rows below rest on the session's notes, not on
files I have read.

Packages: 0.9.3 from the stick (not 0.9.4). Stick = zorin-belgian-stick.iso built on the laptop with the unchanged tool,
sha256 3132aba54f8dd0c2d47f38b88d44de417329b9c5c87135a8cc92553287409b73 (debs identical to the kit's 0.9.3 debs).

**No dd write on the laptop:** the laptop's safety check reserves dd for Younes. The boots used the ISO file itself as a
read-only USB disk (`snapshot=on`, fresh 16 GB overlay per boot): the same bytes a dd-written stick presents. The ISO's
sha256 was unchanged after all boots. A real dd write was tested on Mint in the cloud.

## Results

| Test | Result |
|---|---|
| 2 Boot UEFI from the stick (untouched menu) | PASS. Typing exact (`|@#{[^{}€[]\ |@#{[^{}€[]\ 12 &é`). casper added sda3 "writable" (12.4 GB ext4), stock behaviour |
| 2 Boot BIOS (legacy) | PASS. Typing exact. casper added sda3 here too |
| 3 Brave (Zorin's browser) textarea | PASS, exact. Address bar `@€{}` |
| 3 VS Code | PASS, exact. Ctrl + Belgian A = select all (follows the Belgian letter) |
| 3 Firefox | NOT TESTED: a Firefox tarball's first start shows a Terms of Use dialog with only "Continue"; not accepted on Younes's behalf. Firefox is covered on Mint |
| Install (UEFI, from the stick) | PASS. Keyboard page preselected Belgian / Belgian. First boot landed in the OVMF shell (rig NVRAM quirk, `\EFI\BOOT\BOOTX64.EFI` booted it); later boots normal |
| Before update (boot 2, Wayland) | Typing exact |
| 1 Full update | `apt full-upgrade` exit 0: 413 upgraded + 39 new, incl. keyboard-configuration, console-setup, gnome-shell, mutter, libinput, xserver. No newer xkb-data, systemd or kernel available. /etc/default/keyboard still has caps:be_windows |
| 1 After reboot | Typing exact; `be-azerty-fix check` 0 ✘ |
| 1 Suspend and resume | With virtio-vga the display stayed "not active" after resume (emulator display; unknown whether the guest survived). Rerun with standard VGA: S3 (deep) entered and woke (journal), lock screen unlocked by typing, typing exact after resume |
| Pointer after resume | A click opened the Zorin menu. The QEMU tablet is a weak stand-in for a real touchpad |
| Super key, installed (ours, updated) | Opens the Activities overview. zorin-menu super-hotkey=false, mutter overlay-key='Super_L' |
| Super key, installed stock Zorin | Also opens the overview, same settings. So this is how stock Zorin behaves; not our packages (Younes 21:39Z: "let it go") |

## Finding: Caps Lock out of step after a password dialog or the lock screen (Wayland)

Trigger: type keys that include Caps Lock on/off into a GNOME Shell password dialog (pkexec, also the auto-started
Software Updater dialog) and cancel, or toggle Caps while typing on the lock screen (Super+L) and unlock.
Rows: LED | a, Shift+a | 2, Shift+2 | ù, Shift+ù | digit row | Shift digit row.

Ours (0.9.3, caps:be_windows), Wayland, pkexec:
- before: 0 | a A | é 2 | ù % (correct)
- after cancel: 0 | A a | é é | ù ù | digit row follows the letters only on 1 3 4 5 8; é § è ç à ù stuck at the base symbol
- +1 Caps press: 1 | a A | same keys still stuck; alternates from there

Controls:
- Ours with keyd stopped: identical, so not keyd.
- Ours, lock screen: identical.
- Ours, X11 session: no desync (0/5 tries). Wayland with our packages: 6/6.
- Stock Zorin (installed from the stock ISO, Belgian layout, no options, no keyd, Wayland, not updated), pkexec and lock screen:
  after cancel 0 | A a | é 2 | ù % | &é"'(§è!çà | 1234567890; +1 press 1 | a A | É 2 | Ù % | &É"'(§È!ÇÀ | 1234567890.
  Stock desyncs too (letters invert against the LED), but Shift keeps working on the number row.

Difference: with our option, in every desync state 2 6 7 9 0 and % cannot be typed on the main block (both levels give
the base symbol) until log out/in or reboot. On stock only the case flips.

Recovery checks (ours, desync state, LED off):
- GNOME Shell's own entries (Activities search, Alt+F2): CORRECT (a A é 2 ù %).
- Wayland terminal: WRONG (A a é é ù ù, digit row 1é345§è8çà).
- X11 app (GDK_BACKEND=x11 gnome-text-editor): A a 2 é % ù, 1234567890, i.e. consistently Caps-on while LED off.
- `ibus engine`: xkb:us::eng (same as a clean boot).
- `ibus restart`: not cured. `ibus exit`: daemon stayed gone; terminal row became consistently Caps-on; one Caps press gave
  the correct Caps-off row with LED 1 (inverted).
- xkbcli: not run (libxkbcommon-tools not installed; left unchanged on purpose). Super+Space: n/a, one input source.
- Log out + in: cured (ibus had been exited before, so not a clean test of re-login alone).

Reading (unproven): the shell's own entries get the right lock state and the IBus path into Wayland apps does not, so an
IBus/mutter Wayland lock-state problem that stock has too; our caps:be_windows option makes its effect worse. Mint
(Cinnamon, X11) is not affected by this path. Handed to the threads "Fix the Zorin Caps Lock dead keys after a password
dialog" and the final review (REVIEW-3 finding R3-19).
