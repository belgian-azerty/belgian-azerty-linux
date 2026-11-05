# World prototype: keyboard layouts that type like Windows

**Prototype, not released.** Built with AI help (Claude).

This folder holds a prototype for other countries, next to the Belgian package. For each Windows keyboard layout it
adds a new Linux layout that types, key for key, what Windows types: for example "German (as on Windows)" next to Linux's
own "German". The Linux layouts stay as they are, and nothing of the Belgian package (`belgian-azerty-windows`,
`keyd-belgian-windows`) is changed or replaced.

67 layouts so far:
- the pilot: German, Swiss German, Swiss French, Polish (Programmers);
- group 1 (18): French, English UK, Spanish, Portuguese, Portuguese Brazil (ABNT2), Italian, Hungarian, Estonian,
  Lithuanian, Icelandic, Faroese, Albanian, Ukrainian, French Canada (legacy), Norwegian, Danish, Finnish, Dutch;
- group 2 (20): Irish, Luxembourgish, Portuguese Brazil (ABNT), Italian (142), Hungarian (101-key), Lithuanian (IBM),
  Maltese (47-key), Finnish, Swedish and Norwegian with Sami, Guarani, Hausa, Turkmen, Azerbaijani (Latin and
  Cyrillic), Ukrainian (Enhanced), Bashkir, Tatar (and legacy), Tajik;
- group 3 (18), other scripts: Arabic (101, 102, 102 AZERTY), Kurdish (Central, Arabic script), Persian, Urdu,
  Hindi (INSCRIPT, Traditional), Gujarati, Kannada, Malayalam, Odia, Punjabi (Gurmukhi), Telugu, Khmer (NIDA), Lao,
  Vietnamese, Berber (Tifinagh, extended);
- group 4 (7): Yakut (Sakha), Persian (Standard), Hawaiian, Khmer, Sinhala, Santali (Ol Chiki), Azerbaijani
  (Standard).

## What is in it

| Part | What it does |
|---|---|
| `layouts.tsv` | The layouts of this prototype: which Windows layout (CLDR file), on which Linux layout, new name and description |
| `stock-accent.tsv` | Linux's own layouts that already type like Windows except accent + Space (they get accent-space lines, no new layout) |
| `cldr-43/` | The Windows layout files from Unicode CLDR release 43 (open data, Unicode License, `LICENSE.txt`) |
| `tools/gen_windows_symbols.py` | Writes each new layout: it includes the Linux layout unchanged, then redefines only the keys where Windows differs. Also writes the layout list `xkb/rules/evdev.xml` |
| `tools/check_windows_symbols.py` | Machine check: types every key in 6 states (plain, Shift, Caps Lock, Caps Lock+Shift, AltGr, Shift+AltGr) and every accent sequence, as libxkbcommon (Wayland) and as xkbcomp (X11) build the layout, and compares with Windows |
| `tools/gen_accent_space.py`, `tools/check_accent_space.py` | Accent then Space: the table of what Windows and Linux give per layout (`xkb/accent-space.tsv`), and the machine check of the file the command writes |
| `xkb/` | The generated files (`symbols/<name>_windows`, one per language or country, `rules/evdev.xml`, `accent-space.tsv`) |
| `packaging/`, `build-deb.sh` | The Debian/Ubuntu package `world-keyboard-windows` (0.0.1~proto4), with the command `world-keyboard-windows` |
| `tests/` | Package test next to the Belgian package, system upgrade test to Ubuntu 26.04, typing test in a headless GNOME desktop, Cinnamon layout lookup, accent-space command test |

New layout names: the Linux name plus `_windows` (`de_windows`, `fr_windows`, `gb_windows`, ...; Swiss French is
`ch_windows` variant `fr`; where xkb-data has no layout of its own for the language, a code of its own: `ie_windows`
Irish, `lu_windows` Luxembourgish, `py_windows` Guarani, `ng_windows` Hausa, `bak_windows` Bashkir, `tat_windows`
Tatar). In the layout list they appear as "German (as on Windows)", "French (as on Windows)" and
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

## Accent then Space (optional, per user)

