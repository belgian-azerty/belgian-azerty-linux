# Fast typing: why two characters can swap (`€@` instead of `@€`)

This note explains a problem found while testing this project: when keys come very fast, two characters can arrive
in the wrong order, for example `€@` instead of `@€`. It says how this was measured, where it comes from, and what
the project does about it. The user-facing summary is in the README ("Known issues" and "Fast typing").

The measurements were made on 24 and 25 October 2026 in virtual machines (QEMU with hardware acceleration, close to
the speed of a real computer). Raw results are in `evidence/raw-logs/swaps/`; the test scripts are in `rig/`.

## In short

- **The swaps happen in software, not in the fingers.** The test sent key presses in a fixed order with exact
  timing, and a key logger inside the virtual machine recorded what the desktop received. In all 5,215 typed lines
  the keys reached the desktop in the right order. Every swap happened after that point.
- **The cause is the ibus input method.** ibus is the program that sits between the keyboard and the apps on Mint
  and Zorin; it is needed for Chinese, Japanese, Korean and similar input. With ibus switched off, or skipped for
  one app, there were no swaps at all, even in the test settings that did swap with ibus.
- **It happens on stock Mint and Zorin too.** Typing with AltGr at extreme speed swapped equally often with and
  without this project (Zorin: 12 of 240 lines both ways; Mint: none either way).
- **Ctrl+Alt was more fragile than AltGr at extreme speed.** Ctrl+Alt as AltGr only exists with this project. Before
  the keyd change described below, Ctrl+Alt swapped more often than AltGr (Zorin, 60 ms per key: 4 of 240 lines,
  against 0 of 480 with AltGr).
- **At normal fast typing there were no swaps:** 0 of 570 lines at 90 to 120 ms per key, with Ctrl+Alt and with
  AltGr, on Zorin.
- **No key was ever lost** in these tests (0 lines with a missing or extra key out of 5,215).

## How it was measured

- **Typing.** A script (`rig/swaptest.py`) sends key-down and key-up events one by one to the virtual machine, on a
  fixed timeline. A test line is AltGr (or Ctrl+Alt) held for the whole line, then 2, E, 2, E … eight times, which
  should give `@€@€@€@€@€@€@€@€`, then Enter. Speeds: 120, 90 and 60 ms from one key press to the next, and 30 ms with
  overlapping keys (the next key goes down before the last one is released, as fast typists do). Other patterns:
  pressing AltGr or Ctrl+Alt again for every key, plain letters, mixed text, and the dead key `^` followed by `e`.
- **Logging.** A key logger in the virtual machine (`rig/keylog.py`) reads the keyboard events from the kernel, the
  same events the desktop reads.
- **Scoring.** `rig/swapscore.py` sorts every typed line into right, swapped order, key missing or extra, or wrong
  characters, and checks the key log against the order that was sent.
- **Systems.** Zorin OS 18.1, installed, GNOME on Wayland, GNOME Terminal, ibus on. Linux Mint 22.3 Cinnamon live
  session, X11, GNOME Terminal, ibus on. Both with this project's packages (test build 0.9.1). A minimal GTK
  text window (`rig/typebox.py`) was used to test one app with a chosen input-method setting.

## Results

Lines with swapped characters, out of lines typed. "Overlap" means 30 ms per key with the next key down before the
last one is up.

**Zorin OS 18.1 (GNOME, Wayland), GNOME Terminal**

| What was typed | keyd on, ibus on | keyd off (stock), ibus on | keyd on, ibus off |
|---|---|---|---|
| AltGr held, overlap | 12/240 | 12/240 | 0/40 |
| AltGr held, 60 ms | 0/240 | 0/240 | 0/40 |
| AltGr held, 90 and 120 ms | 0/150 and 0/40 | 0/40 at 120 ms | |
| AltGr pressed for every key, 60 ms | 0/190 | 1/190 | |
| Ctrl+Alt held, overlap | 3/40 | (Ctrl+Alt types nothing on stock) | |
| Ctrl+Alt held, 60 ms | 4/240 | | 0/40 |
| Ctrl+Alt held, 90 and 120 ms | 0/150 and 0/190 | | |
| Ctrl+Alt pressed for every key, 60 ms | 0/190 | | |
| Plain letters (overlap) and mixed text `a@z€e{r}` (60 ms) | 0/40 and 0/40 | 0/40 and 0/40 | |
| Dead key `^` then `e`, 150 ms | 10/10 right (ê) | | |

