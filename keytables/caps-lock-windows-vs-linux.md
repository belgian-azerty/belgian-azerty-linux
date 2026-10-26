# Caps Lock: Windows Belgian vs Linux `be`

Source for Windows: kbdlayout.info XML exports of KBDBE.DLL ("Belgian (Period)", windows-kbdbe-belgian-period.xml)
and KBDBENE.DLL ("Belgian (Comma)", windows-kbdbene-belgian-comma.xml), entries `With="VK_CAPITAL"` and
`With="VK_SHIFT VK_CAPITAL"`. Both DLLs are identical here. Linux: xkeyboard-config 2.41 (Ubuntu 24.04, Mint 22,
Zorin 18) symbols/be, measured in keytables/be-stock.txt.

| Key (scancode) | plain | Shift | Windows Caps | Windows Caps+Shift | Linux `be` Caps |
|---|---|---|---|---|---|
| 1 (02) .. 0 (0B) | & é " ' ( § è ! ç à | 1 2 3 4 5 6 7 8 9 0 | 1 2 3 4 5 6 7 8 9 0 | & é " ' ( § è ! ç à | & É " ' ( § È ! Ç À |
| ) (0C) | ) | ° | ° | ) | ) |
| - (0D) | - | _ | _ | - | - |
| ^ (1A, dead) | ^ | ¨ | ¨ | ^ | ^ |
| $ (1B) | $ | * | * | $ | $ |
| ù (28) | ù | % | % | ù | Ù |
| µ (2B) | µ | £ | £ | µ | µ (keysym mu has no capital in XKB) |
| , (32) ; (33) : (34) = (35) | , ; : = | ? . / + | ? . / + | , ; : = | , ; : = |
| letters | a | A | A | a | A (Caps+Shift: a) |
| ² (29), < (56), space, numpad | | | not affected | not affected | not affected |

So on Windows, Caps Lock is a "shift lock" for every printable key of the main block except ² and <, and Shift
cancels it. AltGr / Ctrl+Alt symbols are not affected by Caps Lock on Windows (no `VK_CAPITAL VK_CONTROL VK_MENU`
entries). Consequence: with Caps Lock on, Windows cannot type É È Ç À Ù with the accent keys (it types 2 7 9 0 %).

XKB implementation prototype: xkb/symbols/be_capslock ("windows") sets key type FOUR_LEVEL_SEMIALPHABETIC on those
20 keys (Lock -> level 2, Shift+Lock -> level 1, Lock+AltGr -> level 3). Same mechanism as upstream
xkeyboard-config's `caps:digits_row` (added in 2.42, June 2024; digits only, so it does not cover ) - ^ $ ù µ , ; : =).
Verified with libxkbcommon (`xkbcli how-to-type`, extra rules in $XDG_CONFIG_HOME/xkb): with option
caps:be_windows, `2` = Shift or Lock on AE02, `é` = none or Shift+Lock, `%` = Shift or Lock on AC11, `@` = AltGr or
Lock+AltGr, `²` unchanged.
