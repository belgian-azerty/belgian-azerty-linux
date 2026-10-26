T7 (rerun 2026-10-24 ~19:49-20:05Z by the thread "Finish the stick rebuild and handover", on the REBUILT Mint stick
sha256 0e29ca31...; the first T7 run at ~18:55Z reached the desktop but its files were lost).
Cloud QEMU (TCG), legacy BIOS, isolinux menu: Down Down (Deutsch) Enter, Down Down (Deutsch QWERTZ) Enter.
Screenshots: mint-bios-menu-top.png (main menu, Deutsch highlighted, countdown stopped), mint-bios-menu-deutsch.png
(the Deutsch submenu: Belgisch AZERTY Punkt / Komma, Deutsch QWERTZ, Zuruck).
t7-mint-bios-de-qwertz.txt: facts from guest-scripts/stick-probe.sh (keyboard de, keyd inactive + disabled,
LANG=de_BE.UTF-8, packages present but not applied).
t7-typed.txt / t7-typed-od.txt: keys sent, in order (QEMU names = US positions):
  alt_r-q alt_r-e spc alt_r-q alt_r-e spc ctrl-alt-q ctrl-alt-e spc 1 2 spc kp_1 kp_decimal kp_5 spc y z ret
  -> "@€ @€ " AltGr+Q = @, AltGr+E = € (German QWERTZ);
  -> Ctrl+Alt+Q / Ctrl+Alt+E gave ESC + control codes (033 033 005), no @ or €: plain Linux, keyd off as designed;
  -> "12"; numpad gave cursor-key sequences (ESC[F ESC[3~ ESC[E): NumLock was off in this VM, numpad not tested;
  -> US y and z positions typed "z y": QWERTZ confirmed.
Typed into gnome-terminal via de_type.py (German key positions).
