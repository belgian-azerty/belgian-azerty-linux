Release build 0.9.7, 2026-10-25 20:36-21:02Z, thread "Ship the keyd Ctrl+Alt patch in 0.9.4" (cloud container, QEMU TCG).
Younes: "Go rebuild" 19:36Z (labels), "all 3" 20:02Z (Maintainer Younes on all three packages), "option 2" 20:25Z
(VS Code fix of the ibus thread joins the release); version 0.9.7 decided by the review. Labels-only 0.9.6.1 before it:
evidence/raw-logs/2026-10-25-release-0.9.6.1/ (never released, archived in dist-archive/0.9.6.1/).

dist-SHA256SUMS-0.9.7.txt, build1-sha256.txt = build2-sha256.txt   two builds, all 11 files byte-identical
lintian.txt                         only Debian keyd's known W wrong-name-for-upstream-changelog
filediff-0961-097-*.txt             every file of each 0.9.6.1 vs 0.9.7 deb by sha256 (debdiff.sh); keyd + mapper all SAME
filediff-096-097-*.txt              same against the released-candidate 0.9.6
code-diff-0.9.6.1-0.9.7.diff        be-azerty-fix and be-azerty-settings as packaged
ibus-skip-offline-097.txt           next-0.9.7-vscode tests on the packaged be-azerty-fix: 54/54
ibus-skip-pkg-cycle-097.txt         extended package cycle (VS Code fixture) on the release deb: 12/12
cloud-run-offline-DISPOSABLE.txt    tests/run-offline.sh DISPOSABLE=1: ALL PASS (its rebuild left dist/SHA256SUMS unchanged)
stick-build-0.9.7.txt, STICKS-SHA256SUMS, CONTENT-*-0.9.7.txt, content-diff-*-0961-097.txt
                                    sticks zorin f6c078a3..., mint 5d189336...; content differs from 0.9.6.1 only in the two
                                    /belgian/ debs, layer be-azerty-fix + be-azerty-settings, md5sum.txt; boot menus = 0.9.6
zorin-0.9.7-*                       UEFI, menu untouched (countdown, Nederlands + period), disc check; probe: packages
                                    0.9.7/.3, CAPS=linux, 0 crosses, automatic skip names VS Code, Terminal + Text Editor
                                    skip; X11. Typed: |@#{[^{}€[]\ |@#{[^{}€[]\ &É &é (expected, Linux Caps)
mint-0.9.7-*                        UEFI, menu waits for Enter, Enter twice; probe: packages 0.9.7/.3, CAPS=windows,
                                    0 crosses; X11. Typed: |@#{[^{}€[]\ |@#{[^{}€[]\ 12 &é (expected)
stick-probe-096.sh, seq.txt, t.sh   probe, key sequence, capture script
Not covered here: VS Code itself (not on the sticks; laptop check by the ibus thread), Wayland, installs, real hardware.
