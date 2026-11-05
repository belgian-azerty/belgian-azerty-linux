# Round two, item 10: the Mint stick's UEFI boot menu does not count down

5 Nov 2026, 01:30-01:40 Belgian time. Change to the stick builder, tested with a GRUB emulator in the cloud; no stick
built yet. Evidence: `evidence/raw-logs/2026-11-05-round-two-10-grub-timeout/`.

## Kort (Nederlands)
- **Probleem** ✔: start je de Mint-stick op UEFI, dan blijft het menu staan tot je twee keer Enter drukt. Het bestand
  `boot/grub/grub.cfg` heeft wel een standaardkeuze maar geen `set timeout`. Ook de gewone Mint-ISO heeft geen timeout.
- **Fix** (klaar op papier): onze stickbouwer zet `set timeout=10` in het menu, **alleen als** het menu zelf geen timeout
  heeft. Zorin heeft er al een en blijft dus ongewijzigd. Eén bestand, 12 regels: `tools/belgian_boot_menu.py` (ook als `patches/stick-builder-mint-grub-timeout-10s.diff`).
- **Getest zonder stick** ✔: met Ubuntu's eigen GRUB 2.12 (de 24.04-versie, als emulator in de cloud) telt het
  nieuwe menu af van 10 naar 0 en start het dan vanzelf "Nederlands, punt". Het oude menu blijft wachten. Druk je
  een toets, dan stopt het aftellen en kies je zelf, zoals nu.
- **Nog niet getest**: een echte stick, opgestart in een virtuele machine of op echte hardware.

## Hoe testen (later, elk met een eigen go)
1. **Cloud**: de patch toepassen in een branch en een Mint-stick 0.9.12 bouwen met `MENU=b PACKAGES=...`.
   Controleren dat `grub.cfg` één `set timeout=10` heeft en dat de schijfcontrole (`md5sum.txt`) klopt.
2. **Virtuele machine of pc** (UEFI): de stick opstarten **zonder iets aan te raken**. Verwacht: het menu telt
   10 seconden af en het bureaublad start in het Nederlands met de punt. Daarna nog één keer opstarten, op een pijltje
   drukken en Français kiezen. Verwacht: geen aftelling meer, de keuze werkt.
3. **Zorin-stick**: hetzelfde, om te zien dat er niets veranderd is (eigen timeout, geen extra regel).

## Details ✔
- Cause: `tools/belgian_boot_menu.py` (MENU=b) writes `set default="0>0"` but copies the distribution's timeout
  setting, and Mint 22.3's UEFI `grub.cfg` has none (`evidence/raw-logs/2026-10-25-sticks-0.9.4/mint-stock-grub.cfg`;
  menu seen waiting in the emulator on 25 Oct, same folder). With no `timeout` GRUB waits forever
  (`grub_menu_get_timeout` returns -1).
- Why 10 s and one level is enough: on timeout GRUB opens the default submenu with `timeout=0` and boots the rest of
  `default` ("0>0") at once (GRUB 2.12 `grub-core/normal/menu.c`, `grub_menu_execute_entry`; read in the Fedora 40
  fork, then confirmed by running Ubuntu's build). A key press unsets the timeout, so after a manual choice both menus
  wait, as today.
- The legacy-BIOS (isolinux) menu already counts down (about 6 s, its own TIMEOUT line); not changed.

| Check (cloud, `grub-emu` and `grub-script-check` from Ubuntu 24.04 grub-common/grub-emu 2.12-1ubuntu7.3) | Result |
|---|---|
| Patched script on Mint 22.3 stock grub.cfg | one `set timeout=10` right after `set default="0>0"`; otherwise identical to before ✔ |
| Menu with its own `set timeout=30` | kept, no extra line ✔ |
| Script run twice | still one `set timeout` ✔ |
| `grub-script-check` before/after | both valid ✔ |
| `grub-emu`, new menu, no key | "executed automatically in 10s" ... "0s", then `BOOTED locale=nl_BE.UTF-8 belgian.decimal=period` ✔ |
| `grub-emu`, old menu, no key, 15 s | no countdown, nothing booted ✔ |
| `grub-emu`, new menu, arrow key after 3 s | countdown stops at 8 s, nothing booted ✔ |

In the emulator test (`emu-test-grub.cfg`) there is no kernel to start: in the Belgian AZERTY entries the `linux` line
became an `echo` of its locale and numpad options, every `initrd` line became `sleep 2; halt`, and `loadfont` was
removed. `grub_platform` is unknown in grub-emu (harmless error).

## Honest limits
- Not run on a real stick, real firmware, VirtualBox or the laptop emulator. Mint's own signed GRUB on the 22.3 ISO
  was not compared with Ubuntu's 2.12-1ubuntu7.3 (Mint 22 is based on 24.04 ✱).
- Not checked: `loopback.cfg` (used when another GRUB boots the ISO file); the script gives it the same line if it has
  a casper entry and no timeout, harmless ✱.
- Only the boot menu. Typing and keyboard are not affected.

## Status
Pushed to the stick builder on main on 5 Nov 2026. The next stick release will carry it; until a stick has been booted
with it, the countdown is tested only in the GRUB emulator. Not reported upstream: stock Mint also has no timeout,
which is Mint's choice for its own ISO.
