# How we tested

Short version: **tested in emulators and on one laptop, for Linux Mint 22.3 and Zorin OS 18.1 only**. Nothing has
been accepted by the Linux projects themselves yet. Technical notes are in `NOTES.md`; raw results are in
`evidence/`.

## 0.9.8

0.9.8 changes how `be-azerty-fix` writes the layout lists (Belgian first, nothing removed), switches the optional ibus
skip off by default, uses the keyd-team PPA's keyd, rebuilds the boot image only when needed and cleans every user's
Caps Lock setting on uninstall. These changes were tested in Ubuntu 24.04 test containers, which have the same
packages as Mint 22 and Zorin 18 underneath but no real desktop, no boot and no keyboard hardware:

- `tests/settings-logic.sh`: the list and option logic, saved choices, the ibus skip default and the keyd version
  check, with a stand-in for the settings store (51 checks).
- `tests/lived-in.sh`: a container with systemd and real users whose settings are "lived in": one with US first, a
  Japanese input method and Belgian second plus her own options and launcher, one not logged in with a French second
  layout and the Windows Caps Lock option, one with only a Chinese input method, and one created afterwards. Every
  keyboard setting of every user is compared before and after each step; anything that disappears fails the test.
  Run for a fresh install with the PPA's keyd already present, and for an upgrade from 0.9.7 (including the switch to
  the PPA's keyd), then uninstall, then each package on its own. The same test run on 0.9.7 fails 13 times (it
  removes the US layout and the input methods, and its uninstall also removes the PPA's keyd), which shows the test
  catches the problem.
- `tests/keyd-rules.sh`: the Ctrl+Alt rules fed through keyd's own test program, built from the keyd-team PPA's
  source: the 15 symbols, Ctrl+Alt held for several symbols, AltGr+4/5, and Ctrl+Alt shortcuts (T, Delete, F3,
  arrows) passed through (18 cases).
- `tests/run-offline.sh`: shellcheck, package build, lintian, the Caps Lock table.

A container cannot run keyd (no virtual keyboard device), the login screen, a reboot or a real desktop session, so
those parts of 0.9.8 rely on the earlier emulator and laptop tests below, where the code did not change.

## Where (all versions)

- **Emulators:** QEMU virtual machines, in the cloud and on one laptop (faster, with hardware acceleration). Keys are
  sent to the virtual machine as real key presses, so the system sees a normal keyboard.
- **One real laptop:** a Lenovo ThinkPad T14s. Zorin was started from a USB stick on it (older version 0.9.1), and
  Mint and Zorin ran inside VirtualBox on its Windows 11.
- **Test containers** (from 0.9.8): Ubuntu 24.04 with systemd, see above.

## What (up to 0.9.7)

- Starting from the Belgian USB stick (UEFI and older BIOS mode), installing from it, and the first start after that.
- Typing: every AltGr and Ctrl+Alt symbol, Caps Lock, the numpad and dead keys (ê, ë, ñ …), mostly in the Terminal
  and the text editor; the symbols also in VS Code and a browser (Firefox on Mint, Brave on Zorin).
- Staying Belgian: login screen, desktop, reboot, log out and in, new users, reset settings, a full system update,
  suspend and resume, disk encryption (Zorin).
- Not breaking things: 176 keyboard shortcuts compared with and without the change; the keyboard keeps working when
  keyd is stopped, killed or given a broken configuration; the mouse and touchpad keep working; uninstall gives back
  the stock system.
- Very fast typing (keys sent faster than people type): how often characters swap, before and after each change.
- The packages themselves: rebuilt from source with the same result byte for byte, checked with Debian's lintian, and
  installed, upgraded and removed in a clean system.

What these tests missed: every test machine started with Belgian as its only layout, so none had a second layout or
an input method, and the removal of those by 0.9.7 could not show up. An outside reviewer found it. From 0.9.8 the
lived-in test above covers it.

## Not tested yet

0.9.8 in an emulator or on real hardware; an install from the stick on real hardware; Mint directly on real
hardware; Mint on Wayland; disk encryption on Mint; a second USB keyboard (US or other); keyboards with a built-in
touchpad; the "Belgian keyboard" window on Mint; Ubuntu itself and any other distribution; VS Code from Snap or
Flatpak.

