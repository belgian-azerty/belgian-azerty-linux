# Round two: items 1, 4, 6 and 10 (3-5 Nov 2026, cloud only)

Long-standing keyboard problems traced to their source, with a patch and a test each. Work done in the cloud on 3 Nov
2026 (items 1, 4, 6) and 5 Nov 2026 (item 10); nothing sent upstream yet. Each write-up: cause, patch, test, honest limits, where it would go upstream.

| Item | Problem | Result | Write-up | Evidence |
|---|---|---|---|---|
| 1 | Login screen ignores typing when ibus fails | GNOME Shell drops every key on an ibus error; 3-line "fail open" patch delivers them (GNOME 46 test) | ITEM-1-GNOME-FAIL-OPEN.md | evidence/raw-logs/2026-11-03-round-two-1-gnome-fail-open/ |
| 4 | Hidden extra "us" layout (be,us) in Dutch and German | No nl_BE/wa_BE/li_BE entry in the Cinnamon and GNOME locale tables; 3 table lines fix Dutch (Mint 22.3 + GNOME 46 test) | ITEM-4-STRAY-US-LAYOUT.md | evidence/raw-logs/2026-11-03-round-two-4-stray-us/ |
| 6 | Installer "detect layout" gives French | Ubuntu's detection tree can never reach Belgian; keymapper fix makes it ask "press !" (tree-level test, 41 layouts) | ITEM-6-INSTALLER-DETECT-LAYOUT.md | evidence/raw-logs/2026-11-03-round-two-6-detect-layout/ |
| 10 | Mint stick UEFI boot menu waits (no countdown) | Stick builder adds `set timeout=10` when the menu has none (Mint); Zorin keeps its own. Tested with Ubuntu's GRUB 2.12 emulator; no stick built yet (5 Nov) | ITEM-10-MINT-GRUB-TIMEOUT.md | evidence/raw-logs/2026-11-05-round-two-10-grub-timeout/ |

Patches: `patches/` (all unsent). Claims and how each was checked: `CLAIMS.md`. Not tested anywhere: real login screens, real installer windows, real hardware.
