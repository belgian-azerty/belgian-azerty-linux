# T14s live run, 2026-10-24: line-by-line reading

The source is `belgian-t14s-results.txt`, saved here unchanged (sha256 992c28f6…ea406, same as Younes's upload). Younes ran the test on a
ThinkPad T14s Gen 2i from the live Belgian Zorin 18.1 stick, with the test folder on a second stick. The stick's `run-test.sh` was the version
with the old block-A wording ("then 2 and E"). It was read in the guide thread "Guide the T14s typing test".

## The 8 anomalies

| # | Block | Typed | Reading |
|---|-------|-------|---------|
| 1 | xorg A, 1st try | `@@@@@@@@2E` ×5 | Wording misread: 2 was pressed 8 times with Ctrl+Alt held, then "2E" was typed afterwards. All 40 Ctrl+Alt+2 presses gave @. Not a fault. |
| 2 | xorg A, 2nd try (after Ctrl+C) | `@€`×10 on all 5 lines | Too many pairs (10 instead of 8). The lines alternate perfectly: no swap, nothing lost. Counting, not a fault. |
| 3+4 | xorg A, 3rd try | `@€`×7 on all 5 lines; line 2 `@#@€…` | 7 pairs on every line (counting). `#` is Ctrl+Alt+3 (3 hit instead of E). Typing slips. |
| 5 | xorg VS Code | `@€`×8 + `@` | One extra 2 at the end of the line. Slip. NOT VS Code taking Ctrl+Alt+E (no € is missing). |
| 6 | wayland B (keyd on, AltGr) | `@€@€@€@€@€€@@€€@` | 8 @ and 8 €, but pairs 6 and 8 are reversed (`€@`). That is the key sequence 2E2E2E2E2EE22EE2, so two reversals in one line. |
| 7 | wayland C (keyd OFF, AltGr, stock) | `@€@€€@€@€@€@€@€€` | 7 @ and 9 € (sequence 2E2EE2E2E2E2E2EE): one 2 missing or turned into €. Irregular on stock Linux, without our fix. |
| 8 | wayland VS Code | 4 lines, all `@€`×8 | Only 4 lines typed. All right. |

## What this does and does not show

- Every block ran on real hardware with 0 "input lagging" journal messages and 0 keyd warnings. The layout check passed 4 times (Caps like Windows). keyd survived the switch to Wayland.
- Clean blocks: xorg B, C and D 5/5; wayland A and D 5/5; wayland VS Code 4/4; xorg VS Code 4/5 (the 5th line is the slip in #5).
- **Rows 6 and 7 cannot tell a finger slip from a software reordering.** The typed text alone does not show whether the physical
  key events arrived in this order. In the emulator the keys are sent in a fixed order, so a swap there is certainly software. On real hardware it is not.
  One irregular line came with keyd on (B) and one with keyd off (C). That is too few lines to compare.
- Proposed (needs Younes's go; Younes made fast-typing swaps a top priority on 2026-10-24 15:16Z): repeat B and C on real
  hardware with many more lines, while logging the physical key events (`libinput debug-events` or `evtest` on the
  "AT Translated Set 2 keyboard") next to the output. Then each wrong line can be classed as finger order or software swap.

## Side notes

- Clock: the Xorg part is stamped 16:25–16:58Z and the Wayland part 15:05Z. The live session started with the clock 2 h ahead, which fits
  Windows keeping the hardware clock in local time (CEST). The clock was corrected once Wi-Fi came up for VS Code. This is the classic dual-boot clock problem and
  relevant to installed dual-boot systems; it is not a keyboard issue.
- Ctrl+C during a block resumes cleanly at the stage start (layout check + block A again), so all three A tries are in the file.
- Keyboards seen: "AT Translated Set 2 keyboard" (internal) + "keyd virtual keyboard"; no external keyboard.
