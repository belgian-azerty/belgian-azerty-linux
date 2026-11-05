Round two, item 10: Mint stick UEFI boot menu without countdown (5 Nov 2026, cloud only, no stick built)
Write-up: research/round-two/ITEM-10-MINT-GRUB-TIMEOUT.md

Tools: Ubuntu 24.04 packages grub-common and grub-emu 2.12-1ubuntu7.3 (grub-script-check, grub-emu), unpacked, not installed.
Input: Mint 22.3 stock UEFI grub.cfg (evidence/raw-logs/2026-10-25-sticks-0.9.4/mint-stock-grub.cfg).

mint-grub-before.cfg   tools/belgian_boot_menu.py grub 1 < mint-stock-grub.cfg, before the change (no timeout)
mint-grub-after.cfg    the same after the change (one "set timeout=10" after set default="0>0")
own-timeout-kept.cfg   stock cfg with "set timeout=30" added in front: kept, no second timeout line
emu-test-grub.cfg      mint-grub-after.cfg for grub-emu (no kernel): Belgian AZERTY entries' linux line -> echo of locale and
                       numpad option, every initrd line -> sleep 2; halt, loadfont removed
emu-new2.txt           grub-emu on emu-test-grub.cfg, no key: counts 10s..0s, then "BOOTED locale=nl_BE.UTF-8 belgian.decimal=period"
emu-old.txt            grub-emu on the menu before the change, no key, stopped after 15 s: no countdown, nothing started
emu-key.txt            grub-emu on the new menu, arrow key after 3 s: countdown stops at 8s, nothing started (stopped after 18 s)
Terminal escape codes were stripped from the emu-*.txt captures. "can't find command grub_platform" is grub-emu only.