**Zorin, a minimal GTK 4 window**

| What was typed | ibus on (default) | ibus skipped for this window | keyd off |
|---|---|---|---|
| AltGr held, overlap | 6/100 | 0/100 | 2/100 |
| Ctrl+Alt held, 60 ms | 0/100 | 0/100 | |
| Dead key `^` then `e` | right | right | |

**Linux Mint 22.3 (Cinnamon, X11)**

| What was typed | keyd on, ibus on | keyd off, ibus on | keyd on, ibus off |
|---|---|---|---|
| Terminal: AltGr held, overlap and 60 ms | 0/150 and 0/150 | 0/150 and 0/150 | 0/150 (overlap) |
| Terminal: Ctrl+Alt held, overlap | 12/150 | | 0/150 |
| Terminal: Ctrl+Alt held, 60 ms | 0/150 | | |

Results varied between test sessions (for example Zorin at 30 ms: 4 of 40 in one session, 8 of 200 in another), so
small counts are rough. Only comparisons made in the same session, as in the tables above, should be read as
comparisons.

## Where it goes wrong

- **After the kernel and after keyd, and only with ibus in the path.** The key log was always in order.
  - On GNOME Wayland, GNOME Shell passes every key to ibus as a separate request and does not wait for the answer.
    Nothing keeps the answers in order (`js/misc/inputMethod.js` in GNOME Shell 46).
  - On X11, GTK 3's ibus module also works this way by default.
- **Only an ASCII character and a non-ASCII character ever swapped** (`@` and `€`). This matches ibus issue
  [#2934](https://github.com/ibus/ibus/issues/2934) (Ubuntu 24.04, GNOME 46, fast input reorders non-ASCII
  characters, and it goes away when ibus is skipped). That issue was closed as "not planned" on 5 October 2026,
  because it did not happen on GNOME 51.
- **Why Ctrl+Alt was more fragile.** To turn Ctrl+Alt+2 into AltGr+2, keyd 2.5.0 released Ctrl and Alt, pressed
  AltGr, sent 2, released AltGr and pressed Ctrl and Alt again: about 8 key events per character, against 2 for
  AltGr. Each event is one more trip through ibus, so there is more room for one answer to overtake another. The
  event counts are measured (key logs in `evidence/raw-logs/swaps/keylogs.tgz`); the link between event count and
  swaps is our reading of the code, not proven.
- **Not the cause:** the Belgian layout, the keyd configuration, the kernel, the virtual machine. Plain letters at
  the same speeds never swapped.

## Typing tools and scripts

