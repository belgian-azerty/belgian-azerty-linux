# Belgian AZERTY that works as it does on Windows, for Linux Mint and Zorin OS

The Belgian keyboard layout itself has been correct on Linux for a long time. What is missing is the Windows
behaviour that Belgians are used to, and a live USB that starts with the Belgian keyboard already set. This project adds:

| Habit from Windows | What it does here | Part of the project |
|---|---|---|
| Live USB and installer start with the Belgian keyboard | Repacked ISO whose boot menu asks for the language, then the Belgian keyboard (period or comma) | `tools/make_belgian_iso.sh` |
| Ctrl+Alt works as AltGr | Ctrl+Alt+2 = @, Ctrl+Alt+E = €, Ctrl+Alt+9 = {, ... on the 15 AltGr keys; other Ctrl+Alt shortcuts unchanged. AltGr+4 and AltGr+5 also give `{` and `[` as on Windows (Linux gives `¼` `½`) | package `keyd-belgian-windows` (rules for the keyd daemon) |
| Caps Lock as on Windows | Caps Lock gives the Shift character on the whole main block (1 2 3 ... ° _ % £ ? . / +); the ² and < keys, AltGr and the numpad are unchanged. On by default on Mint; on Zorin you switch it on yourself (see "Caps Lock on Zorin") | package `belgian-azerty-windows` (XKB option `caps:be_windows`) |
| "Belgian (Period)" or "Belgian (Comma)" | Numpad decimal key types `.` or `,` | `be-azerty-fix` (`DECIMAL=comma`, standard option `kpdl:comma`) |
| The layout never switches by itself | Every place where the system stores the layout says Belgian, also for new users and after a settings reset | `be-azerty-fix system` |

**Status.** Version 0.9.7, the first public release. This is a long-standing problem that no project owns. The fix
was tested in emulators and on one laptop, for Linux Mint 22.3 and Zorin OS 18.1 only (on that laptop: Mint inside
VirtualBox, and Zorin started from USB and inside VirtualBox). A separate review is done (see
`HOW-WE-TESTED.md`), and nothing has been accepted upstream yet. The goal is for Linux Mint, Zorin OS and the projects they build on to adopt these fixes
themselves (`MAINTAINERS.md` says which piece belongs where); until then this is an unofficial community project.

Versions 0.9.0 to 0.9.6 were test builds and were never published (`CHANGELOG.md`). Some checks were run with one of
them, and "What was tested where" names the version each time. The newest parts were tested in emulators only: the
automatic ibus skip in the Terminal, the text editor and VS Code (see "Fast typing: the Terminal, the text editor and
VS Code skip ibus"), the Linux Caps Lock as the default on Zorin (see "Caps Lock on Zorin") and the keyd patch (see
"The keyd patch"). The runs on real hardware (the laptop) used older versions. See also "Known issues".

## Install on an installed system

Download the three packages from `dist/` (or from the release page) into one folder, open a terminal there, then:

```
sudo apt install ./keyd_*.deb ./keyd-belgian-windows_*.deb ./belgian-azerty-windows_*.deb
sudo be-azerty-fix system                    # Belgian (Period); Windows Caps Lock on Mint (on Zorin see below)
sudo DECIMAL=comma be-azerty-fix system      # Belgian (Comma) instead
sudo CAPS=linux be-azerty-fix system         # keep the Linux Caps Lock
sudo CAPS=windows be-azerty-fix system       # Windows Caps Lock on Zorin too (read "Caps Lock on Zorin" first)
sudo PROFILE=linux be-azerty-fix system      # Linux-standard profile (see below)
```

Then log out and back in. `be-azerty-fix check` shows what every setting says. Running `sudo be-azerty-fix system`
again later (for example to repair settings) keeps your earlier Period/Comma and Caps Lock choice; give `DECIMAL=` or
`CAPS=` only to change it. Mint 22 and Zorin 18 (both based on Ubuntu 24.04) have no keyd package of their own,
so `keyd_*.deb` provides one: a rebuild of Debian's keyd package with one clearly labelled patch of this project (see
"The keyd patch" below). If your distribution ships its own keyd, it replaces this one automatically.

## Two profiles: Windows (default) and Linux-standard

| | Windows profile (default) | Linux-standard profile |
|---|---|---|
| Layout | Belgian, everywhere, never switches by itself | same |
| Period / Comma on the numpad | your choice (`DECIMAL=`) | same |
| Caps Lock | as on Windows (whole main block) on Mint; on Zorin Linux unless you add `CAPS=windows` | Linux: letters only |
| Ctrl+Alt+2, Ctrl+Alt+E ... | `@`, `€` ... as on Windows (keyd) | plain Ctrl+Alt; use AltGr for `@` and `€` |
| Switch | `sudo PROFILE=windows be-azerty-fix system` | `sudo PROFILE=linux be-azerty-fix system` |

