Zorin part of the three extra tests (Belgian AZERTY 0.9.3), laptop QEMU+KVM rig in WSL Ubuntu-24.04, 2026-10-25 00:40-04:57Z.
Run by Claude on Younes's laptop (Remote Control session), brief from the coordinator session. No git commits made.
All work files: /root/be-rig/extra-tests/ in WSL. "up/" = files the guests sent back, "logs/" = host-side logs,
"shots/" = screenshots, ../dd-boot/ = boot menus, ../super-key/ = Super key screenshots.

=== Inputs and hashes
kit debs (match kit README):    62ddfe6a...16be belgian-azerty-windows_0.9.3_all.deb
                                7f3c7024...c379 keyd-belgian-windows_0.9.3_all.deb
                                4067e4cd...3e67 keyd_2.5.0-5~ubuntu24.04.1_amd64.deb
stock Zorin-OS-18.1-Core-64-bit.iso  44649b97bd307fc4c8529205d098ebbf98575a1e1ba2ee7d7005b697af1721d5 (reused, matches)
Belgian stick ISO (MENU=b PACKAGES=kit/dist make_belgian_iso.sh, unchanged tool):
  zorin-belgian-stick.iso  3132aba54f8dd0c2d47f38b88d44de417329b9c5c87135a8cc92553287409b73  (3915448320 bytes)
  /belgian/ on it holds the three debs, byte-identical to kit/dist (logs/stick-sha256.txt). The tool's self-check passed
  (logs/make-stick.log). Same sha256 re-checked after all boots (unchanged).
  Build note: the WSL kernel's squashfs cannot mount zstd images (dmesg: 'Filesystem uses "zstd" compression. This is not
  supported'), so for this build only a `mount` wrapper first in PATH expanded filesystem.squashfs with unsquashfs and
  bind-mounted it. The tool itself was not changed. Wrapper: /root/be-rig/extra-tests/shim/mount.
Downloads for test 3 (logs/downloads-sha256.txt): Firefox 158.0.1 tarball dce45470..., VS Code 1.143.1 .deb e459729d...

=== NO dd WRITE HAPPENED ON THE LAPTOP
The laptop's safety hook blocks `dd if=` (Tier 3, "Younes runs it himself"); it was not worked around (no cp/python copy).
zstick.img is an empty 16 GB sparse file (cmp: differs at byte 1). Instead every "stick" boot used the ISO file itself,
never written to, as the read-only backing file of a fresh 16 GB qcow2 overlay attached as a QEMU usb-storage device
(stick-uefi/-bios/-inst.qcow2). The guest sees a 16 GB USB disk whose first 3915448320 bytes are the ISO, which is what a
dd-written 16 GB stick presents. Not covered: the dd write itself and a real USB controller/stick.

