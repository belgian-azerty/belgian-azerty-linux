# World prototype: keyboard layouts that type like Windows

**Prototype, not released.** Built with AI help (Claude).

This folder holds a prototype for other countries, next to the Belgian package. For each Windows keyboard layout it
adds a new Linux layout that types, key for key, what Windows types: for example "German (as on Windows)" next to Linux's
own "German". The Linux layouts stay as they are, and nothing of the Belgian package (`belgian-azerty-windows`,
`keyd-belgian-windows`) is changed or replaced.

22 layouts so far: the pilot (German, Swiss German, Swiss French, Polish Programmers) and 18 more that needed only a
few keys (French, English UK, Spanish, Portuguese, Portuguese Brazil, Italian, Hungarian, Estonian, Lithuanian,
Icelandic, Faroese, Albanian, Ukrainian, French Canada legacy, Norwegian, Danish, Finnish, Dutch).

## What is in it

| Part | What it does |
|---|---|
| `layouts.tsv` | The layouts of this prototype: which Windows layout (CLDR file), on which Linux layout, new name and description |
| `cldr-43/` | The 22 Windows layout files from Unicode CLDR release 43 (open data, Unicode License, `LICENSE.txt`) |
| `tools/gen_windows_symbols.py` | Writes each new layout: it includes the Linux layout unchanged, then redefines only the keys where Windows differs. Also writes the layout list `xkb/rules/evdev.xml` |
| `tools/check_windows_symbols.py` | Machine check: types every key in 6 states (plain, Shift, Caps Lock, Caps Lock+Shift, AltGr, Shift+AltGr) and every accent sequence, as libxkbcommon (Wayland) and as xkbcomp (X11) build the layout, and compares with Windows |
| `xkb/` | The generated files (`symbols/<name>_windows`, one per country, and `rules/evdev.xml`) |
| `packaging/`, `build-deb.sh` | The Debian/Ubuntu package `world-keyboard-windows` (0.0.1~proto2) |
| `tests/` | Package test next to the Belgian package, system upgrade test to Ubuntu 26.04, typing test in a headless GNOME desktop, Cinnamon layout lookup |

New layout names: the Linux name plus `_windows` (`de_windows`, `fr_windows`, `gb_windows`, ...; Swiss French is
`ch_windows` variant `fr`). In the layout list they appear as "German (as on Windows)", "French (as on Windows)" and
so on. Not "(Windows)": xkb-data already has layouts with that name (for example "Italian (Windows)", `it(winkeys)`),
which are something else.

## How the package stays out of the way

- It owns no file in the system keyboard folder. It keeps its files in `/usr/lib/world-keyboard-windows/` and
  copies them to the keyboard folder, each copy with a marker line, so only its own files are ever replaced or removed.
  Reason: xkb-data 2.46 (Ubuntu 26.04, Linux Mint 23, Debian 14) turns the folder into a link and refuses while
  another package owns files there (the problem belgian-azerty-windows 0.9.11/0.9.12 had to fix). An apt hook takes
  the copies out before that switch and puts them back after, the same way the Belgian package does for its own files.
- No change to the rules file. Desktops only offer, and only accept, layouts that are in a layout list
  (`rules/evdev.xml`): GNOME 46 silently fell back to US for a layout that was not listed. GNOME and KDE
  (libxkbregistry) also read a list in `/etc/xkb/rules/evdev.xml`, but Linux Mint's Cinnamon reads only xkb-data's own
  list. So the package diverts xkb-data's list to `evdev.xml.distrib` (xkb-data updates land there, `dpkg -V xkb-data`
  stays clean) and rebuilds `evdev.xml` as that file plus its own entries after every xkb-data change. Removal puts
  xkb-data's file back in one rename. The `/etc/xkb` list is only written when the system list cannot hold the
  entries, so no layout is listed twice. This is the same method the Belgian package uses for `rules/evdev`; the two
  packages divert different files.
- It sets nothing. On removal, a system default (`/etc/default/keyboard`) that names one of its layouts gets the
  Linux layout back (`ch_windows` -> `ch`), so the keyboard never falls back to US.

## Results (4 Nov 2026, cloud containers only, version 0.0.1~proto2 with 22 layouts)

| Check | Result |
|---|---|
| Machine check, Windows cells and accent sequences, all 22 layouts | 5,583 of 5,636 like Windows (stock Linux: 5,327); per layout below |
| Keys that type something else than Windows | 0 on every layout |
| Same on X11 (xkbcomp) as on Wayland (libxkbcommon) | yes, all 22 |
| Linux characters lost (where Windows has none, and anything on level 5 and up) | 0 |
| Headless GNOME Shell 46 (Ubuntu 24.04), typed through Mutter | @TYPING@ |
| Package next to belgian-azerty-windows 0.9.12 (`tests/coexist.sh`) | 95/95 PASS: every Belgian file, the rules file, its diversion and xkb-data's other files byte-identical after install, removal and purge; xkb-data's list kept as `evdev.xml.distrib` and given back on removal; rebuilt after an xkb-data reinstall; a system default naming our layouts gets the Linux layouts back on removal |
| Cinnamon's layout lookup (CinnamonDesktop.XkbInfo, Ubuntu 24.04 build 6.0, `tests/cinnamon-lookup.sh`) | finds all 22 after install, none before and after removal |
| System upgrade Ubuntu 24.04 -> 26.04 (xkb-data 2.46, `tests/upgrade-2604.sh`) | ALL PASS, with (38 checks) and without (34) the Belgian package |

