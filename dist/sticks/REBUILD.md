# Build a Belgian live USB (0.9.7) from the official ISO, and check it

Ready-made stick images are not published. You build one yourself from the official Linux Mint or Zorin OS ISO
you downloaded, with the three 0.9.7 packages in `dist/` and the tool in `tools/`. The result is the stock ISO plus
Belgian boot-menu entries and one extra file with our packages; everything else stays as the distribution made it.
This is an unofficial community build, not made by or affiliated with Linux Mint or Zorin OS.

## What you need

| Input | sha256 (check before you build) |
|---|---|
| Zorin OS 18.1 Core 64-bit, from zorin.com | `44649b97bd307fc4c8529205d098ebbf98575a1e1ba2ee7d7005b697af1721d5` |
| Linux Mint 22.3 Cinnamon 64-bit, from linuxmint.com (matches Mint's own sha256sum.txt) | `a081ab202cfda17f6924128dbd2de8b63518ac0531bcfe3f1a1b88097c459bd4` |
| `dist/belgian-azerty-windows_0.9.7_all.deb` | `78e124dc977b65a56b0bfb7c13c4a4b17c99d345f48fda6cbb8af2ff679c92e2` |
| `dist/keyd-belgian-windows_0.9.7_all.deb` | `33a1a250837efec4be5014fcc3f1a54523ffb75c5ebd22d4dd3e15d77d6cea30` |
| `dist/keyd_2.5.0-5~ubuntu24.04.3_amd64.deb` | `cc58478fe358cf3fec7e673b84cd20b9e3768297a1fe1183054261bcb7d06bb4` |
| `tools/make_belgian_iso.sh`, `tools/belgian_boot_menu.py`, `tools/stick/*` | listed in `dist/sticks/TOOLS-SHA256SUMS` |

A computer (or virtual machine) with Ubuntu 24.04 or a system based on it, as root, with `xorriso` and
`squashfs-tools` installed, and a kernel that can mount zstd-compressed squashfs (a normal Ubuntu kernel can).

## Build

Run from a folder on a local disk, with absolute paths:

```
B=/path/to/this/repository
sudo MENU=b PACKAGES=$B/dist bash $B/tools/make_belgian_iso.sh Zorin-OS-18.1-Core-64-bit.iso zorin-belgian-stick-0.9.7.iso
sudo MENU=b PACKAGES=$B/dist bash $B/tools/make_belgian_iso.sh linuxmint-22.3-cinnamon-64bit.iso mint-belgian-stick-0.9.7.iso
```

The tool ends with its own check ("every boot menu and added file matches /md5sum.txt"). Write the image to a USB
stick with any tool that writes ISO images (Rufus in ISO mode was used in our tests).

On Windows Subsystem for Linux (WSL) the kernel cannot mount zstd squashfs, so the build stops at that step; build on
a normal Ubuntu system or in a virtual machine instead.

## Check that your build matches ours

The image file is not byte-for-byte reproducible (the ISO and squashfs formats record the build time), so its sha256
differs from ours (`dist/STICKS-SHA256SUMS`). Its content must not:

```
sudo bash $B/tools/stick-fingerprint.sh zorin-belgian-stick-0.9.7.iso | diff $B/dist/sticks/CONTENT-zorin-0.9.7.txt - && echo CONTENT-IDENTICAL
sudo bash $B/tools/stick-fingerprint.sh mint-belgian-stick-0.9.7.iso  | diff $B/dist/sticks/CONTENT-mint-0.9.7.txt - && echo CONTENT-IDENTICAL
```

The fingerprint lists sha256 sums of the boot menus, of `md5sum.txt` without the line of our layer, of everything in
`/belgian/` (the packages for the installer), and of our files inside `/casper/zz-belgian-azerty.squashfs` (our
packages unpacked). Everything else on the image is the stock ISO, which casper's own disc check verifies against
`md5sum.txt` when the stick starts.

## Files next to this one

`CONTENT-zorin-0.9.7.txt` and `CONTENT-mint-0.9.7.txt` (the fingerprints), `BOOT-MENUS-0.9.7.txt` (the boot-menu
entries as text), `BELGIAN-DIR-0.9.7.txt` (listing of `/belgian/`), `TOOLS-SHA256SUMS`, `SHA256SUMS`.
