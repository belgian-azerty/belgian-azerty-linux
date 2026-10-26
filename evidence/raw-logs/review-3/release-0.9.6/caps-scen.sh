#!/bin/bash
# Option A choice logic of be-azerty-fix 0.9.6 (installed from dist/), run as root in the review container.
C=/var/lib/belgian-azerty-windows/choices
run() { # name, choices-file content ('' = no file), env...
  local name=$1 content=$2; shift 2
  echo "=== $name"
  if [ -z "$content" ]; then rm -f "$C"; echo "choices before: (no file)"; else mkdir -p "${C%/*}"; printf '%b' "$content" > "$C"; echo "choices before: $(tr '\n' ' ' < "$C")"; fi
  echo "env: $*"
  env -u XDG_CURRENT_DESKTOP "$@" be-azerty-fix system 2>&1 | grep -E "^Choices|Caps|caps" | head -5
  echo "choices after:  $(tr '\n' ' ' < "$C")"
  echo "XKBOPTIONS:     $(grep XKBOPTIONS /etc/default/keyboard)"
  echo "check:"; env -u XDG_CURRENT_DESKTOP "$@" be-azerty-fix check 2>&1 | grep -i -E "caps|GNOME" | head -4
}
echo "cinnamon schema present here: $(gsettings list-schemas 2>/dev/null | grep -c org.cinnamon.desktop.interface)"
run "S1 Zorin upgraded from 0.9.4.1, saved CAPS=windows, no desktop var (GNOME by fallback)" 'PROFILE=windows\nDECIMAL=period\nCAPS=windows\n'
run "S2 Zorin fresh, no choices file" ''
run "S3 stick fallback file (no CAPS line), GNOME by fallback (first-boot service)" 'PROFILE=windows\nDECIMAL=period\n'
run "S4 stick fallback file, XDG_CURRENT_DESKTOP=X-Cinnamon (Mint)" 'PROFILE=windows\nDECIMAL=period\n' XDG_CURRENT_DESKTOP=X-Cinnamon
run "S5 GNOME, CAPS=windows given (opt-in)" 'PROFILE=windows\nDECIMAL=period\nCAPS=linux\n' CAPS=windows XDG_CURRENT_DESKTOP=GNOME
run "S6 GNOME, window picks Windows profile (PROFILE=windows given) after S5 saved CAPS=windows" 'PROFILE=windows\nDECIMAL=period\nCAPS=windows\n' PROFILE=windows XDG_CURRENT_DESKTOP=zorin:GNOME
run "S7 GNOME, no choices file (repeat of S2 with the desktop variable set)" '' XDG_CURRENT_DESKTOP=GNOME
