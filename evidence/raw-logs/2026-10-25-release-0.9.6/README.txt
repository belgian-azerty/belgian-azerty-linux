Final respin 0.9.6, 2026-10-25 12:16Z-13:20Z, thread "Ship the keyd Ctrl+Alt patch in 0.9.4" (cloud container, QEMU TCG,
no KVM). Younes "go respin" 12:16Z (DECISIONS.md).

cloud-run-offline-DISPOSABLE.txt   tests/run-offline.sh with DISPOSABLE=1 on the final build: shellcheck, full rebuild
                                   from source (byte-identical to dist/SHA256SUMS = REPRODUCIBLE), lintian, Caps table,
                                   install/upgrade/trigger/purge cycle. ALL PASS.
cloud-ibus-skip-offline.txt        next-0.9.5/tests/ibus-skip-offline.sh on the packaged be-azerty-fix: 43/43.
cloud-ibus-skip-pkg-cycle.txt      next-0.9.5/tests/ibus-skip-pkg-cycle.sh on belgian-azerty-windows_0.9.6: 11/11.
cloud-deb-0.9.6-vs-tested-0.9.5.txt  files that differ from the laptop-tested 0.9.5 (099fca7c) + code diffs.
dist-SHA256SUMS-0.9.6.txt          dist/SHA256SUMS of the final build.
stick-build-0.9.6.txt              stock ISO and stick hashes, both build logs, content fingerprints.
zorin-0.9.6-*                      Zorin stick, UEFI, menu untouched (countdown -> Nederlands + period): casper disc
                                   check passed; probe: CAPS=linux, no caps:be_windows, 0 crosses in check, profile line
                                   names Linux Caps Lock, automatic ibus skip on (Terminal drop-in, Text Editor copy,
                                   gnome-terminal-server GTK_IM_MODULE=gtk-im-context-simple); live session X11.
                                   Typed: |@#{[^{}€[]\ |@#{[^{}€[]\ &É &é  (Linux Caps Lock: Caps+é = É) = expected.
mint-0.9.6-*                       Mint stick, UEFI: menu waits for Enter (no countdown, like stock Mint UEFI); Enter
                                   twice = Nederlands + period. Probe: CAPS=windows, caps:be_windows, 0 crosses, automatic
                                   ibus skip on (Terminal, Xed). Typed: |@#{[^{}€[]\ |@#{[^{}€[]\ 12 &é = expected.
stick-probe-096.sh, seq.txt, t.sh  probe, key sequence (QEMU key names), capture script.
superseded-builds/                 two 0.9.6 builds of the same hour before R3-21 and the review README lines.
Not covered here: Wayland (live sessions are X11), installed systems, BIOS boot, real hardware -> laptop kit
laptop-kit-0.9.6/ (REVIEW-3 §15 retest), waiting for Younes's yes to the laptop.
