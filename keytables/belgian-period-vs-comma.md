# Windows "Belgian (Period)" vs "Belgian (Comma)" on Linux

Measured 2026-10-23, during the Zorin install and desktop tests.

| Windows layout (Settings name) | Windows DLL / KLID | Numpad decimal key | Linux equivalent |
|---|---|---|---|
| Belgian (Period), the common one (also the one on the test laptop) | KBDBE.DLL / 00000813 (nl-BE), 0000080C (fr-BE "Belgian French") | `.` | layout `be`, no variant, no extra option |
| Belgian (Comma) | KBDBENE.DLL / 00010813 | `,` (kbdlayout.info names the key "NUM-DECIMAAL (,)") | layout `be` + XKB option `kpdl:comma` |

- The two Windows layouts differ in the numpad decimal key. The main block is the same, so the keyd Ctrl+Alt table
  (`keyd/be-winaltgr.conf`) is identical for both and needs no variant.
- Do not use `be(iso-alternate)` for "Comma": that Linux variant changes AltGr letters (AltGr+A = æ, AltGr+Q = @,
  AltGr+Z = «, ...) and leaves the numpad alone. It is a different layout, not the Windows Comma one.
- XKB facts (xkbcli compile-keymap, xkeyboard-config of Ubuntu 24.04): `be` gives `<KPDL> = [KP_Delete, KP_Decimal]`,
  `be` + `kpdl:comma` gives `[KP_Delete, KP_Separator]`. libxkbcommon maps KP_Decimal to `.` and KP_Separator to `,`.
- Laptops without a numpad (T14s) are not affected either way.

How the fix applies it: `be-azerty-fix.sh` reads `DECIMAL=period|comma` (default period). It removes any `kpdl:*`
option and adds `kpdl:comma` for comma, keeping the other options, in /etc/default/keyboard (XKBOPTIONS), the debconf
answer keyboard-configuration/optionscode (so package upgrades keep it), the running X session (setxkbmap), and the
desktop's own option list (GNOME `org.gnome.desktop.input-sources xkb-options`, Cinnamon
`org.cinnamon.desktop.input-sources xkb-options`).

    sudo DECIMAL=comma ./be-azerty-fix.sh system     # Belgian (Comma)
    sudo ./be-azerty-fix.sh system                   # Belgian (Period), the default

Test on the live Zorin 18.1 desktop (GNOME on X11, NumLock on, QEMU keys kp_1 kp_decimal kp_5):
default `1.5`, after `DECIMAL=comma ... live` `1,5`, after `DECIMAL=period ... live` `1.5` again
(evidence/raw-logs/zorin/live-desktop-numpad-period-comma.txt).
