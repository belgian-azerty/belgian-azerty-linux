Functional test of the 0.9.4 packages (keyd with patch 0012 "Keep AltGr held while a Ctrl+Alt layer is held")
Date: 2026-10-25, Mint run 01:14Z-01:35Z, Zorin run 01:35Z-02:04Z (UTC). Laptop rig: QEMU + KVM inside WSL 2 Ubuntu-24.04,
one VM at a time (k94-mint, then k94-zorin), 4 GB RAM, 4 vCPU, --cpu host --vga virtio, BIOS boot, LIVE sessions of the stock ISOs.
Keys injected as PS/2 scancodes through QMP (qemu_rig.py keys/type, swaptest.py, held.py); screen read with QMP screendump.
The other thread's VMs (zu, later zt) ran next to mine the whole time; I did not touch them.

INPUTS
  kit        keyd-094-kit/kit94.tgz  sha256 7537ae8d784946bbb3b28d040389b12b2aa044549c241bbbf57ac112341965da (matches the brief)
  ISOs       linuxmint-22.3-cinnamon-64bit.iso  a081ab202cfda17f6924128dbd2de8b63518ac0531bcfe3f1a1b88097c459bd4
               (= the official list, common/mint-official-sha256sum.txt from mirrors.edge.kernel.org)
             Zorin-OS-18.1-Core-64-bit.iso      44649b97bd307fc4c8529205d098ebbf98575a1e1ba2ee7d7005b697af1721d5 (= the brief)
             both reused read-only from /root/be-rig/iso (no download)
  0.9.4      946cc443bf5c355ec8383765c6a1696d9001fbccc9f0d5062dc90dd835540468  keyd_2.5.0-5~ubuntu24.04.2_amd64.deb
             f9de04365e1c601a82101f3e29e3f624d9dfeedb629a564ed4222405dd33589c  keyd-belgian-windows_0.9.4_all.deb
             6e50c62f8e6414cd94f1496652e2f642e25c786005d1cceec49e42b3f7b880da  belgian-azerty-windows_0.9.4_all.deb
  0.9.3      4067e4cd92cb0693fb0bfa17dc592b1d4c255cda4288af8d1cdf65b86b3c3e67  keyd_2.5.0-5~ubuntu24.04.1_amd64.deb
             7f3c70248a95612a572d13ccd018827d9afda4df34620ad0e4f214f3354fc369  keyd-belgian-windows_0.9.3_all.deb
             62ddfe6a602bcc67f452cf6edb5c404f35b9d86fa6e8dfb156a04ea1c19716be  belgian-azerty-windows_0.9.3_all.deb
  script     be-azerty-fix.sh 6d6b3d923b5b903366a71dc1420c421a68cd56a4c6c58dd714476457fbaae941 (identical to /usr/sbin/be-azerty-fix in
             BOTH 0.9.3 and 0.9.4; its header still says "Version 0.9.3")
  All 7 hashes matched the kit README on the host (common/deb-sha256.txt) and again inside each guest after wget
  (mint/mint-get-check.txt, zorin/zorin-get-check.txt: 20 files OK each).
  Installed keyd binary sha256: 0.9.3 9b1cea38...5e2c79, 0.9.4 3ba243a2...68dc05 (same on Mint and Zorin).

