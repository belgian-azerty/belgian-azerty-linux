#!/bin/bash
# Repack an Ubuntu-based live ISO (Mint, Zorin, Ubuntu flavours) so every boot
# menu entry (UEFI GRUB and legacy-BIOS isolinux) starts the live session with
# a Belgian keyboard.
#   make_belgian_iso.sh IN.iso OUT.iso ["kernel params"]
# Default params: keyboard-configuration/layoutcode=be locale=fr_BE.UTF-8
#   (Dutch-speaking:  make_belgian_iso.sh IN OUT "keyboard-configuration/layoutcode=be locale=nl_BE.UTF-8")
#
# Zorin (and Ubuntu 24.04 Ubiquity ISOs) boot with `maybe-ubiquity`, which shows a language Welcome
# screen before the desktop. Selecting a language there (it auto-selects the one from locale=) runs
# Ubiquity's set_indicator_keymaps(), which writes a per-language desktop layout list with the
# language's layout first (Français -> French (alt.), French, Belgian, Canadian; Nederlands -> Dutch
# first) and so overrides the Belgian boot option on the live desktop. Measured on Zorin 18.1, see
# NOTES.md. The tool therefore drops `maybe-ubiquity`: the ISO boots straight to the live desktop
# (language and keyboard are already chosen) and "Install" stays on the desktop. KEEP_WELCOME=1 keeps it.
#
# LANGS="nl_BE:Nederlands_(België) fr_BE:Français_(Belgique)" (pairs locale:title, separated by spaces; underscores
# in a title stand for spaces) replaces the main "Try or Install" entry of each menu by one entry per language, all
# with the Belgian keyboard; the first language becomes the default (also for the other entries, e.g. safe
# graphics). Without LANGS the menu keeps its entries and every one gets PARAMS. The numpad Comma variant cannot be
# chosen here: casper ignores keyboard options on the kernel command line (19keyboard resets XKBOPTIONS), so it
# needs the packages (be-azerty-fix DECIMAL=comma).
#
# MENU=b: boot menu "B": the first live entry becomes one submenu per language
# (Nederlands, Français, Deutsch, English), each asking for the keyboard (Belgian AZERTY with the numpad period or
# comma; German QWERTZ under Deutsch and English); Nederlands with the period starts after the timeout. Done by
# tools/belgian_boot_menu.py. Every other entry stays as the distribution wrote it.
# PACKAGES=DIR (with MENU=b, needs root): the all-in-one stick. Our two packages and keyd (the keyd-team PPA's .deb) from DIR are installed into an
# extra layer, /casper/zz-belgian-azerty.squashfs, which casper stacks on top of the untouched filesystem.squashfs
# (tools/stick/build-layer.sh); the packages themselves go to /belgian/ for the installer. The layer applies the boot
# menu choice in the live session (numpad comma, Belgian formats for English) and makes an install from the stick
# get the packages and the same choice (tools/stick/belgian-stick).
#
# The tool also updates md5sum.txt for every file it changes, so the boot menu's "Check the disc for defects"
# and casper's background check still pass. Needs xorriso. Exit status is non-zero on any failure.
set -euo pipefail
command -v xorriso >/dev/null || { echo "xorriso is required (sudo apt install xorriso)" >&2; exit 1; }
[ $# -ge 2 ] || { sed -n '2,7p' "$0" >&2; exit 2; }
IN=$1; OUT=$2
PARAMS=${3:-"keyboard-configuration/layoutcode=be locale=fr_BE.UTF-8"}
LANGS=${LANGS:-}
MENU=${MENU:-}
PACKAGES=${PACKAGES:-}
HERE=$(cd "$(dirname "$0")" && pwd)
case "$MENU" in ""|b) ;; *) echo "MENU must be empty or b" >&2; exit 2 ;; esac
[ -z "$PACKAGES" ] || [ "$MENU" = b ] || { echo "PACKAGES needs MENU=b" >&2; exit 2; }
if [ "$MENU" = b ]; then
  [ -z "$LANGS" ] || { echo "MENU=b and LANGS cannot be combined" >&2; exit 2; }
  # Entries the menu leaves alone (safe graphics, NVIDIA, compatibility mode ...) start like the default one.
  [ $# -ge 3 ] || PARAMS="keyboard-configuration/layoutcode=be locale=nl_BE.UTF-8 belgian.keyboard=be belgian.decimal=period"
  if [ -n "$PACKAGES" ]; then
    [ "$(id -u)" = 0 ] || { echo "PACKAGES needs root (the layer is built with loop and overlay mounts)" >&2; exit 2; }
    for n in keyd_ keyd-belgian-windows_ belgian-azerty-windows_; do
      ls "$PACKAGES"/${n}*.deb >/dev/null 2>&1 || { echo "no ${n}*.deb in $PACKAGES" >&2; exit 2; }
    done
  fi
fi
if [ -n "$LANGS" ]; then
  first=${LANGS%% *}
  [ "$first" != "${first#*_*:}" ] || { echo "LANGS must look like 'nl_BE:Nederlands_(België) fr_BE:Français_(Belgique)'" >&2; exit 2; }
  [ $# -ge 3 ] || PARAMS="keyboard-configuration/layoutcode=be locale=${first%%:*}.UTF-8"
fi
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
MAP=(); FOUND=0
# Every boot menu on the ISO: GRUB (grub.cfg, loopback.cfg) and isolinux/syslinux
# (isolinux.cfg, txt.cfg, live.cfg, menuentries.cfg ... names differ per distro).
mapfile -t CFGS < <(for d in /boot /isolinux /syslinux; do
                      xorriso -indev "$IN" -find "$d" -name '*.cfg' 2>/dev/null || true
                    done | sed -n "s/^'\(.*\)'\$/\1/p")
for f in "${CFGS[@]}"; do
  mkdir -p "$W/$(dirname "$f")"
  xorriso -osirrox on -indev "$IN" -extract "$f" "$W$f" >/dev/null 2>&1 || { echo "warning: could not read $f from $IN; left as is" >&2; continue; }
  chmod u+w "$W$f"
  cp "$W$f" "$W$f.orig"
  if [ "$MENU" = b ]; then
    case "$f" in /isolinux/*|/syslinux/*) kind=isolinux ;; *) kind=grub ;; esac
    python3 "$HERE/belgian_boot_menu.py" "$kind" "$([ -n "$PACKAGES" ] && echo 1 || echo 0)" < "$W$f.orig" > "$W$f"
  elif [ -n "$LANGS" ]; then
    # Replace the first casper entry (GRUB: menuentry ... { ... }; isolinux: LABEL ... up to the next blank line)
    # by one copy per language: title gets " - <language>", the kernel line gets the Belgian keyboard + locale.
    # The isolinux/syslinux menu (legacy BIOS boot) cannot show UTF-8 (België came out as garbage characters in
    # the emulator), so its titles are folded to ASCII (Belgie, Francais); GRUB (UEFI) shows them as written.
    case "$f" in /isolinux/*|/syslinux/*) iso=1; titles=$(printf %s "$LANGS" | LC_ALL=C.UTF-8 iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null) || titles=$LANGS ;;
                                       *) iso=0; titles=$LANGS ;; esac
    awk -v langs="$titles" -v iso="$iso" '
      function emit(   n, k, i, a, loc, title, line, low) {
        n = split(langs, a, " ")
        for (k = 1; k <= n; k++) {
          loc = substr(a[k], 1, index(a[k], ":") - 1); title = substr(a[k], index(a[k], ":") + 1); gsub(/_/, " ", title)
          for (i = 1; i <= nb; i++) {
            line = buf[i]; low = tolower(line)
            if (iso && low ~ /^[[:space:]]*menu[[:space:]]+default/ && k > 1) continue
            if (iso && low ~ /^[[:space:]]*label[[:space:]]/ && k > 1) sub(/[[:space:]]*$/, "_" loc, line)
            if (iso && low ~ /^[[:space:]]*menu[[:space:]]+label/) { if (k > 1) gsub(/\^/, "", line); line = line " - " title }
            if (!iso && low ~ /^[[:space:]]*menuentry[[:space:]]/) sub(/["\047] /, " - " title "&", line)
            if (low ~ /casper/ && low ~ /^[[:space:]]*(linux|linuxefi|append)[[:space:]]/ && line !~ /layoutcode=/) {
              if (line ~ / ---?( |$)/) sub(/ ---?( |$)/, " keyboard-configuration/layoutcode=be locale=" loc ".UTF-8&", line)
              else line = line " keyboard-configuration/layoutcode=be locale=" loc ".UTF-8"
            }
            print line
          }
          if (iso && k < n) print ""
        }
      }
      { low = tolower($0) }
      done == 0 && !inb && !iso && low ~ /^[[:space:]]*menuentry[[:space:]]/ { inb = 1; nb = 0 }
      done == 0 && !inb && iso && low ~ /^[[:space:]]*label[[:space:]]/ { inb = 1; nb = 0 }
      inb { buf[++nb] = $0
            if ((!iso && low ~ /^[[:space:]]*}/) || (iso && low ~ /^[[:space:]]*$/)) {
              inb = 0; hascasper = 0; for (i = 1; i <= nb; i++) if (buf[i] ~ /casper/) hascasper = 1
              if (hascasper) { if (iso) nb--; emit(); done = 1; if (iso) print "" } else for (i = 1; i <= nb; i++) print buf[i]
            }
            next }
      { print }
      END { if (inb) { h = 0; for (i = 1; i <= nb; i++) if (buf[i] ~ /casper/) h = 1     # last entry, no blank line after
                       if (h) emit(); else for (i = 1; i <= nb; i++) print buf[i] } }
    ' "$W$f.orig" > "$W$f"
  fi
  # Kernel option lines: GRUB `linux /casper/vmlinuz ...`; isolinux `APPEND ... initrd=/casper/...`
  # (in isolinux a `linux` line only names the kernel file, so it must not get the options).
  case "$f" in /isolinux/*|/syslinux/*) KW=append ;; *) KW="linux|linuxefi" ;; esac
  # Add PARAMS before the first " ---" / " --" separator (what follows it is copied to the
  # installed system; these options are live-only), else at the end. Lines that already
  # carry a layoutcode= are left alone, so running the tool twice changes nothing.
  sed -i -E "/^[[:space:]]*($KW)[[:space:]].*casper/I{ /layoutcode=/b; / ---?( |\$)/{ s# (---?)( |\$)# $PARAMS \1\2#; b; }; s#\$# $PARAMS#; }" "$W$f"
  [ "${KEEP_WELCOME:-0}" = 1 ] || sed -i -E "/^[[:space:]]*($KW)[[:space:]].*casper/I s/ maybe-ubiquity( |\$)/\1/" "$W$f"
  FOUND=$((FOUND + $(grep -c layoutcode= "$W$f" || true)))
  if ! cmp -s "$W$f" "$W$f.orig"; then
    MAP+=(-map "$W$f" "$f")
    echo "patched $f ($(grep -c layoutcode= "$W$f") boot entries)"
  fi
done
# All-in-one stick: the extra layer and the packages (see PACKAGES above).
NEW=()
if [ -n "$PACKAGES" ]; then
  echo "building the package layer (this unpacks the system image once)"
  xorriso -osirrox on -indev "$IN" -extract /casper/filesystem.squashfs "$W/filesystem.squashfs" >/dev/null 2>&1 \
    || { echo "could not read /casper/filesystem.squashfs from $IN" >&2; exit 1; }
  rc=0; bash "$HERE/stick/build-layer.sh" "$W/filesystem.squashfs" "$PACKAGES" "$W/zz-belgian-azerty.squashfs" \
    > "$OUT.layer.log" 2>&1 || rc=$?
  [ $rc = 0 ] || { echo "building the layer failed (full log: $OUT.layer.log):" >&2; tail -40 "$OUT.layer.log" >&2; exit 1; }
  rm -f "$W/filesystem.squashfs"
  mkdir -p "$W/belgian"
  cp "$PACKAGES"/keyd_*_amd64.deb "$PACKAGES"/keyd-belgian-windows_*_all.deb "$PACKAGES"/belgian-azerty-windows_*_all.deb "$W/belgian/"
  printf '%s\n' "Belgian AZERTY packages for this stick (unofficial, community made; not by the makers of this distribution)." \
    "The installer adds them to the installed system when the Belgian keyboard is chosen." \
    "Source, documentation and how to remove: see README.md of the Belgian AZERTY project." > "$W/belgian/README.txt"
  MAP+=(-map "$W/zz-belgian-azerty.squashfs" /casper/zz-belgian-azerty.squashfs)
  NEW+=(/casper/zz-belgian-azerty.squashfs)
  for d in "$W"/belgian/*; do MAP+=(-map "$d" "/belgian/${d##*/}"); NEW+=("/belgian/${d##*/}"); done
  echo "added the package layer and /belgian/ ($(du -sh "$W/zz-belgian-azerty.squashfs" | cut -f1) layer)"
fi

# The ISO's own checksum list (md5sum.txt) is what "Check the disc for defects" and casper-md5check at boot
# compare against: without updating it, every patched menu is reported as corrupt. Rewrite the line of each
# file whose content no longer matches (also repairs ISOs built by older versions of this tool), add lines only for the files the stick adds.
SUMS=/md5sum.txt
if xorriso -osirrox on -indev "$IN" -extract "$SUMS" "$W/md5sum.txt" >/dev/null 2>"$W/xorriso.log"; then
  chmod u+w "$W/md5sum.txt"; cp "$W/md5sum.txt" "$W/md5sum.txt.orig"
  for f in "${CFGS[@]}"; do
    [ -f "$W$f" ] || continue
    grep -q "  \.$f\$" "$W/md5sum.txt" || continue
    sum=$(md5sum < "$W$f" | cut -d' ' -f1)
    awk -v p=".$f" -v s="$sum" '{ if (substr($0, 35) == p) print s "  " p; else print }' \
      "$W/md5sum.txt" > "$W/md5sum.new" && mv "$W/md5sum.new" "$W/md5sum.txt"
  done
  # Files the stick adds get a line too, so the disc check also covers them.
  for f in "${NEW[@]}"; do
    grep -v "  \.$f\$" "$W/md5sum.txt" > "$W/md5sum.new" || true
    src="$W${f#/casper}"       # /casper/zz-belgian-azerty.squashfs and /belgian/* were staged at $W/zz-... and $W/belgian/
    echo "$(md5sum < "$src" | cut -d' ' -f1)  .$f" >> "$W/md5sum.new"; mv "$W/md5sum.new" "$W/md5sum.txt"
  done
  if ! cmp -s "$W/md5sum.txt" "$W/md5sum.txt.orig"; then
    MAP+=(-map "$W/md5sum.txt" "$SUMS")
    echo "updated $SUMS ($(diff "$W/md5sum.txt.orig" "$W/md5sum.txt" | grep -c '^>') checksums)"
  fi
else
  echo "note: $IN has no $SUMS; nothing to update for the disc check"
fi
if [ ${#MAP[@]} -eq 0 ]; then
  [ "$FOUND" -gt 0 ] || { echo "no casper boot entries found in $IN" >&2; exit 1; }
  echo "$IN already starts with these keyboard options; copied unchanged"; cp "$IN" "$OUT"; exit 0
fi
if ! xorriso -indev "$IN" -outdev "$OUT" "${MAP[@]}" -boot_image any replay >/dev/null 2>"$W/xorriso.log"; then
  echo "xorriso failed to write $OUT:" >&2; tail -20 "$W/xorriso.log" >&2; exit 1
fi
# Self-check: every changed file must match its line in the new md5sum.txt.
if [ -f "$W/md5sum.txt" ]; then
  mkdir -p "$W/check"
  xorriso -osirrox on -indev "$OUT" -extract "$SUMS" "$W/check/md5sum.txt" >/dev/null 2>&1
  bad=0
  for f in "${CFGS[@]}" "${NEW[@]}"; do
    line=$(grep "  \.$f\$" "$W/check/md5sum.txt" || true); [ -n "$line" ] || continue
    rm -f "$W/check/one"
    xorriso -osirrox on -indev "$OUT" -extract "$f" "$W/check/one" >/dev/null 2>&1
    [ "$(md5sum < "$W/check/one" | cut -d' ' -f1)" = "${line%%  *}" ] || { echo "checksum mismatch in $OUT: $f" >&2; bad=1; }
  done
  [ "$bad" = 0 ] || exit 1
  echo "checked: every boot menu${NEW[*]:+ and added file} matches $SUMS"
fi
echo "wrote $OUT"