## Reviews

Before 0.9.7, three separate reviews checked the code, the packages, the documents and the test evidence. They were
done with an AI assistant, Claude, in separate sessions that had not written the code. They checked our claims
against our evidence and missed the layout removal; an outside reviewer found it on 26 October 2026. For 0.9.8 a
review starts from "who could this hurt" instead, running as different kinds of users.

## Where the extra US layout in Dutch and German sessions comes from

The running session lists `be,us` in Dutch and German sessions and `be,be` in French ones, although no setting says
so. GNOME Shell 46 (`js/misc/keyboardManager.js`) leaves one slot free in the running keymap and adds the layout of
the display language there, "to ensure that toolkits can handle mnemonics like Alt+Ф even if the user is actually
typing in a different layout". It looks the layout up with GNOME's `get_input_source_from_locale`, which in Ubuntu
24.04 answers `be` for `fr_BE` and nothing for `nl_BE` and `de_BE`; then it uses `en_US`, so `us` (checked in a
test container, 27 October 2026). Cinnamon started as a fork of GNOME Shell; our earlier research traced
the same behaviour there. No key switches to that slot, so it does not change what you type.

## What was tested where, up to 0.9.7

Everything below ran on Linux Mint 22.3 (Cinnamon) and Zorin OS 18.1 (Core) only. "Emulator" means QEMU, either in
the cloud (slow, no hardware acceleration) or on the one test laptop with hardware acceleration ("laptop emulator");
"real hardware" means that laptop itself, a Lenovo ThinkPad T14s. Where a check was run with an earlier test build
and not repeated, the table names that version. What changed between the builds: 0.9.4.1 changed only the README
and changelogs (every program file is byte-identical to 0.9.4). 0.9.6 changed `be-azerty-fix` and the "Belgian
keyboard" window (ibus skip, Caps Lock on Zorin); keyd, its rules and the Caps Lock option itself stayed the same, and
the row "0.9.6 before release" says what was run again with those packages. 0.9.7 adds VS Code to the automatic ibus
skip and finds its current menu file (row "Apps: VS Code"), and changes names and text (copyright holder, the
Maintainer field of all three packages, the status line of this README). The keyd program differs from 0.9.6 only in
its build ID (a checksum that identifies the build; the machine code is the same), and both sticks were rebuilt and
started once more.

| Check | Linux Mint 22.3 | Zorin OS 18.1 |
|---|---|---|
| Live session from the Belgian stick: boot menu, layout, Ctrl+Alt, Caps Lock, numpad | emulator, 0.9.3 UEFI and BIOS, also a stick image written byte for byte (dd); 0.9.4.1 UEFI | emulator, 0.9.3 UEFI and BIOS; 0.9.4.1 UEFI |
| 0.9.4 with the keyd patch (upgrade or fresh install, typing, shortcuts, restarts, Linux profile, uninstall) | emulator, live session, X11 | emulator, live session, X11; with 0.9.6 also installed, Wayland (a fresh install and an upgrade: the test line typed exactly) |
| Real hardware (the T14s) | only inside VirtualBox on Windows 11, first packages (23 Oct) | live session from USB, Xorg and Wayland, VS Code, 0.9.1; inside VirtualBox 7.2.10 on Windows 11 (UEFI), live session from the 0.9.4.1 stick (rebuilt on the laptop from the same ISO and packages), X11, keys sent by a script: boot menu, check, Ctrl+Alt, AltGr, Caps Lock, Terminal and Text Editor right; mouse not tested |
| Installed system: login screen, reboot, log out and in | emulator, first packages (23 Oct) | emulator, encrypted disk, 0.9.1 |
| Install from the Belgian stick and first start | emulator, 0.9.3 (automatic install, BIOS) | emulator, 0.9.3 (UEFI) |
| Disk encryption (Belgian passphrase at boot) | not tested | emulator, 0.9.1 |
| Wayland desktop | not tested | emulator (installed) and the T14s (live) |
| Settings changes, package reinstalls, keyd killed or given a broken config | emulator | emulator |
| Full system update, reboot, suspend and resume | emulator, installed from the stick, 0.9.3 (472 packages upgraded, 32 new) | emulator, installed from the stick, 0.9.3 (413 upgraded, 39 new) |
| New user, wiped desktop settings | emulator | emulator |
| 176 shortcuts compared with keyd off and on | emulator, live | emulator, live and installed |
| UEFI with Secure Boot on | emulator | emulator |
| "Belgian keyboard" window | not tested | emulator |
| Apps: terminal, text editor | yes | yes |
| Apps: VS Code | emulator; ibus skip (0.9.6, switched on by hand): laptop emulator, live, X11 | emulator, the T14s; ibus skip (0.9.6, switched on by hand): laptop emulator, live, X11 |
| Apps: Firefox | emulator | not tested (Brave in the emulator instead) |
| Uninstall back to stock | emulator | emulator |
| Automatic ibus skip of 0.9.6 (fast typing, dead keys; on at login, pause after adding an input method and back after removing it, with a real log out and in; tick box; uninstall) | emulator (cloud and laptop), live, X11 | emulator (cloud and laptop), live, X11; installed, Wayland (a fresh install and an upgrade): on at login and a test line in the Terminal (laptop emulator) |
| Caps Lock on Zorin (Linux by default, `CAPS=windows` switches it on and is kept, all keys typeable after a tap in a password field) | unchanged: Windows Caps Lock (emulator, live, X11, keyd stopped) | emulator, live, Wayland, keyd stopped |
| 0.9.6 before release (final packages and sticks) | packages (in an Ubuntu 24.04 container): rebuilt byte for byte from source, lintian clean, install, upgrade, trigger and remove cycle, Caps Lock table, ibus skip tests (43 offline, 11 package cycle); the sticks' boot checks are recorded outside this README, because it is itself on the sticks (for 0.9.7: `dist/sticks/README.txt`) | same |

