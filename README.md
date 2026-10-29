# Belgian AZERTY that works as it does on Windows, for Linux Mint and Zorin OS

The Belgian keyboard layout itself has been correct on Linux for a long time. What is missing is the Windows
behaviour that Belgians are used to, and a live USB that starts with the Belgian keyboard already set. This project adds:

| Habit from Windows | What it does here | Part of the project |
|---|---|---|
| Ctrl+Alt works as AltGr | Ctrl+Alt+2 = @, Ctrl+Alt+E = €, Ctrl+Alt+9 = {, ... on the 15 AltGr keys; other Ctrl+Alt shortcuts unchanged. AltGr+4 and AltGr+5 also give `{` and `[` as on Windows (Linux gives `¼` `½`) | package `keyd-belgian-windows` (rules for the keyd program) |
| Caps Lock as on Windows | Caps Lock gives the Shift character on the whole main block (1 2 3 ... ° _ % £ ? . / +); the ² and < keys, AltGr and the numpad are unchanged. On by default on Mint; on Zorin you switch it on yourself (see "Caps Lock on Zorin") | package `belgian-azerty-windows` (XKB option `caps:be_windows`) |
| "Belgian (Period)" or "Belgian (Comma)" | Numpad decimal key types `.` or `,` | `be-azerty-fix` (`DECIMAL=comma`, standard option `kpdl:comma`) |
| The layout never switches by itself | Every place where the system stores the layout has Belgian first, also for new users and after a settings reset. Your other layouts and input methods stay | `be-azerty-fix system` |
| Live USB and installer start with the Belgian keyboard | Repacked ISO whose boot menu asks for the language, then the Belgian keyboard (period or comma) | `tools/make_belgian_iso.sh` |

**Status.** Version 0.9.8. This is a long-standing problem that no project owns. The fix was tested in emulators and
on one laptop, for Linux Mint 22.3 and Zorin OS 18.1 only (the changes of 0.9.8 so far in test containers, see
`HOW-WE-TESTED.md`), and nothing has been accepted upstream yet. The goal is
for Linux Mint, Zorin OS and the projects they build on to adopt these fixes themselves (`MAINTAINERS.md` says which
piece belongs where); until then this is an unofficial community project. What was tested, where and with which
version: `HOW-WE-TESTED.md`. Built with AI help (Claude).

**New in 0.9.8** (`CHANGELOG.md` has the details):
- Your other keyboard layouts and input methods are kept. Version 0.9.7 replaced them with Belgian only when you
  ran `sudo be-azerty-fix system` or changed Period/Comma in the "Belgian keyboard" window. Now Belgian is put first
  and nothing else is removed.
- keyd now comes from the keyd-team PPA, so it gets updates; this project no longer ships its own keyd build.
- The fast-typing workaround for the Terminal, the text editor and VS Code is off unless you switch it on.

## Install on an installed system

1. Add keyd, the program behind Ctrl+Alt as AltGr. Ubuntu 24.04, on which Mint 22 and Zorin 18 are based, does not
   have it; the keyd-team PPA does (run by the maintainer of Debian's keyd package; not part of the keyd project
   itself):

   ```
   sudo add-apt-repository ppa:keyd-team/ppa
   sudo apt update
   sudo apt install keyd
   ```

   (`apt update` is needed on Mint, whose `add-apt-repository` does not refresh the package list by itself.)

2. Download the two packages from the release page into one folder, open a terminal there, then:

   ```
   sudo apt install ./keyd-belgian-windows_*.deb ./belgian-azerty-windows_*.deb
   sudo be-azerty-fix system                    # Belgian (Period); Windows Caps Lock on Mint (on Zorin see below)
   ```

   Other choices: `sudo DECIMAL=comma be-azerty-fix system` for Belgian (Comma), `CAPS=linux` to keep the Linux Caps
   Lock, `PROFILE=linux` for the Linux-standard profile (below).

3. Log out and back in. `be-azerty-fix check` shows what every setting says.

**The Ctrl+Alt rules apply to every keyboard you connect, whatever layout it has**, because keyd cannot see which
layout the desktop uses. They are meant for computers that type Belgian. On a US layout, Ctrl+Alt+digit would also
become AltGr+digit, and AltGr+4 and AltGr+5 would send the keys that give `{` and `[` on a Belgian keyboard.

Running `sudo be-azerty-fix system` again later (for example to repair settings) keeps your earlier Period/Comma and
Caps Lock choices; give `DECIMAL=` or `CAPS=` only to change them. If nothing needs changing, no setting changes and
the boot image is not rebuilt.

## Only the parts you need

You do not have to install everything:

- **Only Ctrl+Alt as AltGr:** step 1 above, then `sudo apt install ./keyd-belgian-windows_*.deb`. No keyboard
  setting changes. (Or copy `keyd/be-winaltgr.conf` to `/etc/keyd/` yourself and run `sudo keyd reload`.)
- **Only Caps Lock as on Windows, and Period/Comma:** install only `belgian-azerty-windows` with
  `sudo apt install --no-install-recommends ./belgian-azerty-windows_*.deb`, then `sudo be-azerty-fix system`. Without
  keyd, Ctrl+Alt stays Ctrl+Alt (AltGr types `@` and `€`).
- **Only a live USB that boots Belgian:** no package needed. At the boot menu, press `e` and add
  `keyboard-configuration/layoutcode=be` to the line that starts with `linux`. The repacked stick (see "Live USB")
  does this for you.

## What `be-azerty-fix system` changes

- `/etc/default/keyboard` (console, disk-unlock prompt, login screen, new users): Belgian first, other layouts kept,
  your numpad and Caps Lock choice added to the options, other options kept. These places use at most four layouts:
  if you already had four, the last one is left out there (the command names it; your own desktop list keeps it).
  The boot image is rebuilt only when this file changed.
- Your own desktop settings (GNOME on Zorin, Cinnamon on Mint, MATE): Belgian first in your list of layouts; a second
  layout or a Chinese, Japanese or Korean input method stays, in its order. If you already use a Belgian variant
  (for example Belgian (alt.)), that one is moved first. An empty list, which means "use the system default" (Mint
  users who never changed their layouts), is filled with the system default's layouts, Belgian first. When you run
  the command over ssh or from a console while not logged in, your stored settings are changed the same way. The
  command says what it kept.
- On Mint: the default options for new users and reset settings (one small file, removed again by uninstall).
- The login screen on Zorin: a layout stored only for the login screen is cleared, so it follows the system default.
- keyd: switched on with the Windows profile, off with the Linux-standard profile.

It does not touch other users' own desktop settings, your other keyboard options, or your input method setup.

## Two profiles: Windows (default) and Linux-standard

| | Windows profile (default) | Linux-standard profile |
|---|---|---|
| Layout | Belgian first, everywhere | same |
| Period / Comma on the numpad | your choice (`DECIMAL=`) | same |
| Caps Lock | as on Windows on Mint; on Zorin Linux unless you add `CAPS=windows` | Linux: letters only |
| Ctrl+Alt+2, Ctrl+Alt+E ... | `@`, `€` ... as on Windows (keyd) | plain Ctrl+Alt; use AltGr for `@` and `€` |
| Switch | `sudo PROFILE=windows be-azerty-fix system` | `sudo PROFILE=linux be-azerty-fix system` |

The easiest way to switch is the **Belgian keyboard** entry in the app menu (Belgisch toetsenbord, Clavier belge,
Belgische Tastatur): one window with the four combinations of profile and numpad decimal key. It asks for your
password and runs the same `be-azerty-fix system`. The Linux-standard profile switches the keyd service off and keeps
the packages, so switching back is one command. If you have your own keyd configuration besides ours, keyd keeps
running and the command says so.

### Caps Lock on Zorin

On Zorin (GNOME) the Windows profile keeps the Linux Caps Lock, because of a GNOME problem: in Zorin's normal session
(Wayland), a short Caps Lock tap in a GNOME password field (the lock screen, the password window before updates)
puts Caps Lock out of step until you log out. On stock Zorin that only swaps upper and lower case; with the Windows
Caps Lock it also stops `2 6 7 9 0` and `%` from typing on the main block. If you want the Windows Caps Lock anyway:
`sudo CAPS=windows be-azerty-fix system`, and log out and back in if those keys stop working. Choosing "Windows" in
the "Belgian keyboard" window sets Caps Lock back to Linux on Zorin (the window says so). Tested in emulators only;
a report for GNOME is drafted, not yet sent.

## Fast typing: optional ibus skip for the Terminal, the text editor and VS Code

In emulator tests, keys sent much faster than people type could arrive swapped (`@€` as `€@`) while the ibus input
method sits between the keyboard and the app. This also happens without this project, and at normal typing speed no
swaps were measured. **If you do see swapped characters**, you can let the Terminal, the text editor and VS Code take
the keys without ibus: open "Belgian keyboard" from the app menu, click "Fast typing…" and tick the box, or run
`be-azerty-fix ibus-skip auto on`. It is per user and off unless you switch it on.

When it is on, it steps aside by itself while you have an input method that needs ibus (Chinese, Japanese, Korean
and similar, or another input system such as fcitx). In those three apps you keep the layout, AltGr, Ctrl+Alt, Caps
Lock and dead keys; you lose the ibus emoji picker. It only works for GTK apps and VS Code. Commands:

```
be-azerty-fix ibus-skip                    # what skips ibus now, and why
be-azerty-fix ibus-skip auto on | off      # switch it on or off for your user
be-azerty-fix ibus-skip off --all          # nothing skips ibus any more
```

How it works, the measurements and its limits: `HOW-WE-TESTED.md`, section "Fast typing".

## Coming from 0.9.7

1. Install the two new packages as in step 2 above. If you had the ibus skip on without choosing it (the 0.9.7
   default), it switches off at your next login; tick it again if you want it.
2. keyd: 0.9.7 installed this project's own keyd build (`2.5.0-5~ubuntu24.04.3`, with an extra patch). It keeps
   working, but gets no updates. To switch to the keyd-team PPA's keyd:

   ```
   sudo add-apt-repository ppa:keyd-team/ppa
   sudo be-azerty-fix switch-keyd
   ```

   (apt does not do this by itself, because the old build has a higher version number.)
3. If 0.9.7 removed a layout or input method of yours, add it again in your keyboard settings (Zorin: Settings >
   Keyboard; Mint: Keyboard > Layouts). 0.9.8 keeps it from now on.

## Uninstall

```
sudo be-azerty-fix uninstall
```

This takes the Caps Lock option out of the system default and out of every user's own desktop settings, removes the
defaults for new users and the ibus skip files of every user, purges both packages, and removes files left by older
versions. keyd stays when you installed it yourself (from the PPA); this project's old keyd build (0.9.7 and earlier) is
removed, unless you have your own keyd configuration or another package that needs keyd (`KEEP_KEYD=1` keeps it too). The keyboard stays Belgian, with your other layouts, because the Belgian layout and
the Period/Comma choice are standard Linux settings. Log out and back in afterwards.

Removing the packages with `sudo apt purge belgian-azerty-windows keyd-belgian-windows` also works. Use `purge`, not
`remove`: after a plain `remove`, dpkg keeps `/etc/keyd/be-winaltgr.conf` and keyd keeps using it.

## Live USB

**The all-in-one stick** (Linux Mint 22.3 or Zorin OS 18.1, built from the official ISO you downloaded yourself; the
stick is a stopgap until the distributions offer a Belgian boot entry themselves):

```
sudo MENU=b PACKAGES=dist tools/make_belgian_iso.sh linuxmint-22.3-cinnamon-64bit.iso mint-belgian-stick.iso
```

`PACKAGES` is a folder with the two packages and a keyd `.deb` (for example from the keyd-team PPA). The boot menu
first asks for the language (Nederlands, Français, Deutsch, English), then for the keyboard: Belgian AZERTY with a
period or a comma on the numpad, and for Deutsch and English also German QWERTZ. Without a key press it starts
Nederlands with the period, except on Mint in UEFI mode, which waits (stock Mint does the same). What the tool
changes, and nothing else: the boot menu entries, the checksum list for the disc check, one extra file
`/casper/zz-belgian-azerty.squashfs` (the packages, stacked on top of the distribution's untouched system image) and
the packages in `/belgian/` for the installer. This is an unofficial, community-made stick, not made by or affiliated
with Linux Mint or Zorin OS.

**Boot menu only** (no packages, no root needed): `MENU=b tools/make_belgian_iso.sh IN.iso OUT.iso`.

## Known issues

- **Very fast typing can swap two characters** while the ibus input method runs (stock Mint and Zorin too): see
  "Fast typing" above. Measured in emulators only, at speeds faster than people type.
- **On Zorin with Wayland, six keys can stop working after Caps Lock in a password field**, only with the Windows Caps
  Lock switched on by hand: see "Caps Lock on Zorin". Not caused by keyd. Details: `research/CAPS-DIALOG-DESYNC.md`.
- **The Ctrl+Alt rules apply to every keyboard**, also an external US keyboard: see the note under "Install".
- **If you already use keyd with your own configuration**, keyd applies only one configuration file per keyboard, so
  either your rules or the Belgian Ctrl+Alt rules work on a keyboard, not both. `be-azerty-fix check` and the package
  installation warn about it. Copy the lines of `/etc/keyd/be-winaltgr.conf` into your own file and remove ours, or
  limit one of the files to some keyboards under `[ids]`.
- **Keyboards with a touchpad or mouse built into the same device**: keyd takes over every device with a full set of
  keyboard keys and passes its pointer on without high-resolution scrolling or multi-finger gestures. Not tested with
  such a device. Normal laptop touchpads are separate devices and keyd leaves them alone (checked). Fix for one
  device: `sudo journalctl -b -u keyd | grep match` shows its id; add `-ID` under `*` in `/etc/keyd/be-winaltgr.conf`,
  then `sudo keyd reload`.
- **Zorin's login screen can ignore the keyboard on the first boot after installing** (seen once, on stock Zorin OS
  18.1 before this project was installed): a restart fixes it. Not caused by this project.
- **VS Code (and possibly other Electron apps) sometimes drops the € of Ctrl+Alt+E** in the emulator; the ibus skip
  above stopped it there.
- **The running desktop can list an extra US layout** after Belgian (`setxkbmap -query` shows `be,us`) in Dutch and
  German sessions (French sessions show `be,be`). No key switches to it, so typing stays Belgian. It comes from the
  desktop itself, not from this project: GNOME Shell (and Cinnamon, which started as a fork of it) adds the layout of your
  display language to the running session so that menu shortcuts keep working, and uses US when it knows no layout
  for that language, as for Dutch and German in Belgium (see `HOW-WE-TESTED.md`).
- **The Caps Lock option applies to the first layout only**; a second layout keeps the Linux behaviour. It does not
  appear in the keyboard settings dialogs; it is switched with `be-azerty-fix`.
- **On Linux Mint, Ctrl+Alt+Backspace ends the whole session at once** (Mint's own setting, kept as Mint set it).
- If the keyboard ever stops while the mouse still works (never seen in testing): restart from the system menu with
  the mouse, or run `sudo systemctl restart keyd` with the on-screen keyboard.
- Not tested: real hardware with 0.9.8, Ubuntu itself, other distributions, a second USB keyboard, Wine, remote
  desktop. Full list: `HOW-WE-TESTED.md`.

## Help test, or answer the survey

- **Test it** on your own computer: the steps are in [TESTING.md](TESTING.md) (Nederlands: [TESTING.nl.md](TESTING.nl.md),
  Français : [TESTING.fr.md](TESTING.fr.md)). You can report with or without a GitHub account.
- **2-minute survey**, anonymous, open until 30 November 2026: [English](https://cryptpad.fr/form/#/2/form/view/A9o2MXPQHcgJr0e6Y0eG3Qy0fjz13WeJ1IHy-JGxTy0/) · [Nederlands](https://cryptpad.fr/form/#/2/form/view/mLakgWAFAMsQhn1VkX+rnDxlHPSzbZiloRZxeS6IYlQ/) · [Français](https://cryptpad.fr/form/#/2/form/view/Vs07SGZoahOJOklE8G6wDZaC4Kjdl9mKyBwYAshSCQA/).

## For maintainers

`MAINTAINERS.md` explains how the pieces fit together, how to build the packages from source
(`packaging/build-all.sh`), how to test (`tests/run-offline.sh`, `tests/lived-in.sh`, `tests/keyd-rules.sh` and the
emulator rig in `rig/`), and which piece belongs upstream where. `NOTES.md` has the technical notes, `evidence/`
holds the raw test output.

## Licence

The files of this project are under the MIT licence (`LICENSE`). keyd itself is MIT as well (Raheman Vaiya). The
Belgian layout itself is part of xkeyboard-config (MIT/X11).
