# Round two: claim table

✔ = checked by us (how is in the last column), ✱ = inference, not proven. Every claim is about the versions named.

| # | Claim | Status | How checked |
|---|---|---|---|
| 1 | GNOME Shell drops a key when ibus answers it with an error (only a log line "Error processing key on IM") | ✔ | Code: `js/misc/inputMethod.js` in gnome-46 and main (7904014f5b1a, 2 Nov 2026); test: stock shell typed nothing in phase B |
| 2 | Ubuntu 24.04's gnome-shell 46.0-0ubuntu6~24.04.17 has the same inputMethod.js as upstream gnome-46 | ✔ | Extracted from libshell-14.so with `gresource`, byte compare |
| 3 | The 3-line "fail open" patch delivers every key in that error state, in order, also fast and with Shift, é, è, & | ✔ | Headless GNOME Shell 46 test, `evidence/raw-logs/2026-11-03-round-two-1-gnome-fail-open/` |
| 4 | The error class matches the Zorin login screen of 24 Oct ("object does not exist at …/InputContext_2") | ✔ | Same message in the 24 Oct journal and in our phase B |
| 5 | Two ibus daemons at the login screen produced that dead context | ✱ | Not reproduced; replacing the daemon in our test disconnected cleanly |
| 6 | cinnamon-desktop and gnome-desktop map fr_BE to "be" but have no nl_BE, de_BE, wa_BE, li_BE | ✔ | Source of cinnamon-desktop 6.6.2 and master, gnome-desktop 44.0 (Ubuntu) and master; lookup printed in the container |
| 7 | Mint 22.3 (Cinnamon 6.6.9) in nl_BE with only Belgian chosen runs the keymap "be,us"; fr_BE gives "be,be" | ✔ | Xvfb + Cinnamon in a Mint 22.3 container, `setxkbmap -query` |
| 8 | The table patch gives nl_BE "be,be"; with Cinnamon's commit b0c6e1f6 (12 Mar 2026) only "be" | ✔ | Same container, patched library built from source, JS change backported |
| 9 | GNOME 50 and later add the language layout only when it is missing | ✔ (code only) | gnome-shell gnome-50, gnome-51, main `keyboardManager.js`; not run |
| 10 | Ubuntu's pc105.tree (console-setup 1.226ubuntu1, 1.226ubuntu1.1, 1.237ubuntu3.1, 1.248ubuntu3) never reaches "be" for a Belgian keyboard | ✔ | Ubiquity's own `KeyboardDetector` (Mint 24.04.3+mint19) walked over every answer path, three models of visible signs |
| 11 | The cause is in keymapper `tree.py`: only 10 "press a key" signs are tried, then yes/no questions on AltGr-only signs such as œ | ✔ | Generator trace for {be, fr}; tree rebuilt from source behaves like the shipped one on all 41 layouts |
| 12 | `exc == SingleMapping` is always false, so every yes/no question is written as FINDP | ✔ | Code; fixed tree has FIND lines again |
| 13 | The fixed keymapper makes all 4 Belgian variants reach "be" and makes no layout worse except fr:oss → fr when only plain/Shift signs count | ✔ (model) | Fast walker equal to Ubiquity's code on the shipped tree; 41 layouts × 2 models |
| 14 | Œ is not printed on Belgian key caps | ✱ | Common Belgian AZERTY keyboards; not a survey |
| 15 | Windows defaults nl-BE to Belgian (Period) and de-BE to German QWERTZ | ✔ | Microsoft keyboard identifier table (kbdlayout.info), checked 24 Oct 2026 |
