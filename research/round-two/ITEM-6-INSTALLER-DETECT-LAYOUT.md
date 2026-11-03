# Round two, item 6: the installer's "detect keyboard layout" turns a Belgian keyboard into French

3 Nov 2026, 23:15-00:45 Belgian time. Cloud containers only, no installer window. Not yet sent upstream. Evidence: `evidence/raw-logs/2026-11-03-round-two-6-detect-layout/`.
Background: on a real laptop with a Zorin 18.1 live stick (30 Oct), "Toetsenbordindeling vaststellen" (detect keyboard
layout) jumped to French.

## Kort (Nederlands)
- De knop "Toetsenbordindeling vaststellen" stelt vragen uit een vaste vragenlijst van Ubuntu (`pc105.tree`). Ik heb de
  echte installercode van Mint laten lopen met een Belgisch toetsenbord: **elk** pad eindigt op Frans. Niet alleen op die
  laptop: het kan met een Belgisch toetsenbord nooit "Belgisch" worden.
- Oorzaak: om Belgisch van Frans te onderscheiden vraagt de lijst "staat œ op je toetsenbord?". Op Belgische toetsen
  staat œ niet (het zit verstopt onder AltGr+o). Dus antwoord je eerlijk "nee", en dan wordt het Frans.
- Dat zit in alle Ubuntu-versies die ik nakeek, van 24.04 tot de nieuwste (4 versies van de lijst).
- Fix: een kleine aanpassing in het programma dat de lijst maakt (keymapper). De nieuwe lijst vraagt dan "druk op !"
  (op Belgisch zit ! op de 8-toets, op Frans ergens anders). Getest: alle 4 Belgische varianten worden "Belgisch", en van
  de 41 indelingen in de lijst wordt er geen enkele slechter, behalve één Franse variant die nu als gewoon Frans herkend wordt (zie limieten).
- **Niet** getest in het echte installervenster; alleen de code erachter.

## What happens ✔
- Ubiquity (Mint 22.3 `24.04.3+mint19`, `ubiquity/keyboard_detector.py` + `frontend/gtk_components/keyboard_query.py`)
  walks `/usr/share/console-setup/pc105.tree`: PRESS (press one of these signs; the key code chooses the next step),
  FIND/FINDP (is this sign on your keyboard? yes/no), MAP (result). The window shows the same question for FIND and
  FINDP ✔ (code).
- Walked with Ubiquity's own `KeyboardDetector` class (unchanged) and a model Belgian keyboard from xkb `be`
  (`sim.py`, every possible answer path): shipped tree → `fr:oss` on all 5 paths ✔. With the AltGr signs that are
  really printed on Belgian key caps (| @ # ^ { } [ ] ´ ` \ ~ €): still `fr:oss` ✔. Even if the person counts every
  AltGr sign (so says yes to œ): `fr:latin9` ✔. "Belgian" is unreachable.
- Same result for the trees in console-setup 1.226ubuntu1 and 1.226ubuntu1.1 (Ubuntu 24.04, the base of Mint 22 and
  Zorin 18), 1.237ubuntu3.1 (26.04) and 1.248ubuntu3 (newest) ✔. Which exact one is on the Mint 22.3 and Zorin 18.1
  ISOs: not checked (both 24.04 versions fail the same way).
- The questions on the Belgian path: "press )" or a letter → "is œ there?" → "is º there?" → … The tree reaches
  `MAP be` only after "yes, œ is there" in a branch where it already got "no, œ is not there" ✔ (steps 94-99).

## Why ✔ (keymapper 0.6.3ubuntu0~24.04 = 0.6.4ubuntu1, `keymapper/tree.py`, identical files)
1. `choose_sym()` tries only the 10 highest-ranked "press a key" signs (letters rank highest). Belgian and French AZERTY
   have the same letters, so none of the 10 separates them; signs that do (§ ! on different keys) are never tried. It
   then falls back to yes/no questions about signs that exist only on AltGr levels, such as œ, which are often not
   printed on key caps.
2. Small bug: `if exc == SingleMapping:` compares an exception object with its class, which is always false, so every
   yes/no question is written as FINDP ("plain or Shift only") even when the split was made on AltGr signs ✔. No
   visible effect in Ubiquity (same question text), fixed anyway.
- We rebuilt the tree from source (console-setup 1.226ubuntu1.1 `Keyboard/` rules, kbdcompiler, keymaptree, xkb-data
  2.41): same behaviour as the shipped file on all 41 layouts ✔ (`eval/`).

## Fix (`patches/keymapper-0.6.4-detect-tree-primary-keys-first.diff`, 18 changed lines)
- Before falling back to "is this AltGr sign there?", also try the "press a key" signs on plain/Shift levels that the
  depth limit skipped.
- `isinstance(exc, SingleMapping)` instead of `==`.
- Resulting tree: `patches/pc105.tree.fixed-belgian`. Generation time 19 s (a simpler "try 40 signs" change made the
  generator crash with RecursionError; a "skip all AltGr questions" change could no longer tell Belgian, French and
  most Cyrillic layouts apart; both dropped).

## Test ✔ (tree level, same inputs, stock keymapper vs fixed keymapper)
| Layout | Stock tree | Fixed tree |
|---|---|---|
| be (Belgian), be:oss, be:nodeadkeys, be:iso-alternate, with Belgian key-cap signs | French | **Belgian** (question: "press !", key 9) ✔ |
| fr (French) | fr:oss | **fr** ✔ |
| fr:oss, only plain/Shift visible | fr:oss | fr (still French AZERTY; fr:oss differs only on AltGr) |
| lv, every AltGr sign visible | 8 of 23 paths right | 10 of 25 |
| other 37 layouts (incl. fr:latin9), both models | unchanged | unchanged |

Checked with a fast walker (`fasteval.py`) that gives the same results as Ubiquity's own code on the shipped tree ✔,
for two models of what people see: plain+Shift only, and plain+Shift+AltGr. The Belgian paths were also run through
Ubiquity's own code on the fixed tree ✔.

## Honest limits
- Not run in the real installer window (Mint or Zorin ISO), not on real hardware, not with Zorin's own Ubiquity build (24.04.5+zorin2; its detector code was not compared), and not in Subiquity (Ubuntu's newer
  installer also reads this file, per Launchpad bug 2152901; its question wording was not checked).
- The "printed on the key caps" sets are models. Belgian caps: our own list (common Belgian AZERTY keyboards); other
  countries only as the two bounds above, not with their real caps.
- The exact answers given on 30 Oct are unknown; the walk shows every Belgian path ends French, so the outcome does not
  depend on them.
- The tree is generated at build time from xkb-data, so the fix belongs in keymapper (then a console-setup rebuild).
  Shipping our own pc105.tree on the stick would be possible but changes a system file: not done.

## Upstream (later, not now)
keymapper (Ubuntu, Launchpad project "keymapper"; maintainers of LP bug 2152901) with the diff and the 41-layout table,
plus a note to console-setup for the rebuild. Related: Launchpad 1807344 "Wrong french keyboard when installing Ubuntu"
(ubiquity, Won't Fix, 2018) ◐ not checked whether it is the same cause. Built with AI help (Claude). Not sent yet.
