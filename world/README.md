# World prototype: keyboard layouts that type like Windows

**Prototype, not released.** Built with AI help (Claude).

This folder holds a prototype for other countries, next to the Belgian package. For each Windows keyboard layout it
adds a new Linux layout that types, key for key, what Windows types: for example "German (as on Windows)" next to Linux's
own "German". The Linux layouts stay as they are, and nothing of the Belgian package (`belgian-azerty-windows`,
`keyd-belgian-windows`) is changed or replaced.

151 layouts so far:
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
  (Standard);
- step A (44), where Windows wins (see below): Russian (and Typewriter), Belarusian, Kazakh, Kyrgyz, Uzbek (Cyrillic),
  Bulgarian (Typewriter, Phonetic Traditional), Macedonian (2), Mongolian (4), Armenian (3), Georgian (5), Thai (4),
  Syriac (2), Pashto, Nepali, Dhivehi (2), US Dvorak (3), Ogham, Old Italic, N'Ko (3), Osmanya, Sora, Lisu, New Tai Lue;
- step B (40), accents as on Windows (see below): Greek (4) and Greek Latin (3), Turkish Q and F, Slovak (2), Czech
  (QWERTY, Programmers), Latvian (3), Polish (214), Slovenian, Serbian (Cyrillic, Latin), Bosnian (Cyrillic),
  US-International, Spanish Variation, Canadian Multilingual Standard, Scottish Gaelic, Igbo, Yoruba, Maori, Northern
  Sami (Finland, Sweden), Sorbian (3), Romanian (legacy), Sesotho sa Leboa, Setswana, Central Atlas Tamazight, Wolof,
  English (India), Futhark.

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

## Accents as on Windows: accent-space (optional, per user)

