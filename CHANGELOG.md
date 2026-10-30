# What changed, version by version

A plain-language summary. The technical changelogs are in `packaging/*/debian/changelog`. Versions 0.9.0 to 0.9.7
were made between 23 and 25 October 2026. 0.9.7 is the first public release; the earlier versions were test builds
that were never published. They are listed because the test evidence refers to them.

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
