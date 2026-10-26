# Draft: keyd upstream proposal "keep the sent modifiers while the layer is held"

**Status: draft proposal to keyd, not sent yet.** The project offers it upstream after its first release; the
patch itself ships in this project's keyd package (`packaging/keyd-backport/patches/0012-*`).

## Proposed text (GitHub issue, with the patch attached or as a pull request)

> **Title:** Keep the modifiers of a remapped key down while its layer is still held (fewer events, avoids reordering with IBus)
>
> **What happens now.** With a layer such as
>
> ```
> [control+alt]
> 2 = G-2
> e = G-e
> ```
>
> (Ctrl+Alt+2 types `@` on a Belgian layout, as on Windows), holding Ctrl+Alt and pressing 2, E, 2, E makes keyd
> release Ctrl and Alt, press AltGr, send the key, release AltGr and press Ctrl and Alt again, for every key: about
> 8 key events per character, most of them in the same millisecond. The cause is `update_mods(kbd, -1, 0)` on the
> release of an `OP_KEYSEQUENCE` key in `src/keyboard.c`.
>
> **Why it matters.** On Ubuntu 24.04 based desktops (GNOME 46 Wayland, and GTK 3 apps on X11 with
> `GTK_IM_MODULE=ibus`), IBus can reorder fast key events, so `@€` arrives as `€@` (see ibus/ibus#2934). Each extra
> modifier event is one more chance for that. We measured it in QEMU/KVM with keys injected at exact times and the
> kernel events logged in the guest (the kernel always received the keys in order):
>
> | 30 ms between keys, overlapping, 200 lines of `@€` x8 | keyd 2.5.0 | with the change below | AltGr itself, for comparison |
> |---|---|---|---|
> | Linux Mint 22.3 (Cinnamon, X11), gnome-terminal | 88 lines with a swap | 8 | 11 and 9 |
> | Zorin OS 18.1 (GNOME 46, Wayland), gnome-terminal | 37 | 23 | 18 and 20 |
>
> Original and changed keyd ran in alternating rounds (4 x 50 lines each) so that load affected both alike. With the
> original keyd we saw no swaps at 90 to 120 ms between keys (0 of 570 lines, Zorin); that speed was not measured
> separately with the change. All numbers are from emulators on one machine, not real hardware. The underlying
> reordering is IBus's; this change only stops keyd from adding to it.
>
> **The change.** On release, skip restoring the layer's own modifiers while every layer that produced the key is
> still held. The next key press calls `update_mods()` anyway, and so does the layer's release, so the right
> modifiers are always in place before anything else is sent. Ctrl+Alt+2 E 2 E then reaches the desktop like
> AltGr held + 2 E 2 E (2 events per character).
>
> Checked with the change (keyd 2.5.0): Ctrl+Alt+T and Ctrl+Alt+Left/Right still worked right after typing a symbol
> with Ctrl+Alt held, because keyd puts Ctrl+Alt back down on that key's press (key log shows it). `make test-io`:
> 80 of 86 pass unchanged; six (`composite`, `swap`, `swap2`, `swap3`, `swap4`, `swap8`) expected the old pattern. In
> the five swap tests Shift is no longer released and pressed again between two shifted keys; in `composite` Alt is now
> released before Ctrl when the layer ends. The characters produced are the same. With those six expectations updated,
> 86 of 86 pass.
>
> **Known side effect (not tested):** a mouse click made with Ctrl+Alt held right after a symbol sees AltGr instead
> of Ctrl+Alt until the next key press. If that matters, the change could sit behind a global option, for example
> `[global] hold_sequence_mods = 1` (name open), default off.
>
> Patch against 2.5.0 attached (about 30 lines in `src/keyboard.c` plus the six test files). Happy to rebase it on
> master and add the option if you prefer that form.

## Claim check

✔ checked fact, ◐ from a source, ✱ inference. The evidence paths are relative to this repository.

| # | Claim (as worded) | Evidence (file or URL) | How checked, checked on | Verdict |
|---|---|---|---|---|
| 1 | keyd releases Ctrl+Alt, presses AltGr, sends the key, then restores Ctrl+Alt for every key (about 8 events per character) | keyd 2.5.0 `src/keyboard.c` `OP_KEYSEQUENCE` (`update_mods` on press, `update_mods(kbd, -1, 0)` on release); key logs `evidence/raw-logs/swaps/keylogs.tgz` (`*-ca*` files) | Code read 2026-10-25; key logs recorded during the fast-typing tests, 2026-10-24 | ✔ code; ✔ logs |
| 2 | Master still does this | raw.githubusercontent.com/rvaiya/keyd/master/src/keyboard.c, line 544 | Fetched 2026-10-24 23:48Z | ✔ on that date; re-check before posting |
| 3 | IBus can reorder fast key events on these desktops | ibus/ibus#2934 (closed "not planned" 2026-10-05, did not reproduce on GNOME 51); our measurements: IBus off, or IBus skipped in a GTK 4 window (`GTK_IM_MODULE=simple`; GTK 3 needs `gtk-im-context-simple`) = 0 swaps | `research/FAST-TYPING-SWAPS.md` | ◐ sourced (issue) + ✔ our data for Mint 22.3 and Zorin 18.1 only |
| 4 | Mint 88 -> 8, Zorin 37 -> 23, AltGr 11/9 and 18/20 | `research/FAST-TYPING-SWAPS.md` "Test of the keyd change"; raw files `evidence/raw-logs/swaps/keyd-test/` | Fast-typing tests, emulator on the test laptop, 2026-10-24 evening | ✔ fact (emulator, one machine) |
| 5 | (v1 wording) No swaps at 90 to 120 ms with either version — **reworded 2026-10-25** to "with the original keyd … 0 of 570 lines, Zorin; not measured separately with the change" | FAST-TYPING-SWAPS.md: 0/570 lines at 90-120 ms on Zorin | That run used the ORIGINAL keyd. **With the change, 90-120 ms was not measured separately.** | ✔ as reworded (✘ in v1) |
| 6 | Shortcuts still work right after a symbol | `evidence/raw-logs/swaps/keyd-test/sc-zp1.txt` (Zorin, test build); 0.9.4 laptop test `evidence/raw-logs/2026-10-25-keyd-patch/` | Swap test: Zorin (Wayland). 0.9.4 test 2026-10-25: Mint and Zorin live (both X11), Ctrl+Alt+T and Right/Left after an @ with Ctrl+Alt held | ✔ both (emulator) |
| 7 | 80/86 before, 86/86 with the six expectations updated; same characters | `evidence/raw-logs/2026-10-25-keyd-patch/cloud-keyd-test-io-0.9.4.txt`; the six diffs are in `packaging/keyd-backport/patches/0012-*.patch` | Run 2026-10-24 23:45Z in the cloud | ✔ fact |
| 7b | Held Ctrl+Alt gives 2 events per character and correct text | 0.9.4 test: 10/10 lines on Mint and Zorin at 120 ms, key log 2.00 events/char (`evidence/raw-logs/2026-10-25-keyd-patch/`) | Emulator on the test laptop, 2026-10-25 | ✔ fact (emulator) |
| 8 | Mouse click side effect | Inference from the code (modifiers stay at AltGr until the next key press or layer change) | Not tested | ✱ inference, stated as untested |