| Tool | Goes through keyd? | Result |
|---|---|---|
| ydotool 0.1.8 (Ubuntu 24.04's version), Zorin Wayland, 12 ms between keys | yes | Swapped often with keyd on and off (plain keys: 12 of 20 lines with keyd, 14 of 20 without). It assumes a US layout, so it cannot type correctly on a Belgian layout either way. |
| xdotool, Mint X11, 12 ms | no (it injects inside the X server) | Swapped about the same with keyd on and off (5 and 6 of 20 lines). Ctrl+Alt+2 sent by xdotool is not turned into `@`. |
| Pasting from the clipboard | no keyboard involved | Always correct. |

So for scripts that need to type text on a Belgian layout: paste it, or write it through the app's own interface.
This holds on stock Linux too.

## What the project does about it

1. **A keyd change (shipped from 0.9.4).** keyd now keeps AltGr down while Ctrl+Alt is held, instead of putting
   Ctrl+Alt back after every symbol. Ctrl+Alt typing then sends 2 events per character, like AltGr. When a key that
   is not a symbol is pressed (T, an arrow), keyd puts Ctrl+Alt back first, so shortcuts such as Ctrl+Alt+T keep
   working. The patch is
   `packaging/keyd-backport/patches/0012-Keep-AltGr-held-while-a-Ctrl-Alt-layer-is-held.patch`. See "Test of the
   keyd change" below and the README section "The keyd patch".
2. **Skipping ibus in a few apps (shipped from 0.9.6; VS Code from 0.9.7).** With the Windows profile, the Terminal, the text
   editor and VS Code skip ibus by themselves, unless an input method that needs ibus is set up. In the tests above, skipping ibus removed every swap.
   The setting is `GTK_IM_MODULE=gtk-im-context-simple`. The short form `simple` that is often quoted only works in
   GTK 4 apps; GTK 3 apps, the Terminal among them, ignore it and keep ibus. (In the Zorin GTK 4 window above, the
   short form was used, which is valid there.) Details and the measurements of the shipped version: README, "Fast
   typing".
3. **Not used:** ibus's "synchronous mode" for the whole system. It froze the Zorin desktop once in testing and does
   not help native Wayland apps.

The root problem stays in ibus and in how GNOME and GTK call it. A report to those projects, with these numbers, is
planned.

## Test of the keyd change

The change (about 30 lines in keyd 2.5.0's `src/keyboard.c`) was first built as a test version and installed on the
test machines only, on 24 October 2026. Evidence: `evidence/raw-logs/swaps/keyd-test/`.

- **It does what it should.** With Ctrl+Alt held, keyd sends AltGr down once, then only the symbol keys: 2 events
  per character instead of 8.
- **keyd's own test suite:** 80 of 86 tests passed with the test version. The 6 others expected keyd to release and
  press a modifier again between two keys, which is exactly what the change removes; the typed text is the same.
  The shipped patch updates those 6 tests, and all 86 pass.
- **Comparison.** The original keyd and the test version were run in alternating rounds (4 rounds of 50 lines each,
  30 ms with overlapping keys), so that changes in machine load affected both alike:

| Lines with swapped characters, of 200 | Ctrl+Alt, original keyd | Ctrl+Alt, with the change | AltGr (two rounds) |
|---|---|---|---|
| Mint (X11), Terminal | 88 | 8 | 11 and 9 |
| Zorin (Wayland), Terminal | 37 | 23 | 18 and 20 |

  With the change, Ctrl+Alt swaps about as often as AltGr. It does not fix the ibus problem itself: AltGr still swaps
  at this extreme speed, with or without this project. These evening rounds swapped more than the afternoon tests
  above (Mint, Ctrl+Alt, original keyd: 12 of 150 in the afternoon, 88 of 200 in the evening), which is why only the
  alternating rounds count as a comparison.
- **Shortcuts still work.** With Ctrl+Alt held: typing `@` then T opened a terminal; `@` then Right moved to the next
  workspace, and `€` then Left moved back. The key log shows keyd putting Ctrl+Alt back just before T, Right and Left.
- **One unexplained pause.** In one line out of 400 with the test version, keyd's output paused for 0.6 s (the first
  line after the test version was put in place), and the system repeated `@`. Six more restart-and-type tries showed no
  pause with either version. We could not tell whether the pause came from keyd or from the virtual machine.
- **Not covered:** pressing Ctrl+Alt again for every symbol (the change only helps while Ctrl+Alt stays held), a
  mouse click with Ctrl+Alt held right after a symbol (it would see AltGr until the next key; not tested), and real
  hardware.

## Limits of these measurements

- Virtual machines, not real computers. The keys came from an emulated keyboard of the same kind as a laptop's
  built-in one.
- Two apps per system (GNOME Terminal and a minimal GTK window). VS Code was measured later, for 0.9.7 (README).
- Keys were sent faster than people type, to make the problem visible. The counts compare settings; they do not say
  how often it happens to a person typing on a real machine.
- One test by a person on a real laptop (version 0.9.1) had one line with two pairs swapped with keyd on, and one
  irregular line with keyd off. Without a key log, those lines cannot be told apart from finger slips.
