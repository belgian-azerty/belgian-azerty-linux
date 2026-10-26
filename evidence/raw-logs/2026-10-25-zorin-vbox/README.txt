Zorin 18.1 Belgian stick (0.9.4.1) rebuilt on the laptop (<laptop>) in WSL, live-booted in VirtualBox 7.2.10
on Windows, 2026-10-25 11:49-12:25Z. Approved by Younes in the project thread ("You may test zorin in virtual box on my
computer Yes", 11:41Z; build workaround option "A", 11:56Z). No install, no disk, no snapshots, no dd, not committed.

RESULTS
check                         expected                                   got                                   file
kit integrity                 16 files match SHA256SUMS                  16 OK                                 step-a-prep.log is attempt 1; see commands/a1-flatten.sh
stock Zorin ISO               44649b97...21d5                            44649b97...21d5                       step-a-prep.log
build (attempt 1, kit tools)  exit 0                                     FAILED: WSL kernel has no zstd        build-attempt1-failed.log
                                                                         squashfs (CONFIG_SQUASHFS_ZSTD unset)
build (attempt 2, option A)   exit 0 + 3 expected lines                  exit 0, all 3 lines present           build.log, step-a-build-wsl.log, tools-wsl.diff
stick hash                    new hash (build time recorded)             8c0e89c5...2fac (cloud: 6553975b...)  stick.sha256, content/content-check.log
/belgian/ debs                3 expected sha256                          3 OK                                  content/belgian-debs.sha256
copy to Windows               same sha256                                same; WSL copy removed                copy-to-windows.log
boot menu                     counts down, starts Nederlands/period      countdown seen, booted w/o keypress   shots/b-boot-*.png, uploads/probe.txt (cmdline)
desktop                       stable desktop                             stable at ~6 min (NEM)                shots/desk-17-363s.png, boot-wait.log
terminal Ctrl+Alt+T           opens                                      opened, no click needed               shots/c0-terminal.png
probe: keyd                   active                                     active, enabled                       uploads/probe.txt
probe: packages               0.9.4.1 / 2.5.0-5~ubuntu24.04.2            same                                  uploads/probe.txt
probe: setxkbmap              layout be                                  layout "be,us" (see NOTES)            uploads/probe.txt
probe: be-azerty-fix check    no cross                                   no cross                              uploads/probe.txt
session type                  note it                                    x11                                   uploads/probe.txt, shots/c1-setup.png
terminal typing (seq.txt)     |@#{[^{}€[]\ |@#{[^{}€[]\ 12 &é            exact (od dump)                       uploads/vbox-term.txt, -od.txt
plain letters                 azerty qwerty AZERTY é&ç                   exact (od dump)                       uploads/vbox-letters.txt, -od.txt
GTK Text Editor (seq.txt)     same line                                  exact, saved and uploaded             uploads/vbox-gtk.txt, -od.txt, shots/c7, c10
Caps Lock + a, then off + a   Aa                                         Aa                                    uploads/vbox-caps.txt, -od.txt
pointer click on a menu       menu opens                                 NOT DONE (see NOTES)                  -

NOTES
- Build workaround (option A): tools/ copied to tools-wsl/ in /root/be-rig/zvb; build-layer.sh opens the stock image
  with unsquashfs into a directory instead of a loop mount (2 lines changed, tools-wsl.diff). Kit files unchanged.
- setxkbmap shows layout "be,us" (gsettings sources is [('xkb','be')] only). Typing results were right regardless.
- belgian-stick-live.service reports "inactive" in the probe, but its log shows it ran at 12:07:03Z and applied
  everything (probably a oneshot without RemainAfterExit; not checked).
- gnome-text-editor showed an English UI ("New Document", "Open") while the session locale was nl_BE.
- Pointer check not done: VBoxManage cannot inject mouse clicks; computer-use access to the VirtualBox VM window was
  declined in the approval dialog, so no click was attempted by any other route.
- VirtualBox ran on Hyper-V/NEM: VBox.log "HM: HMR3Init: Attempting fall back to NEM: VT-x is not available".
  First two screenshots failed (0x0 resolution) before the firmware drew; harmless.
- WSL: squashfs-tools 1:4.6.1-1build1 and xorriso 1:1.5.6-1.1ubuntu3 were already installed; nothing installed.
- .git/info/exclude got two local lines (zvb/, belgian-azerty-zorin-vbox-kit/) so the ISO cannot be committed.

FILES
README.txt                   this file
step-a-prep.log              attempt 1: tool check, stock ISO hash, df
build-attempt1-failed.log    attempt 1 full output (mount failure)
step-a-build-wsl.log         attempt 2 wrapper output (diff, build, hash)
build.log                    attempt 2 make_belgian_iso.sh output
tools-wsl.diff               the only change from the kit's tools (build-layer.sh, 2 lines)
stick.sha256                 laptop stick hash
content/                     content-check.log (both hashes, debs, layer superblock, md5sum lines, grub entries),
                             belgian-debs.sha256, grub.cfg, md5sum.txt, zz-belgian-azerty.lls.txt (unsquashfs -lls)
copy-to-windows.log          cp to Windows + sha256 compare + WSL copy removal
showvminfo.txt               VM config before start; showvminfo-at-poweroff.txt after poweroff
VBox.log                     VirtualBox log of the run (NEM lines)
boot-wait.log                desktop-stable wait (hash per 20 s screenshot)
shots/                       b-boot-* boot menu countdown, desk-* boot to desktop, c0-c12 checks in order
uploads/                     files sent from the guest (probe, typed captures, od dumps)
server-logs/                 http 8020 (kit) and upload 8021 logs
commands-driver.log          every key/typing command sent to the VM, with time
commands/                    every script run (a* WSL, b* VM start/wait, c_drive.py keys), guest-lines/ = text typed
                             into the guest terminal, t.sh as served (port 8021), upload_server_8021.py

KEPT ON THE LAPTOP
C:\Users\<you>\zorin and Mint keyboard driver resolution\zvb\zorin-belgian-stick.iso  3915448320 bytes, sha256 8c0e89c5...2fac
/root/be-rig/zvb/ (kit, tools-wsl, logs; no ISO). VM be-zorin-vbox unregistered and deleted (ISO detached first).