The easiest way to switch is the **Belgian keyboard** entry in the app menu (Belgisch toetsenbord, Clavier belge,
Belgische Tastatur): one window with the four combinations of profile and numpad decimal key (period or comma). It
asks for your password and runs the same `be-azerty-fix system` as the commands above.

The Linux-standard profile switches the keyd service off and leaves the packages installed, so switching back is one
command. The choice is saved and survives reruns of `be-azerty-fix system` and package updates; `be-azerty-fix check`
shows the current profile. `CAPS=` can still be set on its own (for example `PROFILE=linux CAPS=windows`). If you
have your own keyd configuration besides ours, the Linux profile leaves keyd running and says so.

### Caps Lock on Zorin

On Zorin (GNOME) the Windows profile keeps the Linux Caps Lock (letters only), because of a GNOME problem: in
Zorin's normal session (Wayland), a short press of Caps Lock in a GNOME password field (the lock screen, or the
window that asks for your password before updates) puts Caps Lock out of step until you log out. On stock Zorin
that only swaps upper and lower case. With the Windows Caps Lock it also stops `2 6 7 9 0` and `%` from typing on
the main block (they give `é § è ç à ù`). If you want the Windows Caps Lock anyway, run
`sudo CAPS=windows be-azerty-fix system`; if the keys stop working, log out and back in. Ctrl+Alt as AltGr is not
affected. Tested in emulators only (Zorin OS 18.1); a report for GNOME is drafted, not yet sent.

Two things to know. If you used a test build up to 0.9.4.1 on Zorin, the Windows Caps Lock stays on after the
update, because those builds saved it as your choice: run `sudo CAPS=linux be-azerty-fix system` once for the Linux
one. And choosing "Windows" in the "Belgian keyboard" window sets Caps Lock back to Linux on Zorin (the window says
so): to keep the Windows Caps Lock, run the `CAPS=windows` command again afterwards.

## The keyd patch (from 0.9.4)

From version 0.9.4, the `keyd` package of this project is no longer an unchanged rebuild of Debian's keyd. It
carries **one patch of this project**, clearly labelled:
`packaging/keyd-backport/patches/0012-Keep-AltGr-held-while-a-Ctrl-Alt-layer-is-held.patch`. The package version
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

## Fast typing: the Terminal, the text editor and VS Code skip ibus

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

## Uninstall

```
sudo be-azerty-fix uninstall
```

This removes the Caps Lock option from the system default and from your desktop settings, removes the defaults for new
users, removes the ibus skip files of every user, purges the three packages (keyd too, when it is the one from
this project; `KEEP_KEYD=1` keeps it), and removes files left by older test versions. The keyboard stays Belgian, because the
Belgian layout and the Period/Comma choice are standard Linux settings. Log out and back in afterwards: on Zorin the
running session still lists the old Caps Lock option name until then (Caps Lock already behaves the Linux way, because
the option files are gone).

Please use `be-azerty-fix uninstall` rather than removing the packages by hand. A plain
`sudo apt purge belgian-azerty-windows keyd-belgian-windows keyd` also works and the keyboard stays Belgian, but it
cannot reach your own desktop settings: they keep the name of the Caps Lock option, which is then ignored (Linux Caps
Lock), and `systemctl --failed` lists the removed keyd service until the next reboot. Use `purge`, not `remove`: after a
plain `remove`, dpkg keeps `/etc/keyd/be-winaltgr.conf` and keyd keeps using it.

## Live USB

**The all-in-one stick** (Linux Mint 22.3 or Zorin OS 18.1, built from the official ISO you downloaded yourself):

```
sudo MENU=b PACKAGES=dist tools/make_belgian_iso.sh linuxmint-22.3-cinnamon-64bit.iso mint-belgian-stick.iso
```

The boot menu first asks for the language (Nederlands, Français, Deutsch, English), then for the keyboard: Belgian
AZERTY with a period or a comma on the numpad, and for Deutsch and English also German QWERTZ. Without a key press it
starts Nederlands with the period after a short countdown, except on Mint started in UEFI mode: that menu has no
countdown and waits (stock Mint does the same), so press Enter twice for Nederlands with the period. English gives English (US) text with Belgian formats (day/month dates, 24-hour
clock, A4, euro, decimal comma). The Belgian entries start with the Windows profile; switch later with the "Belgian
keyboard" window in the app menu. German QWERTZ is plain Linux German: our Windows extras are made for the Belgian
layout and stay off there.

