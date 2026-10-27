# Technical notes

These notes explain, for maintainers and curious readers, what we found about the Belgian keyboard on Linux Mint 22.3
and Zorin OS 18.1, and why each part of this project works the way it does. They summarise the findings of the
testing done between 23 and 25 October 2026.

- How to install and use the project: `README.md`.
- What was tested where: the README table "What was tested where", and `HOW-WE-TESTED.md` in plain words.
- Which piece belongs in which upstream project: `MAINTAINERS.md`.
- Raw test output (logs, screenshots, key logs): `evidence/`. File names below are relative to that folder.
- Two problems have their own notes: fast typing (`research/FAST-TYPING-SWAPS.md`) and Caps Lock after a GNOME
  password field (`research/CAPS-DIALOG-DESYNC.md`).

Almost everything here was measured in virtual machines (QEMU), in which a script presses the physical keys a
Belgian typist would press and reads back what the system typed. Real hardware is named where it was used.

## 1. Where "Belgian" lives

The kernel's keyboard driver does not know about layouts: it reports key positions. "Belgian" only exists in the XKB
keyboard description (`/usr/share/X11/xkb/symbols/be`), which the console, the login screen and the desktop each
load. The Belgian description itself is correct and has been for a long time. The problems below are all about
which layout each part of the system loads, and when.

## 2. Why the live USB starts in US QWERTY

**The live system.** Mint 22.3 and Zorin 18.1 start their live session with casper (version 1.498, the same file on
both ISOs). Its keyboard script (`scripts/casper-bottom/19keyboard` in the initrd) uses US as the fixed default. Only
these boot parameters change it: `keyboard-configuration/layoutcode=`, `console-setup/layoutcode=` (with
`variantcode=` and `modelcode=`), or `kbd-chooser/method=`. The short forms in casper's manual page (`klayout=`,
`keyb=`, `kvariant=`) are not read anywhere in the initrd, so the manual page is wrong for this version. The language
(`locale=`) is read separately and never changes the keyboard. With a non-US layout, casper adds the AltGr option
`lv3:ralt_switch` by itself.

So the boot line `keyboard-configuration/layoutcode=be locale=fr_BE.UTF-8` (or `nl_BE.UTF-8`) gives a Belgian live
session with no installation at all. Measured on the real Mint 22.3 and Zorin 18.1 ISOs and on Ubuntu Cinnamon 24.04.5
and Ubuntu MATE (`real-mint-01` to `03`, `real-zorin-01`, `10-` to `14-cin-*.png`). With `klayout=be` instead, the
menus turn French but the keys stay US, which looks exactly like a broken keyboard driver (`14-cin-*`).