The extra tests of 24-25 October (stick boots, browsers, install, full update, suspend) used the 0.9.3 packages from
the sticks; 0.9.4.1 differs from them only in the keyd patch and documentation.

Not tested at all: an install from the stick on real hardware, the keyd patch on real hardware or on an installed
Mint, the automatic ibus skip on real hardware, fast typing with the automatic ibus skip on Wayland or on an installed
system, Mint directly on real hardware, a second USB
keyboard, keyboards with a built-in touchpad (see "Known issues"), Ubuntu itself and any other distribution.


### Display languages (26 October 2026, 0.9.7 sticks rebuilt on the laptop, laptop emulator)

| Check | Result |
|---|---|
| Mint live, Deutsch + Belgian period | passed: German "Belgian keyboard" window, test line exact |
| Zorin live, Deutsch + Belgian period | passed; cosmetic: a column header of the window was cut off (wider window in 0.9.8) |
| Mint live, Français + Belgian period | passed: French window, test line exact |
| Mint live, Deutsch + German QWERTZ | passed: QWERTZ types `y z @ € ß /`, keyd off |
| Mint install in French, Belgian period | passed: installer preselected Belgian; after reboot Belgian only, no French or US layout added |
| Mint install in German, Belgian period | passed: installer preselected Belgian; no German layout added |

Tested display languages so far: Dutch (Zorin), French (Mint live and install), German (Mint live and install, Zorin
live), English (both). Not tested: Zorin installs in French or German, QWERTZ on Zorin.

## Fast typing: the ibus skip

Up to 0.9.7 the skip was on by default with the Windows profile; from 0.9.8 it is off unless the user switches it
on, because no swaps were measured at normal typing speed. The text below is the 0.9.7 README section (it still
describes the old default), kept for its measurements and limits.


Very fast typing can swap two characters while the ibus input method sits between the keyboard and the app (see
"Known issues"; this happens on stock Mint and Zorin too). With the Windows profile, the Terminal, the text editor
(Zorin's Text Editor, Mint's Xed) and VS Code, if it is installed, take the keys without ibus; in those apps these
swaps were not seen. There is nothing to do: it is set up at every login. It is on by default with the Windows
profile, also on Zorin, whose normal session is Wayland. On Wayland it was checked twice, on an installed Zorin in
the emulator on the test laptop (a fresh install from the stick and an upgrade): the Terminal ran without ibus and
typed the standard test line correctly. All the fast-typing measurements ran in X11 sessions. If typing in the Terminal, the Text Editor or VS Code looks wrong on
Wayland, switch it off as described below.

