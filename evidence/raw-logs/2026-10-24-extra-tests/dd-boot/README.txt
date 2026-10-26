Boot menus of the Zorin Belgian stick (zorin-belgian-stick.iso, sha256 3132aba5...9b73), 2026-10-25, laptop KVM rig.
No dd write happened on the laptop (its hook blocks dd): the ISO itself was the read-only backing file of a 16 GB qcow2
overlay attached as a QEMU USB stick. See ../zorin/README.txt.
uefi-boot-menu.png   UEFI (OVMF) GRUB menu, untouched: Nederlands / Français / Deutsch / English submenus + countdown
bios-boot-menu.png   legacy BIOS isolinux menu, same entries, "Automatic boot in 5 seconds"
bios-md5-check.png   the BIOS boot then ran casper's disc check (all files passed, then the desktop)
zu-boot-N.png        UEFI boot, one screenshot every 1.5 s (menu at 3-8)
zb-boot-N.png        BIOS boot, one screenshot every 1.5 s (menu at 2-6)
