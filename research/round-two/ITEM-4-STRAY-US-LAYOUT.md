# Round two, item 4: the hidden extra "us" layout on Mint (and Zorin) in Dutch and German

3 Nov 2026, 23:20-23:45 Belgian time. Cloud containers only. Not yet sent upstream. Evidence: `evidence/raw-logs/2026-11-03-round-two-4-stray-us/` (SUMMARY.txt = every result line).

## Kort (Nederlands)
- Waarom staat er "be,us" op Mint als je Nederlands kiest? Cinnamon (en ook GNOME op Zorin) voegt stil de indeling van je
  taal toe. Hun tabel kent wel "Frans (België) = be", maar **niet** "Nederlands (België)" en ook niet Waals of Duits
  (België). Dan valt het terug op US.
- Fix: drie regels in die tabel (nl_BE, wa_BE, li_BE = be). Getest op Mint 22.3 en op GNOME 46: Nederlands gedraagt zich
  daarna precies zoals Frans. Samen met een wijziging die Cinnamon al in maart 2026 maakte (komt in Cinnamon 6.7, wellicht
  Mint 23) blijft er alleen "be" over.
- Duits (België) heb ik bewust **niet** veranderd: Windows geeft daar QWERTZ, dus dat is een vraag voor de makers.
- Het was en blijft onschadelijk voor typen (geen toets schakelt naar US). Dit ruimt het op.

## Cause ✔
- Cinnamon 6.6 (`js/ui/keyboardManager.js`, `_buildGroupStrings`) always appends "the layout of the UI language" to the
  running keymap (so menu shortcuts like Alt+Ф work for non-Latin languages). Mint 22.3's file (cinnamon 6.6.9+zena) is
  identical to tag 6.6.7 ✔.
- The layout comes from `CinnamonDesktop.get_input_source_from_locale()`, a fixed table in cinnamon-desktop
  (`default-input-sources.h`). It has `fr_BE → be`, but no `nl_BE`, `de_BE`, `wa_BE` or `li_BE` ✔ (same in 6.6.2 and master).
  Missing → falls back to `en_US → us` ✔ (lookup printed in the container).
- GNOME has the same table in gnome-desktop (Ubuntu 44.0-5build2 and master: only `fr_BE`) ✔ and the same unconditional
  append in GNOME Shell 46-49; GNOME 50 and later append only when the layout is missing ✔ (gnome-50, gnome-51, main).
- Cinnamon master already appends only when missing: commit b0c6e1f6 (12 Mar 2026, "don't append locale layout if
  already present", #13616), in tags 6.7.0-unstable to 6.7.9-unstable, not in 6.6 ✔.

## Test ✔ (keymap after the desktop started, Belgian as the only chosen layout)
Mint 22.3 container (cinnamon 6.6.9, cinnamon-desktop 6.6.2) on Xvfb, read with `setxkbmap -query`; Ubuntu 24.04 container
(GNOME Shell 46.0, gnome-desktop 44.0) headless, read from GNOME Shell's own keymap. Patched library built from the
distribution's own source and loaded with `LD_LIBRARY_PATH` (the lookup printed inside the run confirms it was used).

| Desktop | Change | nl_BE | fr_BE | de_BE | en_US |
|---|---|---|---|---|---|
| Cinnamon 6.6 | none (stock Mint 22.3) | **be,us** | be,be | be,us | be,us |
| Cinnamon 6.6 | table patch | **be,be** | be,be | be,us | be,us |
| Cinnamon 6.6 | 6.7 change backported (JS only) | be,us | be | be,us | be,us |
| Cinnamon 6.6 | table patch + 6.7 change | **be** | be | be,us | be,us |
| GNOME 46 | none (stock, = Zorin 18 base) | **be,us** | be,be | be,us | be,us |
| GNOME 46 | table patch | **be,be** | be,be | be,us | be,us |

Reading: the table patch makes Dutch behave exactly like French ✔. The duplicate "be,be" is what French users already get
today and disappears with Cinnamon 6.7 / GNOME 50 ✱ (GNOME 50 not run, only its code read).

## Patches (`patches/`)
- `cinnamon-desktop-6.6-and-master-be-locales.diff`: nl_BE, wa_BE, li_BE → be (the header is the same in 6.6.2 and master).
- `gnome-desktop-master-be-locales.diff` (upstream) and `gnome-desktop-44-ubuntu-be-locales.diff` (the tested one, on top
  of Ubuntu's mozc patch): the same three lines.
- `cinnamon-6.6-backport-b0c6e1f6-locale-layout-only-when-missing.diff`: Cinnamon's own March 2026 fix, backported to 6.6
  for a possible Mint 22.x update. Not ours; only tested here.

## Honest limits
- Not tested: a real Mint/Zorin desktop or login screen, Wayland Cinnamon, a user with two layouts, the other places that
  read this table (GNOME Settings / gnome-initial-setup / Cinnamon settings suggesting "Belgian" for nl_BE). That
  suggestion would be a side effect ✱, in line with Windows, which defaults nl-BE to Belgian (Period) ✔
  (Microsoft's keyboard identifier table).
- de_BE left out on purpose: Windows gives German (Belgium) the German QWERTZ layout ✔; which keyboard most East Belgians
  use is unknown. Question for the maintainers: `be` or `de`?
- Benefit is cleanliness: "be,us" never changed typing in our tests (README known issue). The link with the first-boot
  w→z in Zorin's installer Wi-Fi dialog (30 Oct) stays NOT proven.

## Upstream (later, not now)
Two tiny pull requests: linuxmint/cinnamon-desktop and GNOME gnome-desktop (merge request), each with this table. Built with AI
help (Claude). Not sent yet.