**Zorin's "Try" page.** Zorin's welcome screen lists languages only, with no Belgian entry. After "Try", the
installer resets the keyboard from the language alone: Français gives French AZERTY (`@` and `\` in the wrong
places for a Belgian), Nederlands gives US QWERTY. The mapping is only right when the language carries the country
(fr_BE, nl_BE give Belgian), which this page never offers (`real-zorin-02`, `03`).

**Zorin's welcome screen also overrides the boot line.** With the Belgian boot line, choosing Français on the welcome
screen writes a desktop layout list with French first (French (alt.), French, Belgian, Canadian), and GNOME uses the
first entry, so the live desktop types French (`real-zorin-07`, `08`). This is why the stick tool removes the welcome
screen (`maybe-ubiquity`) and starts straight on the desktop, where "Install" is still available. A fix for the
installer is drafted in `upstream/ubiquity-indicator-keymaps-honour-layoutcode.patch` (it compiles; not run yet).

**Mint's installer.** Choosing Français pre-selects "French - French (legacy, alt.)" on the keyboard page, not
Belgian. A Belgian user has to find "Belgian" in the list. Once Belgian is chosen, the installer keeps it, the
password page included (`real-mint-05` to `07`).

## 3. The Belgian boot stick

`tools/make_belgian_iso.sh` takes the official ISO you downloaded and writes a new one:

- It adds the Belgian boot parameters to every live boot entry, for UEFI (GRUB) and older BIOS (isolinux) alike. On
  the real ISOs this needed care: Zorin's GRUB lines end in `---` with no space after it, Zorin's BIOS menu is in
  `isolinux/menuentries.cfg` with upper-case `APPEND`, and Mint's isolinux kernel lines must not be edited. All three
  cases are handled, and running the tool on its own output changes nothing.
- With `MENU=b`, the first boot entry becomes a menu: language (Nederlands, Français, Deutsch, English), then Belgian
  with a period or a comma on the numpad (Deutsch and English also offer German QWERTZ). Without a choice it starts
  in Nederlands with a period after the countdown. The other entries of the ISO are left as they are.
- With `PACKAGES=dist`, the packages of this project are added as an extra layer
  (`/casper/zz-belgian-azerty.squashfs`) on top of the untouched system image, and as `.deb` files in `/belgian/` for
  the installer. The live session applies the boot-menu choice; when you install with a Belgian layout, the
  packages and the choice are installed too.
- It updates `md5sum.txt` for every file it changes, so the distribution's own disc check still passes.

How to build a stick and check that it matches ours: `dist/sticks/REBUILD.md`.

## 4. Ctrl+Alt as AltGr

**What Windows does.** In Windows' Belgian layouts, Ctrl+Alt is literally AltGr: Ctrl+Alt+2 is `@`, Ctrl+Alt+E is
`€`, Ctrl+Alt+9 is `{`, and so on for 15 keys (`keytables/ctrlalt-windows-vs-mint-vs-fix.md`). Linux's Belgian AltGr
table is the same, except that AltGr+4 and AltGr+5 give `¼` `½` instead of `{` `[`.

**What stock Linux does.** On stock Mint, Ctrl+Alt+2 types nothing in GTK apps such as the text editor, and the
plain character (é) in the terminal (`real-mint-08`, `13`, `raw-logs/xev-off.txt`).

**Why the layout alone cannot fix it.** GTK, the toolkit of most Mint and Zorin apps, refuses any key with Ctrl or
Alt held as text input (`gtk/gtkimcontextsimple.c`, GTK 3 and 4). The code that lets Ctrl+Alt count as AltGr exists,
but only on Windows (`#ifdef G_OS_WIN32`, with the comment "On Win32, even Ctrl + Alt could be text input because
AltGr = Ctrl + Alt"). An XKB option that maps Ctrl+Alt to AltGr loads correctly, but GTK apps still type nothing
(`real-mint-08b`). So the change has to happen before GTK sees the key.

**The fix: keyd.** keyd is a small service that remaps keys at the kernel input level, below the console, the
display server and every app. This project's rules for it (`keyd/be-winaltgr.conf`, in the package
`keyd-belgian-windows`) turn Ctrl+Alt plus one of the 15 symbol keys into AltGr plus that key, and make AltGr+4 and
AltGr+5 give `{` and `[` as on Windows. Every other Ctrl+Alt combination passes through unchanged, so shortcuts such
as Ctrl+Alt+T, Ctrl+Alt+arrows and Ctrl+Alt+F3 keep working. keyd's output log shows the exchange: for Ctrl+Alt+2 it
releases Ctrl and Alt, presses AltGr, sends 2, then restores Ctrl and Alt; for Ctrl+Alt+T it passes the keys through
untouched (`raw-logs/keyd-monitor-output.txt`). From 0.9.4 a small keyd patch keeps AltGr held while Ctrl+Alt stays
down; see `research/FAST-TYPING-SWAPS.md` and the section "The keyd patch" in HOW-WE-TESTED.md.

Because keyd works below the display server, the same rules work on X11 (Mint), on Wayland (Zorin) and on the text
console (`real-mint-11`, `14`, `real-zorin-06`, `09`, `raw-logs/xev-on.txt`), and so also on the login screen. The one
place keyd does not reach is the disk-encryption prompt at boot, which runs before keyd starts; that prompt uses the
console layout, which `be-azerty-fix system` sets to Belgian.

**Shortcut check.** 176 key combinations were sent with keyd stopped and with keyd running, and keyd's log of what
the desktop would receive was compared: the 15 Ctrl+Alt symbol keys (also with right Ctrl, and with Shift) must
become AltGr, everything else must arrive unchanged (Ctrl+Alt with every other letter, arrows, Tab, Backspace;
Ctrl, Alt and Super shortcuts; Ctrl+Alt+F1 to F7). Result: 176 of 176 correct on live Zorin, live Mint and
installed Zorin (`raw-logs/zorin/sweep-live-*`, `raw-logs/mint/sweep-live-*`, `raw-logs/zorin/installed/`).
Ctrl+Alt+Delete was left out because it restarts the machine; keyd does not touch the Delete key.

**Packaging.** Mint 22 and Zorin 18 (Ubuntu 24.04 base) have no keyd package. The `keyd` package of this project is
Debian's keyd 2.5.0-5, rebuilt for Ubuntu 24.04 with one labelled patch since 0.9.4. Its version sorts below any keyd
a distribution ships, so a distribution's own keyd replaces it automatically.

## 5. Where the layout is stored, and why it "switches back to US"

On an installed Mint or Zorin, the keyboard layout is stored in several places. Measured on fresh installs
(`raw-logs/installed-mint-stores-fresh-install.txt`, `raw-logs/zorin/installed/`):

- `/etc/default/keyboard`: used by the text console, the disk-encryption prompt (through the initramfs), the X
  server's default and the login screens (LightDM on Mint, GDM on Zorin).
- The answers stored for the `keyboard-configuration` package (debconf). On every reinstall or upgrade of that
  package, `/etc/default/keyboard` is rewritten from these answers, so a stale "us" answer brings US back.
- The desktop's own per-user layout list: `org.cinnamon.desktop.input-sources` and `org.gnome.libgnomekbd.keyboard`
  on Mint, `org.gnome.desktop.input-sources` on Zorin. When not empty, the session applies it on top of the system
  file. The Zorin login screen user (gdm) can have its own list too.
- AccountsService's record of each user.

The classic "it switched back to US by itself" needs one of these places to still say US: a debconf answer, a
per-user list, the login screen's own list, or the live-session default. `be-azerty-fix system` sets all of them to
Belgian in one go, also as the default for new users on Mint (a settings override file, since Cinnamon would
otherwise start new users from its own default). `be-azerty-fix check` prints every place and what it says
(`tools/kbstate.sh` is the test version of that list).

On Ubuntu 24.04, and so on Mint 22 and Zorin 18, `localectl set-x11-keymap` and `localectl set-keymap` refuse to run
(a Debian change to systemd since version 253): the layout service only reads `/etc/default/keyboard`. So
`localectl` cannot be used to set the layout there; this project does not rely on it.

**Measured in the virtual machines** (some checks on installed systems, some in live sessions; the README table
"What was tested where" says which): the Belgian layout and Ctrl+Alt stayed in place after a reboot, logging out and
in, reinstalling `keyboard-configuration` and `console-setup`, a full system update, suspend and resume, a new user,
and wiped desktop settings. On Zorin, adding US in the settings and moving it to
the top made the desktop type US, as expected; running `be-azerty-fix system` again put everything back to Belgian
and removed the US entry (`raw-logs/zorin/installed/zi-zdur.txt`).

## 6. Caps Lock as on Windows

**What Windows does** (from Windows' own Belgian layout data, `keytables/caps-lock-windows-vs-linux.md`): with Caps
Lock on, every printable key of the main block gives its Shift character, except `²` and `<`. So Caps Lock gives
`1 2 3 … 0 ° _` on the top row and `% £ ? . / +` on the right. Caps Lock with Shift gives the plain character. AltGr
and the numpad are not affected. Linux's Caps Lock only changes the letters (and é è ç à to É È Ç À).

**How this project does it: an XKB option, `caps:be_windows`.** The package `belgian-azerty-windows` adds a small
symbols file (`xkb/symbols/be_capslock`) and the rule for the option. `tools/captest.py` compares the result with the
Windows table, key by key, using the same library the desktop uses: 0 differences for Caps Lock and Caps Lock with
Shift, AltGr unchanged. The standard Linux options come closest but still differ on 19 to 22 keys
(`raw-logs/caps/captest-options-vs-windows.txt`).

Why an XKB option and not a keyd rule: the option uses the normal Caps Lock key, so the Caps Lock light and
shortcuts such as Ctrl+1 behave as before. A keyd rule would need extra layers for every
modifier combination and could not drive the light cleanly. The option is also the form that can go upstream: it
works like the existing `caps:digits_row` option of xkeyboard-config 2.42 and later (Ubuntu 24.04 has 2.41), extended
to the Belgian punctuation keys.

Details that matter:
- The rules file belongs to the `xkb-data` package, whose updates rewrite it. The package diverts that file and
  rebuilds it with a dpkg trigger, so the option survives `xkb-data` updates, with apt and with plain `dpkg -i`.
- An option the rules do not know is ignored, so the worst case is the Linux Caps Lock, never a broken keyboard.
- The text console and the disk-encryption prompt keep the Linux Caps Lock (the console keymap is identical with
  and without the option, checked).
- **On Zorin, the Windows Caps Lock is off by default** (from 0.9.6), because of a GNOME problem on Wayland that can
  make `2 6 7 9 0 %` untypeable until the next login. See `research/CAPS-DIALOG-DESYNC.md`.

## 7. Belgian (Period) and Belgian (Comma)

Windows has two Belgian layouts. "Belgian (Period)" is Linux's `be`. "Belgian (Comma)" is `be` plus the standard XKB
option `kpdl:comma`. The only difference is the numpad decimal key; the main block and the AltGr table are the same,
so keyd needs no second set of rules. (`be(iso-alternate)` is not the Comma layout.) `be-azerty-fix` takes
`DECIMAL=period` or `DECIMAL=comma` and writes it everywhere the layout is stored. Full table:
`keytables/belgian-period-vs-comma.md`.

## 8. Safety: the keyboard must keep working

- **keyd stopped, killed, or given a broken configuration.** When keyd stops, the keyboard keeps working with the
  plain Belgian layout (only Ctrl+Alt stops giving symbols). When keyd is killed, systemd restarts it within seconds.
  A broken extra configuration file is ignored and the working rules stay. Measured on installed Mint and Zorin
  (`raw-logs/installed-mint-durability.txt`, `raw-logs/zorin/installed/zi-zdur.txt`).
- **Why a stopped keyd cannot leave the keyboard dead:** keyd takes the keyboard exclusively while it runs; when the
  process ends, for any reason, the kernel gives the keyboard back to the system. The one case this does not cover
  is a keyd that hangs while still running. That was never seen; the README's "Known issues" gives the recovery
  steps.
- **The mouse and touchpad.** Normal laptop touchpads and TrackPoints are separate devices, and keyd leaves them
  alone (checked on the laptop and in the virtual machines). Devices that combine a keyboard and a pointer in one
  (some keyboard-and-touchpad combinations, some wireless receivers) are an exception; see the README's "Known
  issues".
- **Uninstall** (`sudo be-azerty-fix uninstall`) removes the packages, the Caps Lock option from every place it was
  written, and the Mint settings override; the rules file is back to the `xkb-data` original. The Belgian layout
  itself stays, because it is a standard setting (`raw-logs/fix-round/mint/un-mint.txt`, `zorin/un-zorin.txt`).
- **A bug found and fixed during testing:** the step that clears the Zorin login screen's own layout list could hang
  forever when the output of `be-azerty-fix` was piped (a helper process started by GNOME's settings library kept the
  pipe open). The script now runs that step with a time limit and with no shared output.

## 9. VirtualBox on Windows

Tested on one laptop with Windows 11 and VirtualBox 7.2.10 (`vbox-*.png`,
`raw-logs/vbox-kali-keyd-output-younes-physical.txt`):

- AltGr typed on the physical keyboard arrives in the virtual machine as AltGr, with no extra Ctrl. The old
  "AltGr arrives as Ctrl+Alt" problem of VirtualBox is not present in 7.2.10; older versions were not checked.
- Ctrl+Alt arrives as Ctrl+Alt, and keyd turns it into AltGr exactly as on a real machine. Both the Belgian boot line
  and the Ctrl+Alt rules work inside VirtualBox.
- Two things that feel like "the keyboard is stuck" but are not keyboard problems: while the virtual machine window
  has the keyboard, Alt+Tab goes to the virtual machine (press the host key, right Ctrl by default, to give the
  keyboard back to Windows); and with Windows' Hyper-V active, restoring a saved virtual machine froze it once, while
  a normal start was fine.

## 10. Other findings

- **Ctrl+Alt+Backspace.** Mint's installer switches on the option `terminate:ctrl_alt_bksp`: Ctrl+Alt+Backspace
  ends the session at once, which looks like a sudden return to the login screen. Zorin's installer does not. This
  project keeps the option as Mint set it (README, "Known issues").
- **Mint's layout indicator** shows "DE" for the Belgian layout in the live session. It is only a label.
- **Under Wayland, `setxkbmap -query` says "us".** That is the X compatibility layer's view, not the real layout;
  `be-azerty-fix check` reads the right places.
- **Mint's live X session has a second `us` layout** (`be,us`) from the stock live system. No switch key is set, so it
  has no effect.

## 11. How to rerun these tests

The scripts are in `rig/` and run from a folder that holds `rig/` and the ISOs. Host side, once per session: run
`python3 -m http.server 8000 --bind 127.0.0.1` in a folder with the files the virtual machine needs (the packages,
`rig/kbstate.sh`, `rig/sweep-guest.sh`), and `python3 rig/upload_server.py` (port 8001, writes what the virtual
machine sends into `up/`). Inside the virtual machine: `wget http://10.0.2.2:8000/<file>`.

- **Build a Belgian ISO:** `sudo MENU=b PACKAGES=dist tools/make_belgian_iso.sh IN.iso OUT.iso` (see
  `dist/sticks/REBUILD.md`). Without `MENU=b`, a third argument sets the boot parameters, for example
  `"keyboard-configuration/layoutcode=be locale=nl_BE.UTF-8"` for Dutch; `KEEP_WELCOME=1` keeps Zorin's welcome
  screen.
- **Start it:** `python3 rig/qemu_rig.py start NAME --iso OUT.iso [--disk d.qcow2] --mem 6144 --vga virtio --cpu Nehalem`.
  Then `shot NAME f.png` (screenshot), `type NAME --as be "text"` (press the keys a Belgian typist would press),
  `keys NAME "ctrl-alt-2 alt_r-e"`, `click NAME X Y`, `stop NAME`. To wait for the screen: `rig/settle.py NAME out.png
  [max_s]` or `rig/waitchange.py NAME ref.png out.png [max_s] [threshold]`. The scripts use KVM when the host has it.
- **List every place the layout is stored** (inside the virtual machine): `bash kbstate.sh LABEL`.
- **Shortcut check:** on a text console in the virtual machine (Ctrl+Alt+F3, logged in), run `sudo systemctl stop
  keyd; bash sweep-guest.sh LABEL-off`; on the host `python3 rig/sweep.py send NAME`, then type `stopstop`; repeat with
  `sudo systemctl start keyd; bash sweep-guest.sh LABEL-on`; compare with `python3 rig/sweep.py compare
  up/mon-LABEL-off.txt up/mon-LABEL-on.txt [--md]`. Pass: `PASS 176 FAIL 0`.
- **Typing probe** (plain keys, Ctrl+Alt, AltGr, Caps Lock rows) into a focused GNOME Terminal: `bash
  rig/typed-probe.sh VM LABEL`, result in `up/typed-LABEL.txt`.
- **Installed-system durability:** put `rig/durability-guest.sh` and `rig/kbstate.sh` in the served folder, focus a
  GNOME Terminal in the virtual machine, then run `python3 rig/durability-host.py VM [password]` on the host.
- **Fast-typing measurements:** `rig/swaptest.py`, `rig/swap-run.sh` and `rig/swapscore.py`
  (`research/FAST-TYPING-SWAPS.md`).
- **Caps Lock option against the Windows table, no virtual machine:** `python3 tools/captest.py [--include DIR]
  caps:be_windows` (needs the Python xkbcommon module). Pass: `mismatches=0`.
- **Package tests, no virtual machine:** `tests/run-offline.sh` (shell check, build and lintian, Caps Lock table,
  ISO checksum check) and `tests/pkg-cycle.sh` (install, upgrade, trigger, remove).

Each virtual-machine step needs the machine at a known screen, so there is no single command that runs everything;
this list is the procedure.