**It steps aside by itself when you need ibus.** ibus is what makes Chinese, Japanese, Korean and similar input
work. At every login the package checks your keyboard settings: if you added such an input (in the keyboard settings
or in ibus's own preferences), or if you use another input system such as fcitx, the Terminal, the text editor
and VS Code keep ibus, until you remove it again. Nothing else is changed.

**To switch it off** (only for your own user): open "Belgian keyboard" from the app menu, click "Fast typing…" and
untick the box. With the Linux-standard profile it is off unless you tick it. For the command line:

```
be-azerty-fix ibus-skip                    # what skips ibus now, and why
be-azerty-fix ibus-skip auto off           # the automatic part off (auto on: back on; auto default: follow the profile)
be-azerty-fix ibus-skip on NAME            # also let another GTK app skip ibus: NAME = its menu file in /usr/share/applications
be-azerty-fix ibus-skip off NAME           # undo that for one app
be-azerty-fix ibus-skip off --all          # nothing skips ibus any more, the automatic part included
```

A change reaches an app the next time it starts: close it completely (every window) and open it again.
`be-azerty-fix check` shows the state too.

**What you keep in those apps:** the Belgian layout, AltGr, Ctrl+Alt as AltGr, your Caps Lock setting, and the dead
keys (`^` `¨` `´` `` ` `` `~` followed by a letter: ê ë é è ñ), which were checked. **What you lose in those apps:**
the ibus emoji picker (and the ibus input methods, which is why it steps aside when you have one). Every other app
keeps ibus.

**What was measured** (emulators, live sessions, keys sent 30 ms apart and overlapping, which is faster than people
type; 100 lines of `@€` x8 with Ctrl+Alt held and 100 with AltGr held, then 20 slower lines and 3 dead-key lines). The
first four rows ran in the slow cloud emulator, the last two in an emulator on a laptop with hardware acceleration,
close to the speed of a real computer:

| Lines with swapped or wrong characters, of the 200 very fast lines | ibus (stock) | app skips ibus |
|---|---|---|
| Zorin OS 18.1, Terminal | 15 swapped | 0 |
| Zorin OS 18.1, a small GTK 4 test window opened from the menu | 2 with a lost or doubled character | 0 |
| Linux Mint 22.3, Terminal | 101 swapped, 2 other | 0 |
| Linux Mint 22.3, a small GTK 3 test window opened from the menu | 141 swapped | 0 |
| Linux Mint 22.3, Terminal, laptop emulator (automatic skip) | 3 swapped | 0 |
| Zorin OS 18.1, Terminal, laptop emulator (automatic skip) | 39 swapped, 9 other | 0 |

With the skip, every line was right, the slower lines (60 ms per key) and the dead-key lines included; with ibus the
dead-key lines were right, and in the cloud emulator a few slower lines swapped too on Mint.

VS Code (1.143.1, Microsoft's own package) was measured once on each system in the laptop emulator, with a shorter
test of 73 lines (10 slower, 30 very fast with Ctrl+Alt, 30 with AltGr, 3 dead-key lines; 560 `€` in all). With ibus
only 15 lines (Mint) and 20 (Zorin) came out right: many Enter presses turned into an extra `€`. With VS Code
skipping ibus, all 73 lines were right on both. These are emulator runs
with keys sent faster than people type, so the counts compare the two settings; they are not how often it happens
when you type on a real machine. For each run the test
recorded that the app really ran without ibus (the input-method module GTK picked), not only that the setting was
there.

**Limits, honestly.**
- It is a workaround, not a fix: ibus still has the problem, and the skip only removes ibus from these three apps
  (and any you add).
- It only works for GTK apps (Terminal, Text Editor, Xed and most Mint and Zorin apps) and for VS Code. Qt apps
  ignore it. VS Code was tested as Microsoft's own package (its menu file is `com.microsoft.VSCode.desktop`; older
  ones, `code.desktop`, are found too). VS Code from Snap or Flatpak, VSCodium and other Electron apps were not
  tested.
- Programs started from inside VS Code, such as the shell in its built-in terminal, inherit the skip, unlike
  programs started from the Terminal (checked on Mint and Zorin on 25 October 2026, live sessions in the laptop
  emulator: that shell has `GTK_IM_MODULE=gtk-im-context-simple`).
- If VS Code is installed or updated while you are logged in, its copy is made or brought up to date at the next
  login; until then VS Code uses ibus, or the old copy.
- It applies when the app is started from the menu, the dock or a keyboard shortcut. If you start the text editor by
  typing its name in a terminal, it still uses ibus. The Terminal skips ibus however it is opened, Ctrl+Alt+T
  included. Programs you start from the Terminal do not inherit the skip (checked).
- The check looks at the GNOME and Cinnamon keyboard settings, ibus's own preferences and the session's input-method
  setting. An input method set up some other way is not seen; then switch the automatic part off as above.
- A change of your keyboard settings counts from the next login.
- The setting is `GTK_IM_MODULE=gtk-im-context-simple`. The short form `simple` that is often quoted only works in
  GTK 4 apps: GTK 3 apps, the Terminal among them, ignore it and keep ibus (checked).
- Tested in emulators only (in the cloud and on one laptop), on live sessions in X11, on Mint and Zorin: switching on
  at login, pausing after a Japanese input was added and coming back after it was removed (with a real log out and
  in), the tick box and the uninstall. Also checked twice on an installed Zorin with Wayland (a fresh install from
  the stick and an upgrade): switched on at login, and the Terminal typed the standard test line correctly. Not tested: fast typing on Wayland or on an installed
  system, an installed Mint, real hardware.

**How it works and how to undo it.** For most apps, the package puts a copy of the app's menu file in
`~/.local/share/applications` with `env GTK_IM_MODULE=gtk-im-context-simple` in front of its command and the line
`X-BelgianAzerty-IbusSkip=true`. The Terminal is opened by a background service, so it gets a small setting file for
that service instead (`~/.config/systemd/user/gnome-terminal-server.service.d/zz-belgian-azerty-ibus-skip.conf`).
At every login (`/etc/xdg/autostart/be-azerty-ibus-skip.desktop`) the copies are made again from the current menu
files, so an app update does not leave an old copy behind, and they are removed while the automatic part pauses or
is off. Your choices are kept in `~/.config/belgian-azerty/` (`ibus-skip-auto` for on or off, `ibus-skip` for apps
you added). Only files with the marker are ever changed or removed: if you already have your own copy of an app's
menu file, it is left alone and that app keeps ibus. `be-azerty-fix ibus-skip off --all`, `sudo be-azerty-fix
uninstall` and removing the package all remove every marked file (purging the package also forgets your choices).


## The keyd patch (versions 0.9.4 to 0.9.7 only)

From 0.9.8 this project no longer ships a keyd build: it uses the keyd-team PPA's keyd, without this patch. The
patch is kept as a proposal for keyd upstream (`upstream/keyd/`). The text below is the 0.9.7 README section, for the
record.


From version 0.9.4, the `keyd` package of this project is no longer an unchanged rebuild of Debian's keyd. It
carries **one patch of this project**, clearly labelled:
`packaging/keyd-backport/patches/0012-Keep-AltGr-held-while-a-Ctrl-Alt-layer-is-held.patch` (now `upstream/keyd/keep-altgr-held-while-a-ctrl-alt-layer-is-held.patch`). The package version
in 0.9.7 is `2.5.0-5~ubuntu24.04.3`. (The test builds 0.9.4 to 0.9.6 had the same patch as `2.5.0-5~ubuntu24.04.2`,
with a different Maintainer field; 0.9.3 and earlier had the unchanged `2.5.0-5~ubuntu24.04.1`.)

**What it changes.** While you hold Ctrl+Alt and type several symbols (Ctrl+Alt held, then 2, E, 2, E for `@€@€`),
keyd used to put Ctrl and Alt back down after every key and take them off again before the next one: about 8 key
events per character. With the patch, AltGr simply stays down while Ctrl+Alt is held: 2 events per character, the
same as typing with AltGr. As soon as you press a key that is not a symbol (T, an arrow), keyd puts Ctrl+Alt back
first, so shortcuts such as Ctrl+Alt+T keep working.

**Why.** On Mint and Zorin the ibus input method can swap two characters when keys come very fast (see "Known
issues"). Every extra key event is one more chance for that. Measured in the emulator at extreme speed (keys 30 ms
apart and overlapping; 200 lines, each `@€` eight times; original and patched keyd in alternating rounds):

| Lines typed wrong (swapped characters; one Mint line had an extra `@`) | Ctrl+Alt, keyd without patch | Ctrl+Alt, with patch | AltGr (for comparison) |
|---|---|---|---|
| Linux Mint 22.3 | 88 of 200 | 8 of 200 | 11 and 9 of 200 |
| Zorin OS 18.1 | 37 of 200 | 23 of 200 | 18 and 20 of 200 |

So with the patch, Ctrl+Alt swaps about as often as AltGr does (and AltGr swaps the same with or without this
project: 12 of 240 lines both ways on Zorin). The patch does not fix the ibus problem itself. Details and raw data: `research/FAST-TYPING-SWAPS.md` (section "Test of the keyd change").

**What was checked with the 0.9.4 packages** (in the emulator on the test laptop, live sessions of Mint 22.3 and
Zorin 18.1, `evidence/raw-logs/2026-10-25-keyd-patch/`): Mint 0.9.3 upgraded to 0.9.4 (keyd restarted by itself with
the new program), Zorin 0.9.4 installed fresh; on both: `be-azerty-fix check` passes (in a live session it shows one
expected ✘ for `/etc/default/keyboard`, which a live session does not write); the standard test line types exactly
`|@#{[^{}€[]\ |@#{[^{}€[]\ 12 &é` (Ctrl+Alt symbols, AltGr symbols, Caps Lock as on Windows); 10 of 10 lines
typed with Ctrl+Alt held came out right (`@€` eight times, 120 ms per key), and keyd's output had 2 key events per character;
Ctrl+Alt+T opens a terminal, also right after typing `@` with Ctrl+Alt still held, and Ctrl+Alt+Right/Left still
switch workspaces after an `@`; the mouse still clicks; 5 keyd restarts each followed by a correct line; the
Linux-standard profile and back; a clean uninstall. Both live sessions ran X11 (Zorin's live session is X11, not
Wayland). The patched keyd also ran on Zorin with Wayland: in the earlier measurement, and on an installed Zorin in
the 0.9.6 retest (a fresh install and an upgrade), where the standard test line with the Ctrl+Alt symbols came out
exactly right; fast typing was not measured there.

**Limits, honestly.**
- Tested in emulators only, not yet on real hardware.
- It only helps while Ctrl+Alt stays held. If you press Ctrl+Alt again for every symbol, nothing changes.
- A mouse click with Ctrl+Alt held, right after a symbol, would see AltGr instead of Ctrl+Alt until the next key
  press (follows from how the patch works; not tested).
- keyd's own test suite: six tests expected the old pattern and were updated in the patch (the typed characters are
  the same); with them, 86 of 86 pass.
- During the measurement, one line in 400 showed a 0.6 s pause in keyd's output, right after the patched keyd was
  put in place.
  It did not come back in six more restart-and-type tries, and we could not tell whether keyd or the emulator
  caused it. In the 0.9.4 test, 10 keyd restarts (5 on each system), each followed by a typed line, showed no
  pause (the longest gap inside a line was 77 ms).
- **The Linux-standard profile is not affected**: it switches the keyd service off, so the patch never runs
  (unless you have keyd configuration of your own: then keyd keeps running for it, patch included). Checked with 0.9.4 on both systems: keyd inactive and disabled, Ctrl+Alt+2 no longer types `@`, AltGr+2 does.
- The patch works for every keyd layer that sends a key with modifiers, not only for Ctrl+Alt. With this project's
  rules that changes nothing else (the only other layer is AltGr itself). If you have keyd configuration of your own,
  its layers that send modified keys also keep those modifiers held while the layer is held.

**Upstream.** Not accepted by keyd, and not proposed yet: a proposal is drafted
(`research/upstream-drafts/keyd-hold-altgr.md`) and will be sent after this release. If your distribution ships its own
keyd, it replaces ours (our version sorts lower on purpose); Ctrl+Alt then still works, just without the patch.