=== Results
Expected typing (seq.txt): |@#{[^{}€[]\ |@#{[^{}€[]\ 12 &é
| Test | Firmware / app | Typed result | Check |
| 2a stick boot | UEFI (OVMF), menu untouched | exact (up/zu-uefi-typing*.txt) | menu: 4 language submenus, Nederlands default, countdown (dd-boot/uefi-boot-menu.png); live desktop nl_BE; be-azerty-fix check 0 ✘ (up/zu-uefi-probe.txt) |
| 2b stick boot | legacy BIOS (SeaBIOS/isolinux) | exact (up/zb-bios-typing*.txt) | menu same 4 entries, 5 s timeout (dd-boot/bios-boot-menu.png); casper ran its md5 disc check on this boot (dd-boot/bios-md5-check.png); 0 ✘ |
| 2 casper partition | both | - | YES: casper added sda3 "writable" ext4 12.4 GB in the free space of the 16 GB stick, mounted on /var/log and /var/crash (up/zu-uefi-lsblk.txt, zb-bios-lsblk.txt) |
| 3a Brave (Zorin's browser) | UEFI live | textarea exact (up/zorin-brave.txt, delay 0.8) | address bar Ctrl+Alt+2 E 9 0 = @€{} (shots/brave-addressbar.png) |
| 3b Firefox 158 tarball | UEFI live | NOT TESTED | first-run modal "By continuing you agree to the Terms of Use", only Continue (shots/ff-1.png); terms not accepted on Younes's behalf |
| 3c VS Code 1.143.1 | UEFI live | exact (up/zorin-vscode*.txt) | repo question answered No (debconf code/add-microsoft-repo=false, no MS repo/key, up/zu-vscode-fix.log); Ctrl+Belgian-A then x -> file "x": Ctrl+A follows the Belgian letter (up/zorin-vscode-shortcut.txt) |
| 1 install | UEFI from stick, default entry | "azerty" in the password field came out right (shots/inst-12.png) | keyboard page preselected Belgian / Belgian (shots/inst-2.png); Brussels preselected; user be / azerty; no encryption |
| 1 first boot | installed, Wayland | exact (up/zt-preupd-typing*.txt, boot 2) | OVMF first landed in its shell (rig NVRAM quirk, shots/boot1-d.png); \EFI\BOOT\BOOTX64.EFI booted, later boots direct. GDM login first try (no IBus race this time) |
| 1 update | apt update + full-upgrade -y | - | 413 upgraded, 39 new, exit 0, 0 left (up/zt-upgrade.log). Watched packages upgraded: keyboard-configuration+console-setup 1.226ubuntu1 -> 1.226ubuntu1.1, gnome-shell 46.0-...13+zorin2 -> ...16+zorin5, libmutter-14-0 46.2-...14+zorin2 -> ...18+zorin1, libinput 1.25.0-1ubuntu3.4 -> 3.7, xserver-xorg-core 21.1.12-1ubuntu1.5 -> 1.9. Not in the list: xkb-data (2.41-2ubuntu1.1), ibus (1.5.29-2), systemd (255.4-1ubuntu8.18), kernel (7.0.0-38 already). /etc/default/keyboard kept caps:be_windows; be_capslock and evdev rule present |
| 1 after reboot | installed, updated, Wayland | exact (up/zt-postupd-typing*.txt) | 0 ✘ (up/zt-postupd-probe.txt) |
| 1 suspend (virtio-vga) | S3 deep | - | QEMU "paused (suspended)", system_wakeup -> running, but the display stayed "Display output is not active" and no guest upload arrived after a blind unlock + command (2 tries); hard stop. logs/zt-suspend-status.txt, shots/wake-1..3. Cause unknown (likely virtio-gpu resume in QEMU) |
| 1 suspend (std VGA) | S3 deep, mem_sleep "s2idle [deep]" | exact after resume (up/zt-resume-typing*.txt) | info status "paused (suspended)", wake via HMP system_wakeup; journal "PM: suspend entry (deep)" ... "Waking up from system sleep state S3" ... "suspend exit" (up/zt-resume-probe.txt, hb-zt.txt); lock screen unlocked by typing; 0 ✘ |
| 1 pointer after resume | USB tablet | - | click on the Zorin menu button opened the menu (shots/resume-click-menu.png). The QEMU tablet is a weak stand-in for a real touchpad |
| Super key | ours, installed+updated | - | gsettings zorin-menu super-hotkey = false, mutter overlay-key = 'Super_L'; Super alone opens the GNOME Activities overview (../super-key/ours-installed-updated-super.png) |
| Super key | STOCK Zorin installed | - | same settings, same Activities overview (../super-key/stock-installed-super.png, up/zs-stock-extra.txt) |

=== Finding: Caps Lock desync on Wayland (files caps-desync-*.txt here, + caps-desync-recovery-steps.txt)
How: a GNOME Shell modal (pkexec password dialog, or the lock screen) receives keys including Caps Lock on/off, then is
cancelled/unlocked. Rows = LED | a A | 2 Shift+2 | ù Shift+ù | digit row | Shift+digit row.
Correct (Caps off): 0 | a A | é 2 | ù % | &é"'(§è!çà | 1234567890
- ours, Wayland, dialog:          after: LED 0 | A a | é é | ù ù | 1é345§è8çà | &é"'(§è!çà   (alternates with each Caps press)
- ours, Wayland, keyd STOPPED:    identical -> not keyd
- ours, Wayland, lock screen:     identical
- ours, X11 (Zorin on Xorg):      no desync, 0 of 5 tries (Caps on gives Aa 2é %ù 1234567890 as designed)
- STOCK Zorin, Wayland, dialog and lock screen: after: LED 0 | A a | é 2 | ù % ; +1 press: LED 1 | a A | É 2 | Ù % | &É"'(§È!ÇÀ
  -> the desync exists without our packages (letters invert against the LED). With caps:be_windows it is worse: é § è ç à ù
  give their base symbol with and without Shift, so 2 6 7 9 0 % cannot be typed on the main block until logout/reboot.
Wayland, ours: 6 of 6 tries desynced. Recovery: GNOME Shell's own entries type correctly in that state, the terminal does
not; `ibus restart` does not cure it; `ibus exit` makes text consistent again (LED inverted); log out + in cures it.
Not done: xkbcli (not installed, not added), Super+Space (only one input source), stock on X11.

=== Other notes
- First boot of our install: GNOME Software Updater's password dialog popped up and took typed keys (shots/b1-fail.png);
  that is how the desync was first seen (Caps-row probe, shots/b1-capsexp.png).
- Ctrl+Alt+T right after login is sometimes lost (known rig quirk); a second press works.
- Times in guest screenshots are CET (UTC+1); host logs are UTC.

=== Left on the laptop (WSL /root/be-rig/extra-tests, not deleted, as asked)
zt.qcow2 16.4 GB (our install), zs.qcow2 13.7 GB (stock install), stick-*.qcow2 4 x ~280 MB overlays,
zorin-belgian-stick.iso 3.9 GB, zorin.iso 3.9 GB (copy of the stock ISO), zstick.img 16 GB sparse / 0 bytes used (empty),
zt-vars.fd / zs-vars.fd (UEFI NVRAM), kit/, rig/ (copy of kit/rig with 2 small changes: qcow2 USB stick, --qarg), shim/.
This thread's servers (8000, 8888, 8001) were stopped at the end. No VM of this thread running.