On Windows, an accent key followed by Space gives the accent itself (´ then Space gives ´); Linux gives an apostrophe
or a quote (' and "). Since step B the command covers every accent sequence where Windows gives something else than
Linux's accent table (Compose), not only accent then Space: for example ´ then ı gives í in Turkish, ˙ then z gives ż
in Sorbian, ~ then a gives ą in Polish (Programmers). It works only on real accent keys (GNOME's text input starts an
accent sequence only on one; tried in the GNOME typing test, 5 Nov), so since route 1 (below) every Windows accent of
the new layouts is a real accent key. It also works for seven of Linux's own layouts that
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

## Results (4-7 Nov 2026, cloud containers only, 151 layouts, package 0.0.1~proto9)

| Check | Result |
|---|---|
| Machine check, Windows cells and accent sequences, all 151 layouts | 33,578 of 34,542 like Windows (stock Linux: 27,483); with accent-space on: 33,995. The first 111: 23,213 of 23,275, with accent-space 23,275 |
| Keys that type something else than Windows | 0 on every layout |
| Same on X11 (xkbcomp) as on Wayland (libxkbcommon) | yes, all 151 |
| Linux characters lost (where Windows has none, and anything on level 5 and up) | 0 on the 67 of groups 1 to 4; the 44 of step A and 40 of step B follow Windows instead (712 and 65 cells listed as "only on the Linux layout", see below) |
| Accent-space file, machine check (`tools/check_accent_space.py`) | every accent + Space like Windows on the 151 and on the 7 Linux layouts, except on keys that stay plain or share an accent key (see route 1); no other result changed |
| Accent-space command (`tests/accent-space.sh`) | 32/32 PASS (also: Turkish Q and Polish (Programmers) get lines for other accent sequences, and the machine check of those files): the written file, layouts from KDE and `/etc/default/keyboard`, Linux's own layouts, layouts that disagree, US international refused, own and changed files left alone, next to the Belgian package's file, removal takes only unchanged files of ours |
| Headless GNOME Shell 46 (Ubuntu 24.04), typed through Mutter | groups 1 to 4, all 67: 19,404 / 19,404 cells typed as the machine check predicted (group 4: 1,853; group 3: 4,595; in the first run the very first keystroke of the session, on Arabic (101), came out as a space, and Arabic (101) typed 232 / 232 when run again after another layout) |
| Same, step A (44 layouts) | every Windows cell typed like Windows: 8,149 / 8,149. 2,115 other cells, all Right Alt + a key on layouts where Right Alt stays a plain Alt key (as on Windows for those layouts, where Windows has nothing there): the desktop types nothing (Alt is a shortcut key), the machine check had predicted a letter. Not a layout fault; stock Linux was not typed for comparison |
| Same, step B (40 layouts) | 13,102 / 13,181 cells typed as predicted; without accent-space 10,044 / 10,900 Windows cells like Windows. The 79 others: 68 Right Alt + a key on Futhark where Windows has nothing (as in step A), 11 on Greek Polytonic where the desktop shows another spacing sign for an unmatched accent (ʽ, ͺ) than the prediction (the prediction's fault) |
| Same, step B, with accent-space on | 13,113 / 13,181 as predicted (the 68 Futhark Right Alt cells), 10,392 / 10,900 like Windows. A first version that made plain keys accent keys (Polish ~, Latvian ') failed here: the desktop typed ~ then the letter; that part was taken out |
| Same, route 1 (safe version, proto9): the 10 layouts whose accent keys changed since step B plus Irish, Latvian (Standard), Scottish Gaelic and English (India), with accent-space on | 4,701 / 4,701 cells typed as predicted; 3,498 / 3,910 Windows cells like Windows: every one on Polish (Programmers) 228 / 228, Irish, Greek (220), Polish (214), United States-International and Romanian (Legacy); Greek Polytonic 243 / 458, Latvian (Standard) 301 / 376, English (India) 235 / 300 (keys that stay as on Linux, see route 1) |
| Same, route 1, without accent-space | 4,690 / 4,701 as predicted; the 11 others are on Greek Polytonic, where the desktop showed the accent's sign (ʽ, ͺ) and the prediction wrote the keysym's name: same result, different spelling. No accent key gives an odd sign instead of the accent: keys where that would happen stay as on Linux |
| Same, with `world-keyboard-windows accent-space on` run by the user first | the 22 of the pilot and group 1 and the 7 of group 2 that have accent lines: 9,291 / 9,291 cells typed as predicted, everything like Windows except the Polish ~. Also the 7 Linux layouts of `stock-accent.tsv`: 2,420 / 2,420, all like Windows (Greenlandic added in group 4). The command found the layout in GNOME's settings and wrote the file; the desktop read it |
| Package next to belgian-azerty-windows 0.9.12 (`tests/coexist.sh`) | 409/409 PASS (more layouts, more compile checks): every Belgian file, the rules file, its diversion and xkb-data's other files byte-identical after install, removal and purge; xkb-data's list kept as `evdev.xml.distrib` and given back on removal; rebuilt after an xkb-data reinstall; a system default naming our layouts gets the Linux layouts back on removal |
| Cinnamon's layout lookup (CinnamonDesktop.XkbInfo, Ubuntu 24.04 build 6.0, `tests/cinnamon-lookup.sh`) | finds all 151 after install, none before and after removal (the first step B run found 5 not: the first layout of a name must be the basic one; fixed, and the generator now stops otherwise) |
| System upgrade Ubuntu 24.04 -> 26.04 (xkb-data 2.46, `tests/upgrade-2604.sh`) | ALL PASS, with (94 checks) and without (90) the Belgian package, also the machine check on the newer libxkbcommon 1.13; the group 3 run found the Georgian Caps Lock change (see above) |

Per layout (machine check, cells like Windows: stock Linux -> new layout, of all cells):

| Layout | Stock Linux | New | Cells | Left without accent-space (accent + Space, unless noted) |
|---|---|---|---|---|
| German (`de_windows(basic)`) | 208 | 239 | 240 | 1 |
| Swiss German (`ch_windows(basic)`) | 256 | 260 | 262 | 2 |
| Swiss French (`ch_windows(fr)`) | 251 | 261 | 262 | 1 |
| Polish (Programmers) (`pl_windows(basic)`) | 204 | 212 | 230 | 18 (~ then a letter; with accent-space 0, see route 1 below) |
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
| Belarusian (`by_windows(basic)`) | 188 | 192 | 192 | 0 (rule windows: 2 cells only on the Linux layout) |
| Bulgarian (Typewriter) (`bg_windows(basic)`) | 171 | 192 | 192 | 0 (rule windows: 10 cells only on the Linux layout) |
| Bulgarian (Phonetic Traditional) (`bg_windows(phonetic_trad)`) | 182 | 194 | 194 | 0 (rule windows: 42 cells only on the Linux layout) |
| Dhivehi (Phonetic) (`mv_windows(basic)`) | 171 | 198 | 198 | 0 (rule windows: 0 cells only on the Linux layout) |
| Dhivehi (Typewriter) (`mv_windows(typewriter)`) | 52 | 198 | 198 | 0 (rule windows: 0 cells only on the Linux layout) |
| English (US, Dvorak) (`us_windows(basic)`) | 188 | 192 | 192 | 0 (rule windows: 2 cells only on the Linux layout) |
| English (US, Dvorak for left hand) (`us_windows(dvorak_l)`) | 188 | 192 | 192 | 0 (rule windows: 2 cells only on the Linux layout) |
| English (US, Dvorak for right hand) (`us_windows(dvorak_r)`) | 188 | 192 | 192 | 0 (rule windows: 2 cells only on the Linux layout) |
| Ogham (`ie_windows(ogam)`) | 52 | 58 | 58 | 0 (rule windows: 3 cells only on the Linux layout) |
| Armenian (Eastern, legacy) (`am_windows(basic)`) | 170 | 192 | 192 | 0 (rule windows: 11 cells only on the Linux layout) |
| Armenian (Western, legacy) (`am_windows(western)`) | 178 | 192 | 192 | 0 (rule windows: 7 cells only on the Linux layout) |
| Armenian (Phonetic) (`am_windows(phonetic)`) | 182 | 234 | 234 | 0 (rule windows: 2 cells only on the Linux layout) |
| Georgian (QWERTY) (`ge_windows(basic)`) | 172 | 178 | 178 | 0 (rule windows: 0 cells only on the Linux layout) |
| Georgian (ergonomic) (`ge_windows(ergonomic)`) | 166 | 173 | 173 | 0 (rule windows: 0 cells only on the Linux layout) |
| Georgian (MES) (`ge_windows(mes)`) | 209 | 217 | 217 | 0 (rule windows: 0 cells only on the Linux layout) |
| Georgian (legacy) (`ge_windows(legacy)`) | 10 | 198 | 198 | 0 (rule windows: 0 cells only on the Linux layout) |
| Georgian (Old Alphabets) (`ge_windows(old)`) | 13 | 233 | 233 | 0 (rule windows: 0 cells only on the Linux layout) |
| Kazakh (`kz_windows(basic)`) | 188 | 192 | 192 | 0 (rule windows: 2 cells only on the Linux layout) |
| Kyrgyz (`kg_windows(basic)`) | 176 | 198 | 198 | 0 (rule windows: 2 cells only on the Linux layout) |
| Old Italic (`it_windows(oldital)`) | 0 | 76 | 76 | 0 (rule windows: 49 cells only on the Linux layout) |
| N'Ko (Bambara) (`nqo_windows(basic)`) | 24 | 172 | 172 | 0 (rule windows: 78 cells only on the Linux layout) |
| N'Ko (Dyula) (`nqo_windows(dyu)`) | 24 | 172 | 172 | 0 (rule windows: 78 cells only on the Linux layout) |
| N'Ko (Mandinka) (`nqo_windows(man)`) | 24 | 172 | 172 | 0 (rule windows: 78 cells only on the Linux layout) |
| Macedonian (Standard) (`mk_windows(basic)`) | 176 | 209 | 209 | 0 (rule windows: 2 cells only on the Linux layout) |
| Macedonian (legacy) (`mk_windows(legacy)`) | 184 | 203 | 203 | 0 (rule windows: 2 cells only on the Linux layout) |
| Mongolian (Cyrillic) (`mn_windows(basic)`) | 146 | 192 | 192 | 0 (rule windows: 3 cells only on the Linux layout) |
| Mongolian (Mongolian script) (`mn_windows(mong)`) | 114 | 154 | 154 | 0 (rule windows: 9 cells only on the Linux layout) |
| Mongolian (Traditional, standard) (`mn_windows(mong_std)`) | 144 | 152 | 152 | 0 (rule windows: 4 cells only on the Linux layout) |
| Phags-pa (`mn_windows(phags)`) | 36 | 180 | 180 | 0 (rule windows: 13 cells only on the Linux layout) |
| Pashto (`af_windows(basic)`) | 201 | 230 | 230 | 0 (rule windows: 0 cells only on the Linux layout) |
| Russian (`ru_windows(basic)`) | 188 | 193 | 193 | 0 (rule windows: 3 cells only on the Linux layout) |
| Russian (Typewriter) (`ru_windows(typewriter)`) | 188 | 193 | 193 | 0 (rule windows: 2 cells only on the Linux layout) |
| Osmanya (`so_windows(basic)`) | 64 | 148 | 148 | 0 (rule windows: 60 cells only on the Linux layout) |
| Sora (`in_windows(sora)`) | 64 | 138 | 138 | 0 (rule windows: 62 cells only on the Linux layout) |
| Syriac (`sy_windows(basic)`) | 188 | 228 | 228 | 0 (rule windows: 40 cells only on the Linux layout) |
| Syriac (Phonetic) (`sy_windows(phonetic)`) | 188 | 228 | 228 | 0 (rule windows: 40 cells only on the Linux layout) |
| Thai (Kedmanee) (`th_windows(basic)`) | 141 | 192 | 192 | 0 (rule windows: 2 cells only on the Linux layout) |
| Thai (Kedmanee, non-ShiftLock) (`th_windows(kedmanee_nsl)`) | 188 | 192 | 192 | 0 (rule windows: 2 cells only on the Linux layout) |
| Thai (Pattachote) (`th_windows(pattachote)`) | 138 | 192 | 192 | 0 (rule windows: 4 cells only on the Linux layout) |
| Thai (Pattachote, non-ShiftLock) (`th_windows(pattachote_nsl)`) | 184 | 192 | 192 | 0 (rule windows: 4 cells only on the Linux layout) |
| Uzbek (Cyrillic) (`uz_windows(basic)`) | 186 | 192 | 192 | 0 (rule windows: 3 cells only on the Linux layout) |
| Nepali (`np_windows(basic)`) | 6 | 148 | 148 | 0 (rule windows: 2 cells only on the Linux layout) |
| Lisu (`lis_windows(basic)`) | 25 | 180 | 180 | 0 (rule windows: 83 cells only on the Linux layout) |
| New Tai Lue (`khb_windows(basic)`) | 12 | 206 | 206 | 0 (rule windows: 2 cells only on the Linux layout) |

Step B (rule windows, accents; "With accent-space": after `world-keyboard-windows accent-space on`):

| Layout | Stock Linux | New | With accent-space | Cells |
|---|---|---|---|---|
| Greek (`gr_windows(basic)`) | 210 | 226 | 228 | 236 |
| Greek (220) (`gr_windows(el220)`) | 159 | 233 | 245 | 245 |
| Greek (319) (`gr_windows(el319)`) | 155 | 212 | 214 | 217 |
| Greek (polytonic) (`gr_windows(polytonic)`) | 197 | 230 | 264 | 512 |
| Greek (Latin) (`gr_windows(latin)`) | 180 | 304 | 308 | 308 (2 cells only on the Linux layout) |
| Greek (220 Latin) (`gr_windows(latin220)`) | 140 | 202 | 204 | 214 (2 cells only on the Linux layout) |
| Greek (319 Latin) (`gr_windows(latin319)`) | 148 | 245 | 247 | 247 (2 cells only on the Linux layout) |
| Turkish (Q) (`tr_windows(basic)`) | 217 | 266 | 276 | 276 |
| Turkish (F) (`tr_windows(f)`) | 232 | 290 | 300 | 300 |
| Slovak (`sk_windows(basic)`) | 239 | 356 | 360 | 360 |
| Slovak (QWERTY) (`sk_windows(qwerty)`) | 239 | 359 | 362 | 362 |
| Czech (QWERTY) (`cz_windows(basic)`) | 266 | 292 | 294 | 294 |
| Czech (Programmers) (`cz_windows(prog)`) | 156 | 303 | 305 | 305 |
| Latvian (Standard) (`lv_windows(basic)`) | 211 | 228 | 303 | 382 |
| Latvian (`lv_windows(ergonomic)`) | 192 | 270 | 278 | 278 |
| Latvian (QWERTY) (`lv_windows(qwerty)`) | 209 | 256 | 263 | 263 |
| Polish (214) (`pl_windows(qwertz)`) | 281 | 307 | 311 | 311 |
| Slovenian (`si_windows(basic)`) | 296 | 316 | 319 | 319 |
| Serbian (Cyrillic) (`rs_windows(basic)`) | 189 | 193 | 193 | 200 |
| Serbian (Latin) (`rs_windows(latin)`) | 298 | 301 | 303 | 310 |
| Bosnian (Cyrillic) (`ba_windows(basic)`) | 196 | 203 | 203 | 210 |
| English (US, international) (`us_windows(intl)`) | 302 | 306 | 308 | 308 |
| Spanish (Variation) (`es_windows(variation)`) | 153 | 304 | 308 | 308 |
| Canadian (Multilingual Standard) (`ca_windows(multix)`) | 254 | 266 | 267 | 267 (1 cells only on the Linux layout) |
| Scottish Gaelic (`gb_windows(gla)`) | 187 | 217 | 217 | 232 |
| Igbo (`ng_windows(igbo)`) | 162 | 221 | 245 | 245 |
| Yoruba (`ng_windows(yoruba)`) | 168 | 207 | 207 | 231 |
| Maori (`nz_windows(basic)`) | 186 | 192 | 203 | 203 |
| Northern Sami (Finland, extended) (`fi_windows(smi)`) | 310 | 342 | 344 | 344 |
| Northern Sami (Sweden, extended) (`se_windows(smi)`) | 310 | 342 | 344 | 344 |
| Sorbian (Standard) (`de_windows(dsb)`) | 197 | 228 | 241 | 241 (1 cells only on the Linux layout) |
| Sorbian (Extended) (`de_windows(dsb_ext)`) | 193 | 237 | 278 | 278 (1 cells only on the Linux layout) |
| Sorbian (Standard, legacy) (`de_windows(dsb_legacy)`) | 202 | 246 | 280 | 280 (1 cells only on the Linux layout) |
| Romanian (legacy) (`ro_windows(basic)`) | 292 | 301 | 306 | 306 |
| Sesotho sa Leboa (`za_windows(basic)`) | 175 | 279 | 279 | 310 |
| Setswana (`bw_windows(basic)`) | 174 | 293 | 293 | 310 |
| Central Atlas Tamazight (Latin) (`ma_windows(tzm)`) | 175 | 233 | 257 | 257 |
| Wolof (`sn_windows(basic)`) | 159 | 245 | 246 | 246 |
| English (India) (`in_windows(eng)`) | 189 | 234 | 237 | 308 |
| Old Norse (Futhark) (`us_windows(futhark)`) | 2 | 80 | 80 | 100 (55 cells only on the Linux layout) |

What is **not** like Windows yet:
- Accent results where Windows differs, unless the user switches on accent-space (above): 964 cells over the
  151 layouts. With accent-space on, 547 are left: keys that stay as on Linux because no accent key is safe without
  accent-space (route 1), most in Greek Polytonic (248), Latvian (Standard) (79) and English (India) (71); also
  Sesotho sa Leboa, Yoruba, Futhark, Setswana, Scottish Gaelic, Greek, Serbian and Bosnian (Cyrillic).
- With two layouts that give different results for the same accent sequence (for example two layouts that both use
  dead_belowring for different accents), that sequence stays as on Linux for that user.
- Ctrl+Alt as AltGr: Windows does this on all these layouts; on Linux it needs keyd (the Belgian package has it for
  Belgian only). Not in this prototype.
- German: Windows data (CLDR and Microsoft's own table) say Caps Lock gives the Shift character on the digit row
  (Caps Lock + 1 = !). Not yet confirmed on a real Windows PC. The same holds for every Caps Lock behaviour taken from
  CLDR: the data is checked, a real Windows PC is not.

Not tested: the Windows data on a real Windows PC (every layout is checked against CLDR 43 only), a real desktop (only
containers), Linux Mint's own Cinnamon build and a Cinnamon session typing test
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

Step A (5 Nov, Younes: "fill in everything that is missing"): the rule for these layouts is **Windows wins, and the
Linux layout stays next to it, unchanged**. Someone used to Linux keeps the Linux layout; someone coming from Windows
picks the "(as on Windows)" one; both can be in the list. In table rows marked `rule = windows`:
- where Windows puts something else on a key, the new layout follows Windows, also on keys with characters on level 5
  and up. What the Linux layout had there is listed by the check as "only on the Linux layout" (712 cells over the
  44; many are Right Alt + a key on layouts without AltGr, where Linux gives the plain letter);
- Right Alt becomes AltGr when the Windows layout has AltGr characters and the Linux layout has no AltGr (Russian:
  AltGr+8 gives ₽, as on Windows); where Windows has no AltGr characters, Right Alt stays Alt;
- with no Linux layout of the language (N'Ko, Lisu, New Tai Lue, Osmanya, Sora, Old Italic, Phags-pa) or one with
  another arrangement (Nepali, Dhivehi Typewriter, Georgian Legacy and Old Alphabets), the new layout is built on
  English (US) or on that layout, with every Windows key rewritten.
Georgian is back: Caps Lock keeps the small letters as on Windows, also with libxkbcommon 1.13 (Ubuntu 26.04), which
gives capitals (Mtavruli) on Linux's own Georgian. German (IBM) was left for later: Shift+AltGr works differently on
its Linux layout.

Step B (5 Nov, Younes agreed): 40 layouts whose accents give other results than Linux, same rule (`rule = windows`).
- The accent keys are where Windows has them, also where Linux's accent table gives other results for some of their
  sequences (before, such a key kept Linux's plain character). Without accent-space they give Linux's results; with
  accent-space on (per user, off until switched on) they give Windows's results.
- Route 1 (7 Nov, Younes: "doe daarna route 1", then "veilige versie"): the Polish (Programmers) ~ is an accent key
  as on Windows (rule `accents`: only its accent keys follow Windows): ~ then a gives ã without accent-space (Linux), ą
  with it (Windows). A Windows accent xkb has no accent key of its own for (Yoruba ', Greek Polytonic « and ») gets a free
  xkb accent keysym only when that key, without accent-space, gives the accent itself after Space and no wrong letter
  (Yoruba ' becomes dead_acute). Where no keysym is safe like that (the ' of Latvian (Standard), Scottish Gaelic,
  Serbian, Bosnian (Cyrillic), Sesotho sa Leboa; Greek ΅ in some Greek layouts; most of Greek Polytonic), the key
  stays as on Linux: a first build gave those keys an unused accent keysym, and without accent-space "it's" came out
  as "it˳s" (GNOME typing test), so that was not kept. A plain key with ~/.XCompose lines (tried first, 5 Nov) does
  not work in GNOME at all.
- Each was put on a Linux layout of its own language (Greek on Greek, Sorbian on Lower Sorbian QWERTZ, Igbo and Yoruba
  on Nigeria's, Maori on Maori, Wolof on Wolof...); Greek Latin and Futhark on English (US).
- Moved to step C: Czech (QWERTZ; Caps Lock gives capitals on the digit row, a key type Linux does not have), Cherokee
  Phonetic and Russian Mnemonic (most of their text comes from letter keys used as accent keys, which this method does
  not do).

Still to do (step C, proposals first): layouts with keys that type two characters at once, Caps Lock behaviours
Linux's key types do not have (Czech), letter keys as accent keys (Cherokee Phonetic, Russian Mnemonic), German (IBM).

## Run it

    python3 -I world/tools/gen_windows_symbols.py world/layouts.tsv world/cldr-43 world/xkb/symbols
    python3 -I world/tools/check_windows_symbols.py world/layouts.tsv world/cldr-43 world/xkb
    sh world/build-deb.sh OUTDIR                      # needs dpkg-buildpackage and debhelper
    world/tests/coexist.sh BELGIAN_DEB WORLD_DEB .    # disposable system only
    world/tests/cinnamon-lookup.sh WORLD_DEB .        # disposable system only
    world/tests/accent-space.sh BELGIAN_DEB WORLD_DEB .   # disposable system only
    python3 -I world/tools/gen_accent_space.py world/layouts.tsv world/cldr-43 world/xkb world/xkb/accent-space.tsv world/stock-accent.tsv
    python3 -I world/tools/check_accent_space.py world/layouts.tsv world/cldr-43 world/xkb
