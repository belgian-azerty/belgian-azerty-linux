# How we tested

Short version: **tested in emulators and on one laptop, for Linux Mint 22.3 and Zorin OS 18.1 only**, and checked by
a separate review before the release. Nothing has been accepted by the Linux projects themselves yet. The full
table is in the README ("What was tested where"); the technical notes are in `NOTES.md`; raw results are in `evidence/`.

## Where

- **Emulators:** QEMU virtual machines, in the cloud and on one laptop (faster, with hardware acceleration). Keys are
  sent to the virtual machine as real key presses, so the system sees a normal keyboard.
- **One real laptop:** a Lenovo ThinkPad T14s. Zorin was started from a USB stick on it (older version 0.9.1), and
  Mint and Zorin ran inside VirtualBox on its Windows 11.

## What

- Starting from the Belgian USB stick (UEFI and older BIOS mode), installing from it, and the first start after that.
- Typing: every AltGr and Ctrl+Alt symbol, Caps Lock, the numpad and dead keys (ê, ë, ñ …), mostly in the Terminal
  and the text editor; the symbols also in VS Code and a browser (Firefox on Mint, Brave on Zorin).
- Staying Belgian: login screen, desktop, reboot, log out and in, new users, reset settings, a full system update,
  suspend and resume, disk encryption (Zorin).
- Not breaking things: 176 keyboard shortcuts compared with and without the change; the keyboard keeps working when
  keyd is stopped, killed or given a broken configuration; the mouse and touchpad keep working; uninstall gives back
  the stock system.
- Very fast typing (keys sent faster than people type): how often characters swap, before and after each change.
- The packages themselves: rebuilt from source with the same result byte for byte, checked with Debian's lintian, and
  installed, upgraded and removed in a clean system.

## Not tested yet

An install from the stick on real hardware; Mint directly on real hardware; Mint on Wayland; disk encryption on
Mint; a second USB keyboard; keyboards with a built-in touchpad; the "Belgian keyboard" window on Mint; Ubuntu itself
and any other distribution; VS Code from Snap or Flatpak.

## Reviews

Before this release, three separate reviews checked the code, the packages, the documents and the test
evidence. They were done with an AI assistant, Claude, in separate sessions that had not written the code; the last
one also re-checked 0.9.6 and 0.9.7. Their findings were fixed or are listed as known issues in the README.