RESULTS (file names relative to mint/ and zorin/)
 step                         Mint 22.3 live (X11, Cinnamon)                Zorin 18.1 live (X11, zorin:GNOME)            files
 1 install                    0.9.3 + live, then upgrade to 0.9.4: PASS     0.9.4 + live: PASS                             *-093-*, *-094-install.txt
                              2.5.0-5~ubuntu24.04.2 / 0.9.4 / 0.9.4,        same versions; exe -> /usr/bin/keyd.rvaiya,
                              keyd restarted by the upgrade (pid 2554->3275),  active, no failed units
                              exe -> /usr/bin/keyd.rvaiya (not deleted),
                              active, no failed units
 2 be-azerty-fix check        all lines OK except ONE ✘:                    same, same single ✘                           *-094-check.clean.txt, *-probe.txt
                              "XKBLAYOUT=us (want be)" (/etc/default/keyboard;
                              "live" does not write it, by design); exit 0
 3 seq.txt typing             |@#{[^{}€[]\ |@#{[^{}€[]\ 12 &é  EXACT        EXACT                                          *-seq.txt, *-seq-od.txt
 4 held Ctrl+Alt, 10 lines    10/10 @€@€@€@€@€@€@€@€                         10/10                                          out-*-ca, keylog-*-ca, kcheck-*-ca,
                              keyd output per line: LEFTCTRL d, LEFTALT d,   identical shape                               score-*-ca
                              LEFTALT u, RIGHTALT d, LEFTCTRL u, then only
                              2/E down/up: 2.00 events per character, 0
                              Ctrl/Alt events between keys, AltGr down x1
   held AltGr, 10 lines       9/10 (line 7 "@€€@@€@€..." ORDER SWAP; key    10/10                                          out-*-ag, keylog-*-ag, kcheck-*-ag,
                              log shows keyd sent the keys in order, so the                                                 score-*-ag
                              swap is above keyd: X/ibus)
 5a Ctrl+Alt+T                new terminal: wmctrl windows 2->3             new terminal on top (screenshot)               shots/*-sc-a*.png, win-sc-*.txt
 5b held Ctrl+Alt: 2, T       @ typed AND new terminal (windows 2->3)       @ typed AND new terminal (screenshot)          sc-typed-*.txt, shots/*-sc-b*.png
 5c held Ctrl+Alt: 2, Right   @ typed, Workspace 1->2 (wmctrl -d)           @ typed, workspace dot moved (screenshot)      shots/*-sc-c-right.png
    then held Left            back to Workspace 1                            back (screenshot)                              shots/*-sc-c-left.png, keylog-sc-*.txt
                              keyd log: AltGr released and real LEFTCTRL+LEFTALT sent before T / Right
 6 pointer (USB tablet)       click on menu button opened the menu          same                                           shots/*-pointer.png
                              (weak proxy for a touchpad: absolute tablet, not a touchpad)
 7 keyd restart x5            5/5 lines right, active after each, new pid   5/5, same                                      out-*-k7, keylog-*-k7-N, kcheck-*-k7,
                              each time, largest gap inside a line 76 ms    largest gap 77 ms                              state-*-k7, journal-*-k7.txt
                              (no 0.3 s+ pause)
 8 PROFILE=linux system       ran in the live session (no refusal), exit 0;  same                                          *-sys-linux*, *-linux-state.txt,
                              keyd inactive+disabled; typed "x␛2x @ &É &é":                                                *-linux-typed*.txt
                              Ctrl+Alt+2 -> no @ (terminal got ESC 2),
                              AltGr+2 -> @, Caps+1 2 -> &É (see below)
   PROFILE=windows system     exit 0, keyd active+enabled; typed            same                                           *-sys-windows*, *-windows-*.txt
                              "x@x @ 12 &é"
 9 uninstall                  exit 0, purged 3 packages; dpkg -l | grep      same                                          *-uninstall*, *-purged-state.txt,
                              empty, systemctl --failed empty, no /etc/keyd,                                                *-purged-typed*.txt
                              check: XKBLAYOUT=be, keyd not installed;
                              typed "x␛2x @ &É &é" (AltGr+2 @, Ctrl+Alt+2 no @)

UNEXPECTED / NOTES
 - Zorin 18.1 live runs an X11 session (XDG_SESSION_TYPE=x11, setxkbmap works), not Wayland as the brief assumed.
 - Step 2: "every line passes" is not literally true in a live session: /etc/default/keyboard stays XKBLAYOUT=us after
   "be-azerty-fix.sh live" (live only changes the running session). Everything else passes.
 - Step 8/9: Caps Lock with the Linux profile (and after uninstall) gives "&É", not "& é": Linux Caps Lock uppercases é,
   which is what the script documents ("Caps Lock only changes letters and é è ç à"). Ctrl+Alt+2 "types nothing" in a GUI
   sense; in the terminal it arrives as ESC + 2 (od shows 033 2), which is the terminal's normal Alt encoding.
 - Zorin after uninstall: setxkbmap -query still lists "options: caps:be_windows" in the running X session (GNOME's own
   xkb-options are empty, /etc/default/keyboard has none). Caps Lock nevertheless behaves the Linux way (typed &É): the
   option's XKB files were removed with the package, so the leftover name has no effect. Mint did not show this.
 - Mint AltGr comparison block: 1 of 10 lines swapped (above keyd, ibus-daemon running). The Ctrl+Alt block had 0 swaps.
 - The key logger only sees "keyd virtual keyboard": keyd grabs the PS/2 keyboard, so there are no input-side timestamps;
   gaps were measured on keyd's output.
 - Stock Zorin live (before anything of ours was installed): the first ~16 typed characters after an idle pause were lost
   twice (shots/z-094.png shows "http://..." without "wget -q"). Sending Enter and waiting 2 s first fixed it. Not caused
   by our packages.
 - My helper first ran "ls -l /proc/PID/exe" without sudo (Permission denied, mint/mint-093-install.txt); fixed to sudo
   and re-recorded for 0.9.3 in mint/mint-093-state.txt. All later records use sudo.
 - Mint boot took ~7 min to the desktop with the other thread's 6 GB VM running in parallel (CPU shared).

NOT DONE
 - Nothing skipped. Step 8 ran because "system" does not refuse a live session (it only skips the initramfs rebuild).

FILES
 mint/, zorin/           everything the guests uploaded (install/check logs with ANSI colours; *.clean.txt = colours removed),
                         typed captures (+ od dumps), key logs, kcheck-* (my per-line key log analysis), score-* (swapscore.py),
                         state-* (time, keyd pid, ibus, session), win-sc-mint.txt (wmctrl log every 0.3 s), journals, shots/
 common/                 ISO and deb hashes, kit README, typed-commands.log (every line typed into the guests, with time),
                         runs.log, scripts/guest (helpers served to the guests on 10.0.2.2:8010, uploads to :8011),
                         scripts/host (drivers: hrun.sh = step 4, krun.sh = step 7, held.py = hold Ctrl+Alt + keys,
                         kcheck.py, s5.sh/s8.sh/s9.sh = steps 5/6, 8, 9). swaptest.py/swapscore.py are the ones in rig/.
