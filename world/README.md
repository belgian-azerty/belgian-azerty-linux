# World prototype: keyboard layouts that type like Windows

**Prototype, not released.** Built with AI help (Claude).

This folder holds a prototype for other countries, next to the Belgian package. For each Windows keyboard layout it
adds a new Linux layout that types, key for key, what Windows types: for example "German (Windows)" next to Linux's
own "German". The Linux layouts stay as they are, and nothing of the Belgian package (`belgian-azerty-windows`,
`keyd-belgian-windows`) is changed or replaced.

## What is in it

| Part | What it does |
|---|---|
| `pilot.tsv` | The layouts of this prototype: German, Swiss German, Swiss French, Polish (Programmers) |
| `cldr-43/` | The four Windows layout files from Unicode CLDR release 43 (open data, Unicode License, `LICENSE.txt`) |
| `tools/gen_windows_symbols.py` | Writes each new layout: it includes the Linux layout unchanged, then redefines only the keys where Windows differs. Also writes the layout list `xkb/rules/evdev.xml` |
| `tools/check_windows_symbols.py` | Machine check: types every key in 6 states (plain, Shift, Caps Lock, Caps Lock+Shift, AltGr, Shift+AltGr) and every accent sequence, as libxkbcommon (Wayland) and as xkbcomp (X11) build the layout, and compares with Windows |
| `xkb/` | The generated files (`symbols/de_windows`, `ch_windows`, `pl_windows`, `rules/evdev.xml`) |
| `packaging/`, `build-deb.sh` | The Debian/Ubuntu package `world-keyboard-windows` (0.0.1~proto1) |
| `tests/` | Package test next to the Belgian package, system upgrade test to Ubuntu 26.04, typing test in a headless GNOME desktop |

New layout names: `de_windows`, `ch_windows` (variant `fr` for Swiss French), `pl_windows`. In GNOME they appear in
the layout list as "German (Windows)", "German (Switzerland, Windows)", "French (Switzerland, Windows)" and
"Polish (Windows, Programmers)".

## How the package stays out of the way

- It owns no file in the system keyboard folder. It keeps its files in `/usr/lib/world-keyboard-windows/` and
  copies them to the keyboard folder, each copy with a marker line, so only its own files are ever replaced or removed.
  Reason: xkb-data 2.46 (Ubuntu 26.04, Linux Mint 23, Debian 14) turns the folder into a link and refuses while
  another package owns files there (the problem belgian-azerty-windows 0.9.11/0.9.12 had to fix). An apt hook takes
  the copies out before that switch and puts them back after, the same way the Belgian package does for its own files.
- No diversion, no change to the rules file, no change to xkb-data's layout list: the layout list for desktops is a
  separate file, `/etc/xkb/rules/evdev.xml`, which libxkbcommon's registry reads next to the system list. A file
  there that is not ours is left alone.
- It sets nothing. On removal, a system default (`/etc/default/keyboard`) that names one of its layouts gets the
  Linux layout back (`ch_windows` -> `ch`), so the keyboard never falls back to US.

## Results (4 Nov 2026, cloud containers only)

| Check | Result |
|---|---|
| Machine check, Windows cells and accent sequences | German 239/240, Swiss German 260/262, Swiss French 261/262, Polish (Programmers) 209/230 like Windows (stock Linux: 208, 256, 251, 204) |
| Same on X11 (xkbcomp) as on Wayland (libxkbcommon) | yes, all four |
| Linux characters lost (where Windows has none) | 0 |
| Headless GNOME Shell 46 (Ubuntu 24.04), typed through Mutter | 1,241 / 1,241 cells typed as the machine check predicted |
| Package next to belgian-azerty-windows 0.9.12 (`tests/coexist.sh`) | 33/33 PASS: every Belgian file, the rules file, its diversion and xkb-data's files byte-identical after install, removal and purge |
| System upgrade Ubuntu 24.04 -> 26.04 (xkb-data 2.46, `tests/upgrade-2604.sh`) | ALL PASS, with and without the Belgian package |

What is **not** like Windows yet:
- An accent followed by Space: Windows gives the accent (´ ¨), Linux an apostrophe or a quote (4 cells over the three
  German-family layouts). That is Linux's Compose table, shared by every layout; changing it is a separate decision.
- Polish (Programmers): on Windows, Shift+` is an accent key (~ then a gives ą). Linux's Compose table gives other
  letters for it (ã), so the prototype keeps Linux's plain ~ (21 cells).
- Ctrl+Alt as AltGr: Windows does this on all these layouts; on Linux it needs keyd (the Belgian package has it for
  Belgian only). Not in this prototype.
- German: Windows data (CLDR and Microsoft's own table) say Caps Lock gives the Shift character on the digit row
  (Caps Lock + 1 = !). Not yet confirmed on a real Windows PC.

Not tested: a real desktop (only containers), Linux Mint's Cinnamon (its layout chooser reads only the system list,
so the layouts probably do not show there yet), the login screen, the text console, the installer, Fedora, openSUSE,
Arch.

## All 208 Windows layouts (dry run, not packaged)

The same generator was run on all 208 Windows layouts in CLDR 43, each on its closest Linux layout: all 208
compile with both libxkbcommon and xkbcomp, and both give the same result. For 147 of them every key types like
Windows with no Linux character lost; 70 are like Windows on accent sequences too. The other 61 need work layout by
layout (for example Canadian Multilingual, Cherokee, Burmese, Sinhala). Results are kept outside the package.

## Run it

    python3 -I world/tools/gen_windows_symbols.py world/pilot.tsv world/cldr-43 world/xkb/symbols
    python3 -I world/tools/check_windows_symbols.py world/pilot.tsv world/cldr-43 world/xkb
    sh world/build-deb.sh OUTDIR                      # needs dpkg-buildpackage and debhelper
    world/tests/coexist.sh BELGIAN_DEB WORLD_DEB .    # disposable system only
