Stick rebuild with the new packages, 2026-10-25 ~02:13-03:35Z, thread "Ship the keyd Ctrl+Alt patch in 0.9.4" (cloud
container, QEMU TCG, no KVM). Asked by the coordinator under Younes's night rules; DECISIONS.md 02:55Z line.

stick-build-0.9.4.1.txt        FINAL sticks: stock ISO hashes, stick hashes, the three debs inside each /belgian/, build log.
stick-build-0.9.4-superseded.txt  first build with 0.9.4 (superseded within the hour by the README-only 0.9.4.1).
package-0.9.4.1-readme-rebuild.txt  0.9.4 -> 0.9.4.1: only README.md, changelogs and a man page header differ; every
                               code file byte-identical (cmp); dist/SHA256SUMS.
zorin-uefi-default-probe.txt, zorin-typed*.txt, zorin-uefi-live-desktop.png, zorin-ctrl-alt-t-terminal.png
                               0.9.4 Zorin stick (superseded), UEFI, menu untouched: all green, line exact.
zorin-0.9.4.1-*                FINAL Zorin stick, UEFI, nobody touched the menu (countdown -> Nederlands + period):
                               probe + be-azerty-fix check with no cross, 0.9.4.1 packages, keyd active; typed line exact.
mint-0.9.4.1-*                 FINAL Mint stick, UEFI. Its GRUB menu has NO countdown (mint-0.9.4.1-uefi-menu-waits.png;
                               mint-0.9.4.1-stick-grub.cfg has no timeout line, nor does Mint's stock UEFI grub.cfg,
                               mint-stock-grub.cfg): Enter twice picked the default (Nederlands, period). Then probe +
                               check with no cross, 0.9.4.1 packages; Ctrl+Alt+T opened a terminal (after one click on
                               the desktop for focus); typed line exact.
stick-probe.sh, seq.txt, t.sh  the probe, the key sequence (QEMU key names) and the capture script used.
Typed line expected and got on both: |@#{[^{}€[]\ |@#{[^{}€[]\ 12 &é
Not covered: BIOS boots of the 0.9.4.1 sticks, dd-written USB boot, install from the sticks (the extra-tests thread did
those with 0.9.3 sticks).