On Windows, an accent key followed by Space gives the accent itself (´ then Space gives ´); Linux gives an apostrophe
or a quote (' and "). For these 67 layouts only ´ and ¨ differ (groups 3 and 4 have no accent key where this matters). It also works for seven of Linux's own layouts that
already type like Windows otherwise (no new layout needed): Swedish, Spanish (Latin American), French (Canada),
English (UK, extended, Windows), Romanian (standard: also ˙ then Space gives ·, as on Windows) and Northern Saami
(Norway), and Greenlandic on Danish (Windows). To get the Windows behaviour for your user (no sudo):

    world-keyboard-windows accent-space on      # then log out and in
    world-keyboard-windows accent-space off

It writes a small `~/.XCompose` that loads Linux's normal accent table and changes only the lines your layouts need
(read from GNOME, Cinnamon, KDE and `/etc/default/keyboard`). Same method as `be-azerty-fix accent-space` of the
Belgian package. A `~/.XCompose` of your own, or one you changed, is never touched (the command shows the lines to
add); with the Belgian file in place it does nothing (that file already gives ´ and ¨). It refuses when you also use a
"US international"-type layout, where ' and " are accent keys. When two of your layouts give different results on
Windows (Swiss German gives ¨, Swiss French gives "), that accent stays as on Linux. Removing the package removes
the unchanged files it wrote. GTK apps, the Terminal and the ibus input method read the file; Qt and Electron apps
(VS Code) are not checked.

## Results (4-5 Nov 2026, cloud containers only, 67 layouts, package 0.0.1~proto6)

| Check | Result |
|---|---|
| Machine check, Windows cells and accent sequences, all 67 layouts | 15,061 of 15,126 like Windows (stock Linux: 13,606); with accent-space on: 15,105 (the 21 left are the Polish ~); per layout below |
| Keys that type something else than Windows | 0 on every layout |
| Same on X11 (xkbcomp) as on Wayland (libxkbcommon) | yes, all 67 |
| Linux characters lost (where Windows has none, and anything on level 5 and up) | 0 |
| Accent-space file, machine check (`tools/check_accent_space.py`) | every accent + Space like Windows on the 67 and on the 7 Linux layouts (except the Polish ~, a plain key on Linux); no other result changed |
| Accent-space command (`tests/accent-space.sh`) | 28/28 PASS: the written file, layouts from KDE and `/etc/default/keyboard`, Linux's own layouts, layouts that disagree, US international refused, own and changed files left alone, next to the Belgian package's file, removal takes only unchanged files of ours |
| Headless GNOME Shell 46 (Ubuntu 24.04), typed through Mutter | all 67: 19,404 / 19,404 cells typed as the machine check predicted (group 4: 1,853; group 3: 4,595; in the first run the very first keystroke of the session, on Arabic (101), came out as a space, and Arabic (101) typed 232 / 232 when run again after another layout) |
| Same, with `world-keyboard-windows accent-space on` run by the user first | the 22 of the pilot and group 1 and the 7 of group 2 that have accent lines: 9,291 / 9,291 cells typed as predicted, everything like Windows except the Polish ~. Also the 7 Linux layouts of `stock-accent.tsv`: 2,420 / 2,420, all like Windows (Greenlandic added in group 4). The command found the layout in GNOME's settings and wrote the file; the desktop read it |
| Package next to belgian-azerty-windows 0.9.12 (`tests/coexist.sh`) | 208/208 PASS (more layouts, more compile checks): every Belgian file, the rules file, its diversion and xkb-data's other files byte-identical after install, removal and purge; xkb-data's list kept as `evdev.xml.distrib` and given back on removal; rebuilt after an xkb-data reinstall; a system default naming our layouts gets the Linux layouts back on removal |
| Cinnamon's layout lookup (CinnamonDesktop.XkbInfo, Ubuntu 24.04 build 6.0, `tests/cinnamon-lookup.sh`) | finds all 67 after install, none before and after removal |
| System upgrade Ubuntu 24.04 -> 26.04 (xkb-data 2.46, `tests/upgrade-2604.sh`) | ALL PASS, with (61 checks) and without (57) the Belgian package; the group 3 run found the Georgian Caps Lock change (see above) |

Per layout (machine check, cells like Windows: stock Linux -> new layout, of all cells):

| Layout | Stock Linux | New | Cells | Left without accent-space (accent + Space, unless noted) |
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
| Irish (`ie_windows(basic)`) | 229 | 230 | 231 | 1 |
| Luxembourgish (`lu_windows(basic)`) | 251 | 261 | 262 | 1 |
| Portuguese (Brazil ABNT) (`br_windows(abnt)`) | 256 | 257 | 259 | 2 |
| Italian (142) (`it_windows(142)`) | 194 | 202 | 202 | 0 |
| Hungarian 101-key (`hu_windows(101key)`) | 226 | 234 | 234 | 0 |
| Lithuanian IBM (`lt_windows(ibm)`) | 182 | 197 | 197 | 0 |
| Maltese 47-Key (`mt_windows(basic)`) | 206 | 207 | 207 | 0 |
| Finnish with Sami (`fi_windows(sami)`) | 306 | 334 | 336 | 2 |
| Swedish with Sami (`se_windows(basic)`) | 306 | 334 | 336 | 2 |
| Norwegian with Sami (`no_windows(sami)`) | 301 | 337 | 339 | 2 |
| Guarani (`py_windows(basic)`) | 256 | 268 | 270 | 2 |
| Hausa (`ng_windows(basic)`) | 197 | 206 | 206 | 0 |
| Turkmen (`tm_windows(basic)`) | 186 | 194 | 194 | 0 |
| Azeri Latin (`az_windows(basic)`) | 186 | 194 | 194 | 0 |
| Azeri Cyrillic (`az_windows(cyrillic)`) | 186 | 194 | 194 | 0 |
| Ukrainian (Enhanced) (`ua_windows(enhanced)`) | 182 | 194 | 194 | 0 |
| Bashkir (`bak_windows(basic)`) | 179 | 189 | 189 | 0 |
| Tatar (`tat_windows(basic)`) | 201 | 215 | 215 | 0 |
| Tatar (Legacy) (`tat_windows(legacy)`) | 200 | 215 | 215 | 0 |
| Tajik (`tj_windows(basic)`) | 187 | 192 | 192 | 0 |
| Arabic (101) (`ara_windows(basic)`) | 176 | 184 | 184 | 0 |
| Arabic (102) (`ara_windows(102)`) | 156 | 184 | 184 | 0 |
| Arabic (102, AZERTY) (`ara_windows(azerty)`) | 152 | 184 | 184 | 0 |
| Kurdish (Central, Arabic script) (`iq_windows(basic)`) | 174 | 190 | 190 | 0 |
| Persian (`ir_windows(basic)`) | 186 | 190 | 190 | 0 |
| Urdu (`pk_windows(basic)`) | 188 | 192 | 192 | 0 |
| Hindi (Devanagari INSCRIPT) (`in_windows(basic)`) | 177 | 213 | 213 | 0 |
| Hindi (Traditional) (`in_windows(hindi_trad)`) | 162 | 211 | 211 | 0 |
| Gujarati (`in_windows(guj)`) | 145 | 175 | 175 | 0 |
| Kannada (`in_windows(kan)`) | 139 | 175 | 175 | 0 |
| Malayalam (`in_windows(mal)`) | 166 | 188 | 188 | 0 |
| Odia (`in_windows(ori)`) | 130 | 180 | 180 | 0 |
| Punjabi (Gurmukhi) (`in_windows(guru)`) | 129 | 170 | 170 | 0 |
| Telugu (`in_windows(tel)`) | 145 | 178 | 178 | 0 |
| Khmer (NIDA) (`kh_windows(basic)`) | 203 | 204 | 204 | 0 |
| Lao (`la_windows(basic)`) | 181 | 182 | 182 | 0 |
| Vietnamese (`vn_windows(basic)`) | 252 | 288 | 288 | 0 |
| Berber (Tifinagh, extended) (`ma_windows(basic)`) | 195 | 200 | 200 | 0 |
| Yakut (`sah_windows(basic)`) | 150 | 185 | 185 | 0 |
| Persian (Standard) (`ir_windows(std)`) | 182 | 190 | 190 | 0 |
| Hawaiian (`haw_windows(basic)`) | 197 | 204 | 204 | 0 |
| Khmer (`kh_windows(khmer)`) | 131 | 263 | 263 | 0 |
| Sinhala (`lk_windows(basic)`) | 52 | 208 | 208 | 0 |
| Santali (Ol Chiki) (`in_windows(sat)`) | 30 | 100 | 100 | 0 |
| Azerbaijani (Standard) (`az_windows(std)`) | 64 | 186 | 186 | 0 |

What is **not** like Windows yet:
- An accent followed by Space, unless the user switches on accent-space (above): 44 cells over the 67 layouts.
- Polish (Programmers): on Windows, Shift+` is an accent key (~ then a gives ą). Linux's Compose table gives other
  letters for it (ã), so the prototype keeps Linux's plain ~ (21 cells).
- Ctrl+Alt as AltGr: Windows does this on all these layouts; on Linux it needs keyd (the Belgian package has it for
  Belgian only). Not in this prototype.
- German: Windows data (CLDR and Microsoft's own table) say Caps Lock gives the Shift character on the digit row
  (Caps Lock + 1 = !). Not yet confirmed on a real Windows PC. The same holds for every Caps Lock behaviour taken from
  CLDR: the data is checked, a real Windows PC is not.

Not tested: whether native speakers expect the group 3 layouts this way (they are checked against the Windows data
only), a real desktop (only containers), Linux Mint's own Cinnamon build and a Cinnamon session typing test
(only Cinnamon's layout lookup was checked), the login screen, the text console, the installer, Fedora, openSUSE,
Arch.

## All 208 Windows layouts (dry run, not packaged)

The same generator and checks were run on all 208 Windows layouts in CLDR 43 (again on 5 Nov, with the level-5
check), each on its closest Linux layout as chosen automatically: all 208 compile with both libxkbcommon and xkbcomp,
and both give the same result. Results are kept outside the package. Apart from the 42 of groups 1 and 2 (group 3
came out of the 67 below):

- 67 more would be "fast" by the numbers, but many sit on a Linux layout of another language (N'Ko and Lisu on
  Arabic, Kyrgyz on Yakut, Wolof on Moroccan French) or are in another script (Arabic, Indic scripts, Georgian,
  Khmer, Lao, Vietnamese...): each needs its Linux base checked by language first.
- 21 already type like Windows on Linux (Swedish, Latin American, Romanian, Canadian French, UK Extended, the US
  and the Chinese, Japanese and Korean US layouts...): nothing to add except accent + Space (see above).
- 3 differ only in accent results (Turkish Q, Igbo, Central Atlas Tamazight).
- 95 have keys that type something else, or would lose a Linux character: work layout by layout. Examples: Russian,
  Belarusian, Kazakh (the extra key next to Left Shift), Bulgarian (Caps Lock), Canadian Multilingual (Right Ctrl
  level), Greek, US-International, Polish (214), Serbian (Latin), Slovenian, Latvian, Czech, Slovak.

How groups 1 to 4 were chosen: on a Linux layout of the same language or country, the new layout has no key that
types something else than Windows, loses no Linux character, gains at least one cell, and leaves nothing but
accent + Space. Group 2 also: Latin or Cyrillic script, and only a few keys rewritten (Azerbaijani Standard, with 122
cells rewritten, was left out). Group 3: the "fast" layouts in other scripts whose Linux base is the same language,
with at most 50 cells rewritten (a near match shows it is the same layout; the scripts were not read by a native
speaker). Left out: layouts whose closest Linux layout is another one (Nepali, Divehi, Kyrgyz, Sakha, N'Ko, Lisu,
Wolof, Persian Standard), and ones with more than 50 cells rewritten (Khmer, Sinhala, Georgian Legacy and Old
Alphabets, Ol Chiki, Azerbaijani Standard). Georgian (QWERTY, Ergonomic, MES) passed every check on Ubuntu 24.04
but is held back: newer libxkbcommon (1.13, Ubuntu 26.04) gives Georgian capital letters (Mtavruli) with Caps Lock,
on Linux's own Georgian too, while Windows does not; the new layouts would then differ from Windows on 26.04.
Group 4: the rest of the "fast" ones, each checked again on a Linux layout of its own language: Yakut on Russian
(Sakha), Persian Standard on Persian, Hawaiian on English (US, Hawaiian); and Khmer, Sinhala, Santali (Ol Chiki) and
Azerbaijani Standard, where Windows has another arrangement than Linux (70 to 156 cells rewritten) but every check
passes. Still out: Russian and Kyrgyz (on Linux the right Alt key is a plain Alt there, on Windows it is AltGr, for
example AltGr+8 gives ₽: a change of what a key does, not made without a decision), Nepali and Divehi (Linux's
layout of the language is another arrangement: characters would be lost), N'Ko, Lisu and New Tai Lue (no Linux
layout), Sinhala Wij 9 (64 keys left), and Turkish Q, Igbo, Central Atlas Tamazight and Wolof (accent results).

## Run it

    python3 -I world/tools/gen_windows_symbols.py world/layouts.tsv world/cldr-43 world/xkb/symbols
    python3 -I world/tools/check_windows_symbols.py world/layouts.tsv world/cldr-43 world/xkb
    sh world/build-deb.sh OUTDIR                      # needs dpkg-buildpackage and debhelper
    world/tests/coexist.sh BELGIAN_DEB WORLD_DEB .    # disposable system only
    world/tests/cinnamon-lookup.sh WORLD_DEB .        # disposable system only
    world/tests/accent-space.sh BELGIAN_DEB WORLD_DEB .   # disposable system only
    python3 -I world/tools/gen_accent_space.py world/layouts.tsv world/cldr-43 world/xkb world/xkb/accent-space.tsv world/stock-accent.tsv
    python3 -I world/tools/check_accent_space.py world/layouts.tsv world/cldr-43 world/xkb
