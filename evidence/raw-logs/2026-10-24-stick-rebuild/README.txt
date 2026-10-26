Evening rebuild, 2026-10-24 ~19:40-20:25Z, thread "Finish the stick rebuild and handover" (cloud QEMU, TCG).
package-rebuild.txt  packaging/build-all.sh --no-keyd: SHA256SUMS before/after, unpacked old vs new debs (only the
                     README inside belgian-azerty-windows differs), t14s-test/ refreshed.
stick-build.txt      stock ISO checksums, both stick checksums, the three debs inside each stick's /belgian/, build logs.
R (recheck boot of the rebuilt Zorin stick): UEFI, nobody touched the menu.
  r-zorin-boot-disc-check.png  casper's built-in disc check running at boot (it continued to the desktop, no error).
  r-zorin-uefi-default.txt     probe (../2026-10-24-stick/guest-scripts/stick-probe.sh): nl_BE, be, Windows profile,
                               keyd active + enabled, 0.9.3 packages, be-azerty-fix check without any cross.
  r-typed.txt / r-typed-od.txt keys sent (QEMU names = US positions), in order:
     alt_r-2 alt_r-e spc alt_r-2 alt_r-e spc ctrl-alt-2 ctrl-alt-e spc ctrl-alt-2 ctrl-alt-e spc shift-1 shift-2 spc
     kp_1 kp_decimal kp_5 spc num_lock kp_1 kp_decimal kp_5 spc caps_lock 1 2 caps_lock spc 1 2 ret
     -> "@€ @€ @€ @€ 12 [F[3~[E 1.5 12 &é": AltGr and Ctrl+Alt both give @€; numpad first with NumLock off (cursor
        keys), then NumLock on: 1.5 (period); Caps Lock on: & é keys type 1 2 (Windows Caps); Caps off: & é.
The Mint stick's recheck boot is T7 (../2026-10-24-stick/t7-*).
