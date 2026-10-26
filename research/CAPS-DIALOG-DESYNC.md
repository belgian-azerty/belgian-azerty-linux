# Caps Lock out of step after a GNOME password field

This note explains why, on Zorin OS, the Windows-style Caps Lock of this project is something you switch on
yourself instead of being on by default. The user-facing summary is in the README ("Caps Lock on Zorin" and
"Known issues").

The investigation ran on 24 and 25 October 2026 in virtual machines. Evidence:
`evidence/raw-logs/2026-10-25-caps-dialog/` and `evidence/raw-logs/2026-10-24-extra-tests/zorin/caps-desync-*.txt`.

## In short

On GNOME's Wayland session (Zorin's normal session), a **short** Caps Lock tap inside a GNOME password field puts
two parts of the system out of step: GNOME itself and the apps no longer agree whether Caps Lock is on. Password
fields of this kind are the lock screen, the Software Updater password dialog, and any app that asks for your
password through the system (this project's "Belgian keyboard" window included). The disagreement lasts until you
log out and back in.

- **On stock Zorin** this shows as letters in the wrong case. It is a known GNOME problem
  ([mutter issue 3441](https://gitlab.gnome.org/GNOME/mutter/-/issues/3441), open since April 2024).
- **With the Windows-style Caps Lock**, the number-row keys depend on Caps Lock, and each has one plain ASCII
  character and one accented character (2 and é, 7 and è, 0 and à, % and ù). When the two parts disagree, the
  accented character wins with and without Shift, so `2 6 7 9 0 %` can no longer be typed on the main keys until the
  next login.
- **The project's response (from 0.9.6):** on Zorin the Windows profile keeps the Linux Caps Lock by default.
  `sudo CAPS=windows be-azerty-fix system` switches the Windows Caps Lock on for those who want it, knowing this
  risk. Mint, whose normal session is X11, keeps the Windows Caps Lock by default; the problem was never seen on X11.

## What was measured

**Virtual machine in the cloud.** Stock Zorin OS 18.1 Core, live session switched to GNOME on Wayland, this project's
packages (0.9.4.1) installed with the Windows Caps Lock, keyd stopped for every row (so keyd plays no part). Keys
were sent as real key presses. Each probe typed a, 2, 7, 0, ù, each plain and then with Shift, into GNOME Terminal.

The correct rows are `aA é2 è7 à0 ù%` with Caps Lock off and `Aa 2é 7è 0à %ù` with Caps Lock on.

| Step | Caps Lock light | Row typed | Reading |
|---|---|---|---|
| Caps Lock on, then off, in the terminal | on, then off | `Aa 2é 7è 0à %ù`, then `aA é2 è7 à0 ù%` | correct |
| Password dialog, one Caps Lock tap of 100 ms, dialog closed | on | `aA éé èè àà ùù` | **out of step**: letters as if Caps Lock were off, digits and % lost |
| Then one Caps Lock tap in the terminal | off | `Aa éé èè àà ùù` | still out of step, the other way round |
| Password dialog again, one 100 ms tap | on | `Aa 2é 7è 0à %ù` | back in step |
| Password dialog, Caps Lock **held for 2.5 s** | off | `aA é2 è7 à0 ù%` | stays in step |
| Taps of 50, 100 and 300 ms; holds of 1 and 2 s | | taps change the agreement, holds do not | |
| Log out and log in, from the out-of-step state | off | `aA é2 è7 à0 ù%`, Caps Lock correct again | **repaired** |
| Lock screen: Caps Lock was on, the screen warned about it, one tap to switch it off, password, unlock | off | out of step | the everyday path triggers it too |

**Virtual machine on a laptop (installed Zorin 18.1, Wayland).** Out of step 6 times out of 6 on Wayland, 0 out of 5
on X11. Stock Zorin, without this project, gets out of step too, but only as letters in the wrong case. In the
out-of-step state, GNOME's own text fields (the Activities search) typed correctly, while the apps did not.
`ibus restart` did not repair it; logging out and in did.

**After the change (0.9.6, installed Zorin on Wayland, laptop virtual machine).** With the default Linux Caps Lock,
after a Caps Lock tap in a password dialog and on the lock screen, every digit and `%` could still be typed
(evidence in `evidence/raw-logs/2026-10-25-release-0.9.6-laptop/`). Only the stock letter-case problem remains.

## Why it happens

There are two keyboard states in a GNOME Wayland session (mutter 46 source code):

- **GNOME's own state.** It is updated by every key from the hardware, drives the Caps Lock light, and decides the
  key that GNOME's own fields and the ibus input method see.
- **The state sent to apps.** Mutter keeps a second copy, updated from the key events that pass a certain point in
  its code, and sends it to the apps, which compute characters from it.

How a short tap is counted twice (our reading of the code, supported by the hold-time measurements; not proven):

1. While a GNOME password field has the keyboard, a Caps Lock press passes that point once, so the apps' state counts
   it.
2. The password field also hands the key to ibus. When ibus answers "not handled", mutter sends a copy of the event
   back through the same point.
3. Mutter ignores the copy of a key that is still held down. But if the copy of the press arrives **after** the real
   key was released, it counts as a new press, and Caps Lock toggles a second time, in the apps' state only.

This fits what was measured: short taps (50 to 300 ms) put the states out of step, long holds (1 to 2.5 s, where the
copy arrives while the key is still held) do not, and every further short tap in a password field flips the
agreement again.

**Why the digits are lost with the Windows Caps Lock** (read in the source code of ibus 1.5.29 and GNOME Shell 46).
GNOME Shell always uses ibus's basic keyboard engine. That engine types every character above U+007F (é, è, à, ù)
itself, based on GNOME's state, and hands every ASCII character (2, 7, 0, %) back to the app, which computes it from
its own state. For a number-row key with the Windows Caps Lock, the two states point at different levels: if GNOME's
level is é, ibus types é; if GNOME's level is 2, the app types its own level, which is é. So é either way. Keys whose
two characters are both ASCII (1 3 4 5 8 & " ' ( !) and the letters follow the apps' state only: they stay typeable,
just inverted. On stock Linux the digits survive, because Caps Lock does not change the number row there.

## Repairing it without a reboot

- **Log out and back in:** repairs it.
- **Another short Caps Lock tap in a password field** (for example on the lock screen) flips it back, but that is
  hard to explain, so it is not the documented recovery.
- `ibus restart` does not help.

## Why the keyboard layout itself cannot avoid it

Any Caps Lock-dependent key whose two characters are one ASCII and one non-ASCII character gives the non-ASCII one as
soon as the two states disagree. That is exactly the Windows Caps Lock on the Belgian number row and on the ù/% key.
Another kind of lock would be counted twice the same way. The one form that would survive is a lock that only
locks (Caps Lock switches on, Shift switches off, like a typewriter), but that is not how Windows behaves by
default. It was not built or tested.

## An experiment that did not finish

To prove the double count, mutter was rebuilt with one change: the copy of a key event that ibus hands back is not
counted again while a GNOME password field has the keyboard. Zorin's own mutter source was not available, so
Ubuntu's mutter 46.2 source was used. Ubuntu's libraries did not run under Zorin's GNOME Shell (a missing symbol,
then a crashed session), so the test could not be completed. The mechanism above therefore stays our reading of the
code. A test in a plain Ubuntu 24.04 virtual machine, with matching libraries, would settle it. Files:
`evidence/raw-logs/2026-10-25-caps-dialog/mutter-experiment/`.

## Not tested

- Real hardware. A real key tap lasts about 50 to 150 ms, inside the range that went out of step in both virtual
  machines.
- Other GNOME password fields (Wi-Fi password, online accounts, unlocking a disk in Files). They use the same code
  path but were not tried.
- Newer GNOME versions (mutter 47 and later). The same two code paths still exist in mutter's main branch, and issue
  3441 is still open, but it was not run.

A comment for the GNOME issue, with the mechanism and the hold-time numbers, is planned.
