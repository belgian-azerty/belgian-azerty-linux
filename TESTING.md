# Help test: Belgian AZERTY like on Windows, for Linux Mint 22.3 and Zorin OS 18.1

*Nederlands: [TESTING.nl.md](TESTING.nl.md) · Français : [TESTING.fr.md](TESTING.fr.md)*

Thank you for helping. This project was tested in emulators and on one laptop only, so every real computer counts.
You do not need to be an expert, and you do not need to give your name.

## Most wanted

- **A real computer** (not a virtual machine) with Linux Mint 22.3 or Zorin OS 18.1.
- **Linux Mint installed directly on a computer** (not tested at all yet).
- **A second keyboard** plugged in by USB.
- **A keyboard with a touchpad built in** (one device, such as some wireless keyboard-and-touchpad sets). Please read
  "Before you start" first: this case is a known risk.
- Zorin OS in its normal Wayland session, and VS Code if you use it.

A virtual machine (VirtualBox, GNOME Boxes) with Mint 22.3 or Zorin OS 18.1 is also useful.

## Before you start (1 minute)

- This changes keyboard settings. One command takes everything away again (step 9); the keyboard stays Belgian
  afterwards, because the Belgian layout is a standard Linux setting.
- Only on **Linux Mint 22.3** or **Zorin OS 18.1**. It was not tested on other versions or other distributions.
- **Keyboard with a built-in touchpad**: while the fix runs, smooth scrolling and touchpad gestures may stop working
  on that one device. The README ("Known issues") explains how to exclude that device. Please tell us if it happens.
- **If the keyboard ever stops while the mouse still works** (never seen in testing): restart the computer from the
  system menu with the mouse.

## Test 1: on an installed system or a virtual machine (about 20 minutes)

**1. Download.** From the [release page](https://github.com/belgian-azerty/belgian-azerty-linux/releases/latest), download these three files into your Downloads folder:
`keyd-belgian-windows_…_all.deb`, `belgian-azerty-windows_…_all.deb` and `SHA256SUMS`.

**2. Open a terminal there.** Open the Downloads folder, right-click in an empty spot, choose "Open in Terminal".

**3. Check the files.** Type:

```
sha256sum -c SHA256SUMS --ignore-missing
```

Each of the two lines must end with `OK`.

**4. Install.** Type (it asks for your password):

```
sudo add-apt-repository ppa:keyd-team/ppa
sudo apt install keyd ./keyd-belgian-windows_*.deb ./belgian-azerty-windows_*.deb
sudo be-azerty-fix system
```

The first line adds the keyd-team PPA, which provides keyd (the program behind Ctrl+Alt as AltGr) for Mint 22 and
Zorin 18. For the comma on the numpad, type `sudo DECIMAL=comma be-azerty-fix system` instead of the last line.

**5. Log out and log back in.**

**6. Type the test lines.** Open the Text Editor. For each line, write down exactly what appears.

| Line | What you do | You should see |
|---|---|---|
| A | Hold **left Ctrl + left Alt**, press `1` `2` `3` `9` `0` `E`, let go | `\|@#{}€` |
| B | Hold **AltGr**, press `1` `2` `3` `9` `0` `E`, let go | `\|@#{}€` |
| C | Press **Caps Lock** once. Type the letters `A` `Z` `E`, then the top-row keys `1` `2` `3`. Press **Caps Lock** again | Mint: `AZE123` · Zorin: `AZE&É"` (on Zorin the Windows Caps Lock is off unless you switch it on) |
| D | Num Lock on, press the numpad's decimal key | `.` (or `,` if you chose the comma) |
| E | Press **Ctrl+Alt+T** | a terminal opens |

**7. Restart the computer.** At the login screen type your password as usual. After logging in, type line A again.

**8. Collect the details.** In a terminal, type:

```
be-azerty-fix check 2>&1 | sed "s/\b$USER\b/USER/g" > ~/belgian-check.txt
echo "$XDG_SESSION_TYPE" >> ~/belgian-check.txt
```

This makes the file `belgian-check.txt` in your home folder, with your user name already replaced by `USER` (it
appears in a few lines and in folder paths). **Open it and look it over before you share it**: if your user name is
still in it somewhere, replace it with `USER`. Nothing else in it is personal.

**9. Remove it (or keep it).** If you want it gone:

```
sudo be-azerty-fix uninstall
```

Then log out and back in. Line B (AltGr) should still give `|@#{}€`: that is standard Linux.

**Optional extras** (only if you have them):
- Second USB keyboard: plug it in and type line A on it.
- Fast typing: in the Terminal, hold left Ctrl + left Alt and press `2` `E` `2` `E` … eight times as fast as you
  normally type. Expected `@€@€@€@€@€@€@€@€`. Write down any swapped pair.
- VS Code: type line A in an empty file.
- Zorin, Windows Caps Lock: read "Caps Lock on Zorin" in the README, then `sudo CAPS=windows be-azerty-fix system`,
  log out and in, and type line C (expected `AZE123`).

## Test 2: live USB on a real computer (for people who already use Linux)

There is no ready-made image. You build the stick on a Linux computer from the official ISO you downloaded yourself,
with one command (README, "Live USB"). Start the computer from the stick, choose your language and "Belgian" in the
boot menu, and do lines A to E of Test 1 in the live session (nothing is written to the computer's disk). Then step 8.
**Do not click "Install"** unless you do Test 3.

## Test 3: install from the stick (only on a computer whose disk may be erased)

Installing erases the disk you choose. Only on a spare computer or an empty disk, never on a computer with files you
need. Install from the stick with the Belgian keyboard; the first start after the install takes longer (it finishes
the setup once; let it run). Then lines A to E, step 7 and step 8.

## Send the result

Pick one, whichever is easiest:

- **With a GitHub account:** [open a test report](https://github.com/belgian-azerty/belgian-azerty-linux/issues/new?template=test-report.yml) (a form with the same steps).
- **Without an account:** [the anonymous test form](https://cryptpad.fr/form/#/2/form/view/5pyp77A2OWeYL8oIgyPDl7DLfyyXh3St+p2L3pdFXdo/) (no account, no name, no e-mail needed).
- **By e-mail:** linuxbelgiumkeyboard.rc0g4@aleeas.com, with the lines you saw and `belgian-check.txt`.

Please include: Mint or Zorin, installed / virtual machine / live USB, what you saw for lines A to E, anything strange.
The computer model and keyboard model help but are optional. Do not send your name, e-mail address or user name
unless you want a reply by e-mail.

**No time to test?** The 2-minute survey also helps: [English](https://cryptpad.fr/form/#/2/form/view/A9o2MXPQHcgJr0e6Y0eG3Qy0fjz13WeJ1IHy-JGxTy0/) · [Nederlands](https://cryptpad.fr/form/#/2/form/view/mLakgWAFAMsQhn1VkX+rnDxlHPSzbZiloRZxeS6IYlQ/) · [Français](https://cryptpad.fr/form/#/2/form/view/Vs07SGZoahOJOklE8G6wDZaC4Kjdl9mKyBwYAshSCQA/).

Thank you!
