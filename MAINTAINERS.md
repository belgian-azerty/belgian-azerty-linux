# Maintainer notes: Belgian AZERTY as on Windows (Mint 22 / Zorin OS 18)

For whoever builds, tests, reviews or takes over these pieces, including Mint, Zorin, Ubuntu or Debian maintainers.
User documentation is `README.md`; the technical notes (findings and how to rerun the tests) are in `NOTES.md`; raw
test output is in `evidence/`. Version 0.9.7 (2026-10-25), the first public release; 0.9.0 to 0.9.6 were unpublished
test builds.

## 1. The problem in one paragraph

The Belgian layout (`be` in xkeyboard-config) is correct. What goes wrong for Belgians on Mint and Zorin is around
it: live sessions always start in US (no keyboard choice in the boot menu; Zorin's language Welcome screen even puts
French first); Ctrl+Alt does not act as AltGr (GTK and Qt refuse key presses that still carry Ctrl or Alt as text, see
`gtkimcontextsimple.c`, the consumed-modifier logic is Windows-only); Caps Lock only affects letters; the "Belgian
(Comma)" numpad is not obvious; and the layout is stored in several places (debconf, `/etc/default/keyboard`,
localed, the desktop's own settings, the greeter's settings, schema defaults for new users) that can disagree, which
users experience as "the layout switches back by itself".

## 2. The pieces and where each belongs upstream