What the tool changes, and nothing else: the boot menu entries (the distribution's other entries, theme and splash stay
as they are), the checksum list for the disc check, one extra file `/casper/zz-belgian-azerty.squashfs` (our packages,
about 6 MB, stacked on top of the distribution's untouched system image) and the packages in `/belgian/` for the
installer. When you install from the stick with the Belgian keyboard, the installer adds the packages and your choice
to the installed system, and the first start finishes the setup once (it rebuilds the boot image; on Mint this
took about 23 minutes in the slow emulator, and should be much faster on real hardware, not measured yet; let it
finish). This is an unofficial, community-made stick,
not made by or affiliated with Linux Mint or Zorin OS, and not continuously maintained; others are welcome to join
the project.

On older PCs that start in legacy BIOS mode the menu is plain text without accents (Belgie, Francais); on Mint's BIOS
menu the list scrolls (it shows six lines).

**Boot menu only** (no packages, no root needed): `MENU=b tools/make_belgian_iso.sh IN.iso OUT.iso` gives the same
menu without the comma entries (the live system cannot set the numpad comma at boot by itself) and English with US
formats. The older one-language form still works: `tools/make_belgian_iso.sh IN.iso OUT.iso` (French, Belgian
keyboard on every entry) or with `"keyboard-configuration/layoutcode=be locale=nl_BE.UTF-8"` for Dutch. On Zorin the
tool skips the language Welcome screen, which would otherwise put a French or Dutch layout first.

## What was tested where

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

## Known issues

- **On Zorin with Wayland, six keys can stop working after Caps Lock in a password field** (only when the Windows
  Caps Lock is switched on by hand with `CAPS=windows`, see "Caps Lock on Zorin"; found 2026-10-25; cause traced to
  GNOME, upstream report drafted). On Zorin OS 18.1 in a Wayland
  session, a short Caps Lock tap inside a GNOME password field (the password dialog before updates or of the "Belgian
  keyboard" window, or the lock screen) puts Caps Lock out of step between GNOME and the apps. It happened every time
  it was tried on Wayland in the emulator (6 of 6) and never in a Zorin X11 session (0 of 5); on Mint (X11) a Caps
  Lock tap on the lock screen did not cause it (one try). On stock Zorin that only flips upper and lower case. With this project's Windows-style Caps Lock, the
  keys `é § è ç à ù` then give only those characters, with or without Shift, in normal apps, so `2 6 7 9 0` and `%`
  cannot be typed on the main block (GNOME's own search and password fields keep working). Not caused by keyd (the
  same with keyd stopped). Recovery: log out and back in (the sure way); tapping Caps Lock once more in a password
  field usually restores it too (seen in one clean run); `ibus restart` does not help. To avoid it: keep the Linux Caps Lock, which is the default on Zorin
  (`sudo CAPS=linux be-azerty-fix system` returns to it). Details: `research/CAPS-DIALOG-DESYNC.md`.
- **Zorin's login screen can ignore the keyboard on the first boot after installing** (seen once, in the emulator,
  on stock Zorin OS 18.1 before any of this project was installed): the mouse works, typing does nothing, and the
  journal shows ibus errors ("InputContext ... does not exist") from two ibus copies started at the same moment. A
  restart (or `sudo systemctl restart gdm3` from a text console, Ctrl+Alt+F3) fixes it; it did not come back on later
  boots. Not caused by this project; reported here because a user would see it as "the keyboard does not work".
- **Very fast typing can swap two characters** while the ibus input method runs (it runs by default on Mint and
  Zorin): `@€` can arrive as `€@`. This also happens without this project, with AltGr. In the emulator it was rare at
  ordinary speeds and common only at extreme speed (keys 30 ms apart and overlapping: up to about 1 line in 10 with
  AltGr). Until 0.9.3, Ctrl+Alt swapped more often than AltGr at extreme speed; with the keyd patch of 0.9.4 it swaps
  about as often as AltGr (see "The keyd patch"). Stopping ibus removes it, but ibus is needed for some input
  methods. Measured in emulators; on real hardware not measured yet. Details: `research/FAST-TYPING-SWAPS.md`. From
  0.9.6 the Terminal and the text editor (and VS Code from 0.9.7) skip ibus automatically when you have no input
  method that needs it (see
  "Fast typing: the Terminal, the text editor and VS Code skip ibus").
- **VS Code (and possibly other Electron apps) sometimes drops the € of Ctrl+Alt+E** (about 1 in 4 on Mint in the
  emulator; on Zorin only with fast typing). Same cause as above: with ibus in synchronous mode for VS Code it did
  not happen once in 72 tries. In the same runs AltGr+E typed correctly. From 0.9.7 VS Code skips ibus automatically
  (see "Fast typing"); in the laptop emulator that typed all 560 `€` of a fast test right on both systems. Firefox (Mint) and Brave (Zorin) typed the Ctrl+Alt symbols correctly in
  the emulator; other Electron apps were not tested.
- **Dual boot with Windows: the clock can be two hours off** (not a keyboard issue, seen on the test laptop): Windows
  keeps the hardware clock in local time, Linux expects UTC, so the live session started two hours ahead until the
  network corrected it. On an installed dual-boot system the usual fix is `timedatectl set-local-rtc 1` on Linux, or
  making Windows use UTC.
- **On Linux Mint, Ctrl+Alt+Backspace ends the whole session at once** (Mint's installer switches this X option,
  `terminate:ctrl_alt_bksp`, on; unsaved work is lost). It looks like a sudden reset to the login screen. Not caused
  by this project, which keeps the option as Mint set it.
- **Some app shortcuts follow the key position, not the letter**: VS Code and other Electron apps can read a
  shortcut by where the key sits on a US keyboard, so a shortcut shown as Ctrl+/ or Ctrl+` may sit on a different key
  on AZERTY. Same on any non-US layout; not caused by this project.
- **Windows programs under Wine and remote desktop sessions (xrdp, VNC) were not tested.** They handle the keyboard
  themselves, so the Belgian layout and the Ctrl+Alt rules may not reach them as on the desktop. Planned for later.
- **Keyboards with a touchpad or mouse built into the same device** (some keyboard+touchpad combinations, some
  wireless receivers, some gaming mice with extra keys): keyd takes over every input device that has a full set of
  keyboard keys, also when that same device reports pointer movement. It then passes the pointer on through its own
  virtual pointer, without high-resolution scrolling and without multi-finger touch, so smooth scrolling and touchpad
  gestures may stop working on such a device while keyd runs. This follows from keyd's code; no such device was
  tested. Normal laptop touchpads and TrackPoints are separate devices and keyd leaves them alone (checked on the
  T14s and in the emulators). If you have such a device: `sudo journalctl -b -u keyd | grep match` lists the devices keyd
  took, with their id; add the line `-ID` (a minus sign and that id) under `*` in `/etc/keyd/be-winaltgr.conf`,
  then run `sudo keyd reload`. Ctrl+Alt then works as plain Ctrl+Alt on that device only.
- **If the keyboard ever stops while the mouse still works** (never seen in testing): a keyd that hangs without
  exiting would keep the keyboard to itself, and nothing restarts it automatically. Restart the computer from the
  system menu with the mouse, or type `sudo systemctl restart keyd` in a terminal with the on-screen keyboard
  (accessibility settings). A keyd that crashes or is killed gives the keyboard back at once, and systemd starts it
  again within seconds (tested).
- **On Zorin OS the Super (Windows) key opens the Activities overview, not the Zorin menu.** Stock Zorin OS 18.1
  does the same: it is Zorin's own default setting, which this project does not touch. To get the Zorin menu: Zorin
  Appearance, Interface, "Left Super Key", or `gsettings set org.gnome.shell.extensions.zorin-menu super-hotkey true`.
- **Typing tools such as ydotool and xdotool can swap or mistype text on a Belgian layout**, with or without this project: they
  assume a US layout or type faster than ibus keeps up with. To put text into an app from a script, paste it instead.
- The Ctrl+Alt rules apply to every keyboard, whatever layout is selected. They are meant for systems that type
  Belgian; on a US layout, Ctrl+Alt+digit would also become AltGr+digit, and AltGr+4 and AltGr+5 would be sent as
  AltGr+9 and as AltGr plus the key to the right of P (the keys that give `{` and `[` on the Belgian layout).
- On Mint installed from the stick (and in the live sessions of both systems), the running desktop lists a second
  layout, US, after Belgian (`setxkbmap -query` shows `be,us`), although the system setting and the desktop setting
  say only Belgian. No key switches to it (no layout-switch option is set), so typing stays Belgian; checked after
  the install, the full update and a suspend. Where the extra `us` comes from was not traced.
- If you write your own keyd configuration with `[ids] *`, it competes with `be-winaltgr.conf`; merge the two.
- The Caps Lock option applies to the first layout only (a second layout keeps the Linux behaviour).
- After a manual `systemctl stop keyd`, keyd stays stopped (Ctrl+Alt is plain Ctrl+Alt again) until
  `systemctl start keyd` or the next boot. If anything else stops it (a crash, `kill`), systemd restarts it within
  about a second.
- The Caps Lock option does not appear in the keyboard settings dialogs (it is not in xkb-data's option list); it is
  switched with `be-azerty-fix`.

## For maintainers

`MAINTAINERS.md` explains how the pieces fit together, how to build every package from source
(`packaging/build-all.sh`), how to test (`tests/run-offline.sh` and the emulator rig in `rig/`), and which piece
belongs upstream where. `NOTES.md` has the technical notes, `evidence/` holds the raw test output.

## Licence

The files of this project are under the MIT licence (`LICENSE`). keyd itself is MIT as well (Raheman Vaiya). Its
Debian packaging, which this project rebuilds with one added patch, is GPL-2+ (Richard Hansen); the added patch is
MIT. The Belgian layout itself is part of xkeyboard-config (MIT/X11).
