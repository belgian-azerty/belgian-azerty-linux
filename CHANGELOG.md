# What changed, version by version

A plain-language summary. The technical changelogs are in `packaging/*/debian/changelog`. Versions 0.9.0 to 0.9.7
were made between 23 and 25 October 2026. 0.9.7 is the first public release; the earlier versions were test builds
that were never published. They are listed because the test evidence refers to them.

## Not released yet (after 0.9.12)

Nothing changes on Linux Mint, Zorin OS, Ubuntu or Debian: the keyboard types exactly as with 0.9.12.

- **Package files for Fedora, openSUSE and Arch Linux**, to build yourself (`packaging/OTHER-DISTRIBUTIONS.md`):
  `belgian-azerty-windows` and `keyd-belgian-windows` for each, plus keyd 2.6.0 for Fedora (Fedora has no keyd
  package). They put the rules in `/etc/xkb` only and change no file of the system. Built from the v0.9.12 release
  archive. Tested in test containers only; nothing published.
- **`be-azerty-fix` knows Fedora**: the system default through systemd-localed (`/etc/vconsole.conf`), the boot image
  with dracut, the files in `/etc/xkb`, packages with rpm and dnf, GDM's Fedora paths. The Debian/Ubuntu part is
  unchanged. On systems it does not know (openSUSE, Arch, Fedora's relatives) it now stops and changes nothing; before,
  it would have treated them as Debian. Not in the Fedora package yet: run `be-azerty-fix.sh` from the repository.
- New tests: `tests/rpm-cycle.sh` (Fedora and openSUSE), `tests/arch-cycle.sh` (Arch), `tests/fedora-fix.sh`.
- **A script for systems without a package** (NixOS, Gentoo, Slackware, Void, Solus):
  `packaging/etc-xkb/be-azerty-etc-xkb.sh install|remove|status` puts the two files in `/etc/xkb` and takes out only
  its own. Tested in test containers with each system's own keyboard library and data; only for Wayland desktops.
- **SELinux: Fedora and openSUSE package 0.9.12-2.** On Fedora 45 with SELinux on, 0.9.12-1 made `localectl` refuse
  every layout (systemd-localed may not read files labelled `etc_t`, the label `/etc/xkb` gets), so the login screen
  stayed US. 0.9.12-2 adds a small SELinux rule (`packaging/selinux/belgian_azerty_xkb.cil`) that gives `/etc/xkb`
  the label `usr_t`, as the system's own keyboard files have; it is added on install and removed with the package. The
  `/etc/xkb` script does the same when SELinux is on. Tested with SELinux enforcing on Fedora 45 and openSUSE Leap 16.0
  in a virtual machine on one laptop (login screen Belgian, Caps Lock as on Windows), and in test containers.

## 0.9.12

The upgrade fix; the keyboard types exactly as with 0.9.11.

- **A system upgrade to Ubuntu 26.04, Linux Mint 23 or Debian 14 goes through with the package installed.** Those
  upgrades bring xkb-data 2.46 or later, which turns `/usr/share/X11/xkb` into a link to `/usr/share/xkeyboard-config-2`
  and refuses to do so while the folder holds files of another package. The package keeps two there (its Caps Lock
  file and xkb-data's diverted rules file), so with 0.9.11 and earlier the upgrade stopped half-way, with many packages
  left unconfigured. 0.9.12 adds an apt setting that runs `/usr/lib/belgian-azerty-windows/xkb-move` around dpkg:
  just before an xkb-data 2.46+ install it gives xkb-data its own rules file back and takes the Caps Lock file out; just
  after, it puts both back under the real name. It never stops apt and does nothing once the package is removed. Not
  covered: installing the new xkb-data with a plain `dpkg -i`.
- The README inside the package now has the upgrade note (0.9.11's package carried the README from before the note).
- New test `tests/release-upgrade.sh` (full package upgrade of the whole system, four situations).

## 0.9.11

Preparation for the next Ubuntu base; on Mint 22.3 and Zorin 18.1 the keyboard types exactly as with 0.9.10.

- **The rules stay after a keyboard-data update on Ubuntu 26.04.** From xkb-data 2.46 (Ubuntu 26.04, the base Linux
  Mint 23 will use; Debian made the same change), the keyboard files live in `/usr/share/xkeyboard-config-2` and
  `/usr/share/X11/xkb` is only a link to it. The package protected the rules file under the old name, which the package
  system no longer knows, so an update of xkb-data removed the Caps Lock, accents and Apple rules: Linux Caps Lock and
  accents came back until the package was installed again. The keyboard itself kept working. 0.9.11 protects the real
  name, follows updates in the new folder, and when updating from 0.9.10 cleans up the old protection. Found while
  trying the packages on Ubuntu 24.04, Ubuntu 26.04 and Debian 13 in test containers.
- **Known problem (fixed in 0.9.12): upgrading the system.** On Ubuntu 24.04 with the package installed,
  the update to xkb-data 2.46 (part of an upgrade to Ubuntu 26.04, Linux Mint 23 or Debian 14) stops with an error:
  xkb-data can only turn `/usr/share/X11/xkb` into a link when that folder holds nothing but its own files, and the
  package keeps its Caps Lock file and the rules diversion there. Remove the package before such an upgrade
  (`sudo apt remove belgian-azerty-windows`), install it again afterwards and run `sudo be-azerty-fix system` again.

## 0.9.10

A small fix release; the keyboard itself types exactly as with 0.9.9.

- `sudo be-azerty-fix system` no longer says "only 4 layouts fit in the system default: be left out" when Belgian is the
  only layout, and `be-azerty-fix live` no longer says a layout is missing from the running X session (wrong messages
  since 0.9.8; nothing was left out and the layout was never changed). Found in the laptop test of 0.9.9.
- Correction: the 0.9.9 README (and its "Known issues") said that the text console and the disk unlock prompt follow
  the Apple layout with `APPLE=yes`. That was wrong: they keep the PC layout, as the package changelog said. The
  console tool (`setupcon`) reads the general rules file, which this project does not change, so it ignores this
  project's options. Found by the "try to break it" review of 0.9.10 with the console tool itself; the 0.9.9 check
  had used the keymap tool in a way the console never does.

## 0.9.9

- **Shift+AltGr accents as on Windows.** With the Windows profile, Shift+AltGr on the `ù`, `µ` and `=` keys gives
  `´`, `` ` `` and `~`, the same accents as AltGr, as on Windows. Linux gives caron, breve and dot above there; the
  Linux-standard profile and `ACCENTS=linux` keep those. Only the standard Belgian layout changes, wherever it sits in
  the list of layouts. If you update from 0.9.8, your accents stay as they were until you choose `ACCENTS=windows`.
- **Accent then space, optional and per user.** `be-azerty-fix accent-space on` makes `´` then space give `´` and
  `¨` then space give `¨`, as on Windows, in GTK apps and the ibus input method. A `~/.XCompose` of your own is never
  changed. Refused next to a "US international"-type layout.
- **Belgian Apple keyboards, optional.** `APPLE=yes` types the characters printed on a Belgian Apple keyboard (from
  Unicode CLDR's macOS data); `be-azerty-fix apple-iso-keys on` fixes keyboards whose key left of 1 and key next to
  left Shift come out swapped. Refused without a connected Apple keyboard, because it changes every keyboard and the
  login screen. Not tested on a real Apple keyboard.
- In a test container, 306 of the 308 Windows Belgian characters compared now come out the same (0.9.8: 272; without
  accent-space: 302), and nothing that matched in 0.9.8 changed.
- Uninstall and removing the package take all of this project's keyboard options out of every setting, and remove the
  Apple key setting.
- Found by an independent "try to break it" review of this version before release, and fixed: updating from 0.9.8
  would have changed your Shift+AltGr accents without asking; `APPLE=yes` on a PC keyboard (or with only an Apple
  mouse) would have changed every keyboard and the login screen; the new options hit the first layout even when
  Belgian was second; accent-space ignored `XCOMPOSEFILE`, a link of your own and US international layouts; the Apple
  key setting outlived uninstall; the boot image was rebuilt on every `apple-iso-keys` run.

## 0.9.8

- **Your other layouts and input methods are kept.** 0.9.7 replaced the list of layouts with Belgian only when you
  ran `sudo be-azerty-fix system` (also through the Period/Comma choice in the "Belgian keyboard" window), so a second
  layout or a Chinese or Japanese input method was lost. Now Belgian is put first and everything else stays, in the
  desktop settings, the running session and the system default. Found by an outside reviewer.
- **keyd comes from the keyd-team PPA** instead of this project's own build, so it gets updates. The extra keyd patch
  of 0.9.4-0.9.7 is no longer shipped; it is now only a proposal for keyd (`upstream/keyd/`). 0.9.7 users switch with
  `sudo be-azerty-fix switch-keyd` after adding the PPA. Uninstall no longer removes a keyd you installed yourself
  (0.9.7 removed the PPA's keyd too).
- **The fast-typing ibus skip is off unless you switch it on.** No swaps were measured at normal typing speed, so it
  should not be on for everyone. Users who never chose lose it at their next login.
- Found by a second, independent review of this version before release, and fixed: an empty layout list on Mint
  (meaning "use the system default") was replaced by Belgian only, so a second layout of the system default was
  lost there; it is now filled from the system default. Also: a Belgian variant the user already has (be+oss) stays
  the Belgian entry; the system default keeps at most four layouts and says which one is left out; users who are not
  logged in get their stored settings changed instead of a wrong "follows the system default"; `check` accepts
  Belgian first with other layouts; the packages could not find keyd when apt answered in Dutch or French; a warning
  when the user has their own keyd configuration (keyd uses one per keyboard); uninstall keeps the old keyd build
  when the user's own keyd configuration or another package still needs it; uninstall no longer writes Cinnamon
  options for users who never had the Caps Lock option, and includes users with high user numbers; the window keeps
  a Caps Lock choice made with `CAPS=` when only the numpad key changes; `switch-keyd` exits with an error when it
  cannot switch.
- Found by the laptop test (Zorin and Mint installed in an emulator, upgraded from 0.9.7), and fixed: on Mint,
  `switch-keyd` and the install found no PPA keyd, because Mint's `add-apt-repository` does not refresh the package
  lists (the install steps now include `sudo apt update`, and both commands refresh the lists themselves); the
  "Belgian keyboard" window did not open at all when its language was not installed (it now falls back to English,
  and shows zenity's error instead of quitting without a word).
- **Faster reruns:** when nothing needs changing, nothing is reconfigured and the boot image is not rebuilt.
- **Uninstall cleans every user's Caps Lock setting**, also users who are not logged in.
- The "Belgian keyboard" window is wider (a German column header was cut off).
- Shorter README, with "Only the parts you need"; the test tables moved to `HOW-WE-TESTED.md`. Unused files of an
  abandoned first approach (`xkb/types/winaltgr`, `xkb/rules/`) were removed.
- New tests: `tests/settings-logic.sh`, `tests/lived-in.sh` (lived-in profiles, "take nothing away"),
  `tests/keyd-rules.sh`.

## 0.9.7 — first public version

- **VS Code** also skips the ibus input method by itself now, like the Terminal and the text editor. In the tests this
  stopped the extra or missing `€` that very fast Ctrl+Alt typing caused in VS Code.
- The setting now finds current VS Code (its menu file was renamed by Microsoft).
- Names and text: the packages name "Younes" as maintainer and "Younes from Belgium" as copyright holder, and the
  README says how far the project was tested.

## 0.9.6

- **Fast typing:** the Terminal and the text editor skip the ibus input method by themselves, which in our tests
  removed the swapped characters that very fast typing could cause there. It steps aside on its own when you use an input method
  that needs ibus (Chinese, Japanese, Korean and similar). A tick box in the "Belgian keyboard" window switches it off.
- **Caps Lock on Zorin:** Zorin now keeps the normal Linux Caps Lock unless you switch the Windows one on
  (`sudo CAPS=windows be-azerty-fix system`). Reason: a GNOME problem where a Caps Lock tap in a password field could
  make six keys stop typing with the Windows Caps Lock. Mint keeps the Windows Caps Lock.

## 0.9.5 (not released)

- First version of the fast-typing change above.

## 0.9.4 and 0.9.4.1

- **Ctrl+Alt symbols are steadier when you type fast.** While you hold Ctrl+Alt for several symbols, keyd now keeps
  AltGr down instead of pressing and releasing Ctrl and Alt for every character. This is one small, labelled change to
  keyd, to be offered to the keyd project after this release.
- 0.9.4.1 changed only the documentation.

## 0.9.3

- **"Belgian keyboard" window** in the app menu (Nederlands, Français, Deutsch, English): choose the Windows-style
  profile or the standard Linux behaviour, and a period or a comma on the numpad.
- **Live USB that starts with the Belgian keyboard:** a tool that adds Belgian boot-menu entries to the official Mint or Zorin ISO.

## 0.9.2

- **Two profiles:** the Windows-style profile (default) and a Linux-standard profile that keeps the Belgian layout
  with normal Linux behaviour.

## 0.9.1

- Running the setup again keeps your earlier choices (period or comma, Caps Lock).
- Fixes for Wayland sessions and for removing the package cleanly.

## 0.9.0

- First packaged version: Ctrl+Alt as AltGr, Caps Lock as on Windows, Belgian (Period) or Belgian (Comma), and the
  layout kept Belgian everywhere (login screen, desktop, new users). An `uninstall` command puts the system back.