| Piece | Path | What it does | Natural upstream |
|---|---|---|---|
| ISO repack tool | `tools/make_belgian_iso.sh` | Adds `keyboard-configuration/layoutcode=be locale=fr_BE.UTF-8` to every casper boot entry (GRUB and isolinux), drops Zorin's `maybe-ubiquity`, updates `md5sum.txt` | Mint / Zorin ISO builds (a "Belgian" boot entry), casper |
| Ubiquity patch (draft, not run) | `upstream/ubiquity-indicator-keymaps-honour-layoutcode.patch` | Welcome screen keeps a layout chosen on the boot line | Ubiquity (Zorin) |
| `keyd` backport | `packaging/keyd-backport/build.sh` | Rebuild of Debian's keyd 2.5.0-5 for Ubuntu 24.04 ("noble") plus one labelled patch (`patches/0012-*`, from 0.9.4; README "The keyd patch"), version `2.5.0-5~ubuntu24.04.3` (sorts below Debian's, so a distribution keyd always wins) | Ubuntu (sync keyd from Debian) |
| `keyd-belgian-windows` | `packaging/keyd-belgian-windows/`, config `keyd/be-winaltgr.conf` | Ctrl+Alt+key = AltGr+key for the 15 AltGr keys of Windows "Belgian (Period)"; AltGr+4/5 = { [ as on Windows; `Restart=on-failure` drop-in | keyd (as an example config), or Mint/Zorin as an optional package |
| `belgian-azerty-windows` | `packaging/belgian-azerty-windows/`, symbols `xkb/symbols/be_capslock` | XKB option `caps:be_windows` (Caps Lock = Shift level on the main block, as Windows KBDBE/KBDBENE CAPLOK) and the `be-azerty-fix` command | xkeyboard-config (the option itself; it generalises `caps:digits_row` from 2.42), Mint (new-user defaults) |
| `be-azerty-fix` | `be-azerty-fix.sh` (installed as `/usr/sbin/be-azerty-fix`) | `check`, `live`, `system`, `uninstall`; see `man be-azerty-fix` | Mint/Zorin keyboard settings tools, in spirit |

All changes are additive and reversible. Nothing patches distribution files in place: the one distribution file we
must extend (xkb-data's `rules/evdev`) is diverted, see 4.2.

## 3. Building

On Ubuntu 24.04 with `build-essential debhelper devscripts lintian dh-python python3 scdoc curl`:

```
packaging/build-all.sh            # -> dist/: .deb + source package (.dsc, .tar.xz) of each package, SHA256SUMS, lintian
packaging/build-all.sh --no-keyd  # only our two packages
```

`MAINTAINER="Name <mail>" COPYRIGHT_HOLDER="Name" SOURCE_URL=https://...` fill the placeholders in `debian/control`,
`debian/changelog` and `debian/copyright`. The defaults are: licence MIT, maintainer
`Younes <linuxbelgiumkeyboard.rc0g4@aleeas.com>`, copyright holder "Younes from Belgium" (the test builds up to 0.9.6
named "Belgian AZERTY for Linux maintainers" instead); `SOURCE_URL` stays a placeholder until the project's
public address is known. The keyd backport
downloads Debian's three source files from deb.debian.org and checks their SHA-256 sums before building; Debian's
upstream test suite (`make test-io`) runs during the build. lintian is clean for our two packages; Debian's keyd has
one Debian-side warning (`wrong-name-for-upstream-changelog`), kept unchanged on purpose. Two builds give
byte-identical packages: `keyd-backport/build.sh` pins the changelog date that the backport step (`dch`) writes,
which was the only difference between two builds before that fix (found by the second review, 2026-10-24). The 0.9.7
packages were built twice with the same result (`evidence/raw-logs/2026-10-25-release-0.9.7/`).

## 4. Design decisions (and why)

### 4.1 keyd for Ctrl+Alt, not XKB
An XKB-only approach (a key type that maps Control+Mod1 to level 3) changes the keysym, but GTK and Qt still see Ctrl
and Alt in the modifier state and refuse the character (measured: `evidence/real-mint-08b-...png`). keyd rewrites
the events below X11 and Wayland, so every toolkit, the console and the greeter see a real AltGr. Debian renames the
binary to `keyd.rvaiya` (Debian bug #1098982); the service stays `keyd.service` and the configuration
`/etc/keyd/*.conf`. `be-winaltgr.conf` uses `[ids] *`: every keyboard, every layout (documented in the README).
A plain `apt remove keyd-belgian-windows` keeps the conffile and keyd keeps using it; `purge` removes it (the
postrm restarts keyd so the purge takes effect at once). The package's systemd drop-in sets `Restart=always` and
`SuccessExitStatus=2 15`: keyd ends with exit status 15 on SIGTERM (`signal(SIGTERM, exit)` in `keyd.c`), which systemd
would otherwise report as "failed" after every `systemctl stop keyd`. A plain `apt purge keyd` still leaves one
"failed" record, because dpkg removes our drop-in before keyd's own prerm stops the daemon; `be-azerty-fix uninstall`
clears it with `systemctl reset-failed`.

### 4.2 Caps Lock option: package-owned symbols, diverted rules
The symbols file `/usr/share/X11/xkb/symbols/be_capslock` is a new file owned by the package. The option also needs
one rule in `/usr/share/X11/xkb/rules/evdev`, a file of xkb-data. The package diverts it (`dpkg-divert --no-rename
--divert evdev.distrib`), so xkb-data upgrades write `evdev.distrib`, and a dpkg file trigger
(`interest-noawait /usr/share/X11/xkb/rules`) regenerates `evdev` = `evdev.distrib` + our three lines
(`/usr/lib/belgian-azerty-windows/update-xkb-rules`, one atomic rename). Consequences, all tested in
`tests/pkg-cycle.sh`: the rule survives xkb-data reinstalls by apt **and** by plain `dpkg -i`; `dpkg -V xkb-data`
stays clean; purge gives back xkb-data's file byte for byte. The rules file is never missing, not even for a moment
(copy + `--no-rename`). An option name the rules do not know is ignored by libxkbcommon, Xorg and ckbcomp, so a
leftover `caps:be_windows` in someone's settings after an uninstall only means Linux Caps Lock, never a broken
keyboard. When the package is removed, its postrm also takes `caps:be_windows` out of `XKBOPTIONS` in
`/etc/default/keyboard` (keyboard-configuration's config script reads that file as the current value), so a plain
`apt purge` leaves only users' own desktop settings with the unused name. Earlier versions of `be-azerty-fix.sh` appended the rule by hand and kept it with an apt hook; the
package's postinst and `be-azerty-fix system` remove those leftovers.

### 4.3 Cinnamon defaults for new users
Mint ships a schema default `org.cinnamon.desktop.input-sources xkb-options=['terminate:ctrl_alt_bksp']`
(mint-artwork). Cinnamon applies it for every user without a setting of their own, on top of the X server's options
from `/etc/default/keyboard`, so a new user (or a reset) lost Caps Lock and Comma while the layout stayed Belgian
(found by the first review). `be-azerty-fix system` writes `/usr/share/glib-2.0/schemas/zz_belgian-azerty-windows.gschema.override`
with the distribution default plus our options (computed, so `DECIMAL`/`CAPS` choices are honoured; read with
`GSETTINGS_BACKEND=memory`) and recompiles the schemas. The `zz_` prefix makes it win over mint-artwork's override.
It is generated, not shipped, because its content depends on the user's choices; `uninstall` and the package's postrm
remove it. GNOME (Zorin) has no such schema default and follows `/etc/default/keyboard`, so nothing is written there.

### 4.4 Which store wins where (short)
Console and LUKS prompt: `/etc/default/keyboard` via console-setup and the initramfs. LightDM greeter: the X server's
options from `/etc/default/keyboard`. GDM: same, unless the gdm user has its own `input-sources` (cleared by
`system`). Cinnamon session: libgnomekbd + `org.cinnamon.desktop.input-sources` (user value, else schema default).
GNOME session: `org.gnome.desktop.input-sources` (user value, else localed/`/etc/default/keyboard`). The details are in
`NOTES.md`, section 5.

### 4.5 ISO tool
It edits only boot menus (text files) and the checksum list, with xorriso, keeping the original boot records
(`-boot_image any replay`); BIOS and UEFI both boot (UEFI checked in the review). Running it twice changes nothing;
running it on an ISO built by an older version repairs the checksum list. It checks its own output (every changed
menu against the new `md5sum.txt`) and fails loudly on any xorriso error.

## 5. Testing

| What | How | Where the evidence is |
|---|---|---|
| Static checks, package build, lintian, Caps table, ISO checksums | `tests/run-offline.sh [ISO...]` | `evidence/raw-logs/fix-round/run-offline.txt` |
| Install / upgrade / trigger / purge | `sudo DISPOSABLE=1 tests/run-offline.sh` (throwaway system only) | `evidence/raw-logs/fix-round/pkg-cycle-container.txt` |
| Live, installer, installed systems, durability, shortcut check | QEMU test scripts in `rig/` (one VM at a time), see NOTES "How to rerun these tests" | `evidence/` |
| Real hardware (fast typing, VS Code) | `T14S-TEST-PLAN.md` + `t14s-test/` | run once with 0.9.1 (Zorin live session from USB): `evidence/t14s/` |

The test scripts type raw scancodes into QEMU (`rig/qemu_rig.py keys/type`), so the guest sees a real keyboard. In
the cloud, without hardware acceleration (KVM), this is about 20 times slower than real hardware; with KVM, in WSL 2
on the test laptop, it is close to real speed (`RIG-SPEED.md`).

## 6. Known limits

See README "Known issues". The open one that matters is the order of fast-typed characters with ibus: stock ibus
behaviour that keyd's extra key events made more frequent (the keyd patch brings Ctrl+Alt back to the AltGr level;
the Terminal, the text editor and VS Code skip ibus). A measurement on real hardware with a key log is still to do.

## 7. Before any release

1. `tests/run-offline.sh` on both Belgian ISOs: ALL PASS.
2. The emulator checks in NOTES.md ("How to rerun these tests") for every changed piece.
3. A test on real hardware (`T14S-TEST-PLAN.md`).
4. A separate re-review.
5. Check `MAINTAINER`, `COPYRIGHT_HOLDER` and `SOURCE_URL`.
6. Re-check the upstream trackers (xkeyboard-config, GTK, Ubiquity/subiquity, Mint, Zorin) for changes.
