# 0.9.4 functional test on the laptop rig (2026-10-25 ~01:05-02:05Z), summary

Copied from the Remote Control session's report to this thread. The 194 raw files (27 MB: logs, typed text, key logs,
screenshots, hashes, every typed command, the scripts used, README.txt) are in the LAPTOP folder
`C:\Users\<you>\zorin and Mint keyboard driver resolution\evidence\raw-logs\2026-10-25-keyd-patch\{mint,zorin,common}\`,
not committed to git; mirror v6 must copy them here. Verify against those files.

Inputs: kit94.tgz 7537ae8d… verified; all 6 debs + be-azerty-fix.sh matched the kit README on the host and inside each
guest. ISOs reused read-only: Mint a081ab20… (= official sha256sum.txt), Zorin 44649b97…. Live sessions only.

| Step | Mint 22.3 live | Zorin 18.1 live |
|---|---|---|
| 1 Install | 0.9.3 + live, then upgrade to 0.9.4: keyd 2.5.0-5~ubuntu24.04.2, 0.9.4, 0.9.4; keyd restarted by itself (pid 2554 -> 3275), exe /usr/bin/keyd.rvaiya not deleted, active, no failed units | 0.9.4 fresh + live: same |
| 2 check | all pass except one expected ✘ XKBLAYOUT=us in /etc/default/keyboard (live mode does not write it); exit 0 | same |
| 3 seq.txt | `|@#{[^{}€[]\ |@#{[^{}€[]\ 12 &é` exact | exact |
| 4 held Ctrl+Alt, 120 ms, 10 lines | 10/10 `@€`x8; key log: AltGr down once per line, 2.00 events/char, 0 Ctrl/Alt events between keys | 10/10, same |
| 4 held AltGr (comparison) | 9/10 (line 7 swapped; keyd's output was in order, so the swap was above keyd) | 10/10 |
| 5a Ctrl+Alt+T | new terminal (wmctrl 2 -> 3 windows) | new terminal (screenshot) |
| 5b held Ctrl+Alt: 2 then T | @ typed and a new terminal | same |
| 5c held Ctrl+Alt: 2 then Right, Left | @ typed, workspace 1 -> 2 and back (wmctrl -d) | @ typed, indicator moves and back (screenshots) |
| 6 pointer (emulated tablet, weak proxy for a touchpad) | click opened the menu | same |
| 7 keyd restart x5 | 5/5 lines right, new pid each time, longest gap in a line 76 ms | 5/5, 77 ms |
| 8 Linux profile (`system` ran live) | keyd inactive + disabled; Ctrl+Alt+2 no @, AltGr+2 @; back to Windows: Ctrl+Alt+2 @, keyd active | same |
| 9 uninstall | 3 packages purged, no failed units, /etc/keyd gone, check plain Belgian; AltGr+2 @, Ctrl+Alt+2 no @ | same |

Unexpected (verbatim points of the report, condensed):
1. Zorin 18.1's live session is X11, not Wayland.
2. In live mode `check` cannot pass the /etc/default/keyboard line (expected).
3. Linux profile and after uninstall: Caps Lock + 1 2 gives `&É` (Linux Caps uppercases é, documented); in a terminal
   Ctrl+Alt+2 arrives as ESC+2 instead of nothing.
4. Zorin after uninstall: `setxkbmap -query` in the running X session still lists caps:be_windows (Caps behaves Linux,
   the option's files are gone); Mint clean. The uninstall code is unchanged since 0.9.3, so not caused by the keyd patch; earlier uninstall tests
   did not report it (not checked whether they ran setxkbmap -query in the same session). For the final review.
5. be-azerty-fix said "Version 0.9.3" in its header comment (fixed in the cloud after the test: comment only).
6. Stock Zorin, before anything of ours was installed, dropped the first ~16 typed characters after an idle pause.
7. The key log sees only keyd's virtual keyboard (keyd grabs the PS/2 one): no input-side timestamps.
8. A first `ls -l /proc/PID/exe` without sudo was refused; re-recorded with sudo.
Nothing skipped. Left on the laptop: /root/be-rig/k94 (7.6 GB, two VM snapshot files); deleting them needs Younes's
"Approve" for: `wsl -d Ubuntu-24.04 -u root -- rm -f /root/be-rig/k94/k94-mint-state.qcow2 /root/be-rig/k94/k94-zorin-state.qcow2`

Tested belgian-azerty-windows was 6e50c62f…; the final one (7a52855e…) differs only in README.md and that header
comment (`cloud-final-vs-tested-packages.txt`). keyd and keyd-belgian-windows are the tested files.
