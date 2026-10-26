# Ctrl+Alt on a Belgian keyboard: Windows vs Linux Mint stock vs with the keyd fix

Physical key = the legend printed on a US keyboard at that position (how QEMU names it). Belgian columns from
xkeyboard-config 2.41 `be` through libxkbcommon (tools/keytable.py). Windows column from KBDBE.DLL, where
Ctrl+Alt and AltGr are the same thing. 'Mint stock' and 'with fix' columns are what was MEASURED in xed on the real
Linux Mint 22.3 live session (evidence/real-mint-12-xed-keyd-on-vs-off-same-window.png, raw-logs/typed-*.txt).
'(shortcut)' = no character, the key combination is passed to the application/desktop as a Ctrl+Alt shortcut.

| Physical key | Belgian plain | Shift | AltGr (Linux be) | Ctrl+Alt on Windows | Ctrl+Alt Mint stock (GTK) | Ctrl+Alt with keyd fix | AltGr with keyd fix |
|---|---|---|---|---|---|---|---|
| ` | ² | ³ | ¬ | (nothing) | (nothing) | (shortcut) | ¬ |
| 1 | & | 1 | \| | \| | (nothing) | \| | \| |
| 2 | é | 2 | @ | @ | (nothing) | @ | @ |
| 3 | " | 3 | # | # | (nothing) | # | # |
| 4 | ' | 4 | ¼ | { | (nothing) | { | { |
| 5 | ( | 5 | ½ | [ | (nothing) | [ | [ |
| 6 | § | 6 | ^ | ^ | (nothing) | ^ | ^ |
| 7 | è | 7 | { | (nothing) | (nothing) | (shortcut) | { |
| 8 | ! | 8 | [ | (nothing) | (nothing) | (shortcut) | [ |
| 9 | ç | 9 | { | { | (nothing) | { | { |
| 0 | à | 0 | } | } | (nothing) | } | } |
| - | ) | ° | \ | (nothing) | (nothing) | (shortcut) | \ |
| = | - | _ | <dead_cedilla> | (nothing) | (nothing) | (shortcut) | <dead_cedilla> |
| q | a | A | @ | (nothing) | (nothing) | (shortcut) | @ |
| w | z | Z | ſ | (nothing) | (nothing) | (shortcut) | ſ |
| e | e | E | € | € | (nothing) | € | € |
| r | r | R | ¶ | (nothing) | (nothing) | (shortcut) | ¶ |
| t | t | T | ŧ | (nothing) | (nothing) | (shortcut) | ŧ |
| y | y | Y | ← | (nothing) | (nothing) | (shortcut) | ← |
| u | u | U | ↓ | (nothing) | (nothing) | (shortcut) | ↓ |
| i | i | I | → | (nothing) | (nothing) | (shortcut) | → |
| o | o | O | œ | (nothing) | (nothing) | (shortcut) | œ |
| p | p | P | þ | (nothing) | (nothing) | (shortcut) | þ |
| [ | ^(dead) | ¨(dead) | [ | [ | (nothing) | [ | [ |
| ] | $ | * | ] | ] | (nothing) | ] | ] |
| a | q | Q | æ | (nothing) | (nothing) | (shortcut) | æ |
| s | s | S | ß | (nothing) | (nothing) | (shortcut) | ß |
| d | d | D | ð | (nothing) | (nothing) | (shortcut) | ð |
| f | f | F | đ | (nothing) | (nothing) | (shortcut) | đ |
| g | g | G | ŋ | (nothing) | (nothing) | (shortcut) | ŋ |
| h | h | H | ħ | (nothing) | (nothing) | (shortcut) | ħ |
| j | j | J | <dead_hook> | (nothing) | (nothing) | (shortcut) | <dead_hook> |
| k | k | K | ĸ | (nothing) | (nothing) | (shortcut) | ĸ |
| l | l | L | ł | (nothing) | (nothing) | (shortcut) | ł |
| ; | m | M | ´(dead) | (nothing) | (nothing) | (shortcut) | ´(dead) |
| ' | ù | % | ´(dead) | dead ´ | (nothing) | dead ´ | dead ´ |
| \ | µ | £ | `(dead) | dead ` | (nothing) | dead ` | dead ` |
| < | < | > | \ | \ | (nothing) | \ | \ |
| z | w | W | « | (nothing) | (nothing) | (shortcut) | « |
| x | x | X | » | (nothing) | (nothing) | (shortcut) | » |
| c | c | C | ¢ | (nothing) | (nothing) | (shortcut) | ¢ |
| v | v | V | „ | (nothing) | (nothing) | (shortcut) | „ |
| b | b | B | “ | (nothing) | (nothing) | (shortcut) | “ |
| n | n | N | ” | (nothing) | (nothing) | (shortcut) | ” |
| m | , | ? | <dead_cedilla> | (nothing) | (nothing) | (shortcut) | <dead_cedilla> |
| , | ; | . | • | (nothing) | (nothing) | (shortcut) | • |
| . | : | / | · | (nothing) | (nothing) | (shortcut) | · |
| / | = | + | ~(dead) | dead ~ | (nothing) | dead ~ | dead ~ |
|   |   |   |   | (nothing) | (nothing) | (shortcut) |   |

Caps Lock: measured identical results for the Ctrl+Alt column with Caps Lock on (letters are upper-cased, symbols unchanged).
Shift+Ctrl+Alt with the fix = Shift+AltGr (level 4 of the Belgian layout: 1 ¡, 2 ⅛, 3 £, 4 ±, 5 ˚, 6 ⅝, 9 ±, 0 °, e ¢).
Right Ctrl + Left Alt behaves like Left Ctrl + Left Alt with the fix. Ctrl+Alt on keys not in the Windows table stays a shortcut (Ctrl+Alt+T, Ctrl+Alt+Del, Ctrl+Alt+F1...).