Per layout (machine check, cells like Windows: stock Linux -> new layout, of all cells):

| Layout | Stock Linux | New | Cells | Left (accent + Space, unless noted) |
|---|---|---|---|---|
| German (`de_windows(basic)`) | 208 | 239 | 240 | 1 |
| Swiss German (`ch_windows(basic)`) | 256 | 260 | 262 | 2 |
| Swiss French (`ch_windows(fr)`) | 251 | 261 | 262 | 1 |
| Polish (Programmers) (`pl_windows(basic)`) | 204 | 209 | 230 | 21 (Polish ~ key, see below) |
| French (`fr_windows(basic)`) | 183 | 265 | 267 | 2 |
| United Kingdom (`gb_windows(basic)`) | 193 | 206 | 206 | 0 |
| Spanish (`es_windows(basic)`) | 247 | 256 | 258 | 2 |
| Portuguese (`pt_windows(basic)`) | 253 | 255 | 257 | 2 |
| Portuguese (Brazil ABNT2) (`br_windows(basic)`) | 256 | 257 | 259 | 2 |
| Italian (`it_windows(basic)`) | 192 | 200 | 200 | 0 |
| Hungarian (`hu_windows(basic)`) | 307 | 315 | 317 | 2 |
| Estonian (`ee_windows(basic)`) | 242 | 264 | 265 | 1 |
| Lithuanian (`lt_windows(basic)`) | 205 | 213 | 213 | 0 |
| Icelandic (`is_windows(basic)`) | 238 | 254 | 256 | 2 |
| Faeroese (`fo_windows(basic)`) | 258 | 259 | 261 | 2 |
| Albanian (`al_windows(basic)`) | 306 | 307 | 309 | 2 |
| Ukrainian (`ua_windows(basic)`) | 180 | 194 | 194 | 0 |
| Canadian French (Legacy) (`ca_windows(basic)`) | 315 | 331 | 334 | 3 |
| Norwegian (`no_windows(basic)`) | 255 | 256 | 258 | 2 |
| Danish (`dk_windows(basic)`) | 256 | 257 | 259 | 2 |
| Finnish (`fi_windows(basic)`) | 256 | 257 | 259 | 2 |
| Dutch (`nl_windows(basic)`) | 266 | 268 | 270 | 2 |

What is **not** like Windows yet:
- An accent followed by Space: Windows gives the accent (´ ¨ ^ ~ `), Linux often an apostrophe, a quote or the ASCII
  character (33 cells over the 22 layouts). That is Linux's Compose table, shared by every layout; changing it is a
  separate decision.
- Polish (Programmers): on Windows, Shift+` is an accent key (~ then a gives ą). Linux's Compose table gives other
  letters for it (ã), so the prototype keeps Linux's plain ~ (21 cells).
- Ctrl+Alt as AltGr: Windows does this on all these layouts; on Linux it needs keyd (the Belgian package has it for
  Belgian only). Not in this prototype.
- German: Windows data (CLDR and Microsoft's own table) say Caps Lock gives the Shift character on the digit row
  (Caps Lock + 1 = !). Not yet confirmed on a real Windows PC. The same holds for every Caps Lock behaviour taken from
  CLDR: the data is checked, a real Windows PC is not.

Not tested: a real desktop (only containers), Linux Mint's own Cinnamon build and a Cinnamon session typing test
(only Cinnamon's layout lookup was checked), the login screen, the text console, the installer, Fedora, openSUSE,
Arch.

## All 208 Windows layouts (dry run, not packaged)

The same generator was run on all 208 Windows layouts in CLDR 43, each on its closest Linux layout: all 208
compile with both libxkbcommon and xkbcomp, and both give the same result. For 147 of them every key types like
Windows with no Linux character lost; 70 are like Windows on accent sequences too. The other 61 need work layout by
layout (for example Cherokee, Burmese, Sinhala). Results are kept outside the package.

How the 18 were chosen: a Windows layout used by many people, on the Linux layout of the same name, where the new
layout has no key that types something else than Windows, loses no Linux character, gains at least one cell, and
leaves nothing but accent + Space. Already like Windows on Linux, so nothing to add (except accent + Space):
Swedish, Latin American, Romanian (Standard). Left for later, the harder ones:
- accents that Linux's Compose table gives differently (not only accent + Space): Irish, Turkish Q, Greek,
  US-International, Polish (214), Serbian (Latin), Slovenian, Latvian;
- a Linux character would be lost on the extra key next to Left Shift: Russian, Belarusian, Kazakh;
- Caps Lock not expressible with the stock key types: Bulgarian;
- Linux has characters on level 5 and up (Right Ctrl) on the key Windows changes: Canadian Multilingual Standard;
- not yet looked at one by one: Czech, Slovak and the rest.

## Run it

    python3 -I world/tools/gen_windows_symbols.py world/layouts.tsv world/cldr-43 world/xkb/symbols
    python3 -I world/tools/check_windows_symbols.py world/layouts.tsv world/cldr-43 world/xkb
    sh world/build-deb.sh OUTDIR                      # needs dpkg-buildpackage and debhelper
    world/tests/coexist.sh BELGIAN_DEB WORLD_DEB .    # disposable system only
    world/tests/cinnamon-lookup.sh WORLD_DEB .        # disposable system only
