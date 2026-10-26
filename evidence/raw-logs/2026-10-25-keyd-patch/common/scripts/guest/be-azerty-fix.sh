#!/usr/bin/env bash
# be-azerty-fix: make every keyboard-layout store on an Ubuntu-based system agree on Belgian AZERTY, with the
# Windows habits Belgians expect (Ctrl+Alt as AltGr, Caps Lock as on Windows, Period or Comma on the numpad).
# Targets: Linux Mint 22 (Cinnamon, LightDM + slick-greeter) and Zorin OS 18 (GNOME, GDM); live sessions too.
#
#   be-azerty-fix check               show what every store currently says (no changes, no root needed)
#   be-azerty-fix live                fix the running session only (forgotten at reboot)
#   sudo be-azerty-fix system         fix the installed system: console, boot prompt, login screen, your desktop,
#                                     and the defaults that new users (and reset settings) start from
#   sudo be-azerty-fix uninstall      remove everything this project added and leave a stock system that still
#                                     types Belgian (the layout and the Period/Comma choice are standard Linux)
#
# Settings, given as environment variables:
#   PROFILE=windows | linux           The two profiles. windows (the default): everything below set the Windows way,
#                                     i.e. Ctrl+Alt works as AltGr and Caps Lock as on Windows. linux: the Belgian
#                                     layout with Linux conventions (Caps Lock only for letters, Ctrl+Alt stays
#                                     Ctrl+Alt; the keyd service is switched off, the packages stay installed so
#                                     switching back is one command). Example:  sudo PROFILE=linux be-azerty-fix system
#                                     When not given: the profile of the last "system" run, else windows. CAPS and
#                                     DECIMAL below can still be set on their own.
#   DECIMAL=period | comma            Windows has two Belgian layouts that differ only on the numpad decimal key.
#                                     period = "Belgian (Period)", the common one; comma = "Belgian (Comma)" (adds the
#                                     standard XKB option kpdl:comma). Example:  sudo DECIMAL=comma be-azerty-fix system
#                                     When not given: the choice of the last "system" run is kept; on the first run,
#                                     comma if /etc/default/keyboard already has kpdl:comma, else period.
#   CAPS=windows | linux              When not given: the profile when PROFILE is given, else the choice of the last
#                                     "system" run, else the profile.
#                                     windows: Caps Lock gives the Shift level on the whole main block, as on Windows
#                                     (1 2 3 ... 0 ° _ % £ ? . / +); Shift+Caps gives the normal level; ² < AltGr and
#                                     the numpad are unaffected. Needs the belgian-azerty-windows package (option
#                                     caps:be_windows). linux: Caps Lock only changes letters and é è ç à.
#   VARIANT=  (default, standard Belgian) | oss | nodeadkeys   other variants of the Belgian layout. Only the default
#                                     was tested on the real distributions; oss and nodeadkeys were checked at the
#                                     layout level only (libxkbcommon).
#   KEEP_KEYD=1                       with uninstall: keep the keyd daemon package (the Belgian rules still go).
# The settings can also follow the command, e.g.  sudo be-azerty-fix system PROFILE=linux DECIMAL=comma
# (that is how the "Belgian keyboard" window, be-azerty-settings, passes them through pkexec).
#
# Ctrl+Alt+2 = @ and Ctrl+Alt+E = € come from the keyd-belgian-windows package (keyd rules); "system" installs the
# packages found next to this script (or in dist/ next to it) if they are not installed yet.
#
# Status: see NOTES.md for what was run where. Version 0.9.3 (2026-10-24).
set -u
for a in "${@:2}"; do
  case "$a" in
    PROFILE=*|DECIMAL=*|CAPS=*|VARIANT=*|KEEP_KEYD=*) export "${a?}" ;;
    *) echo "unknown setting: $a (expected PROFILE=, DECIMAL=, CAPS=, VARIANT= or KEEP_KEYD=)" >&2; exit 1 ;;
  esac
done
LAYOUT=be
VARIANT="${VARIANT:-}"
case "$VARIANT" in ""|oss|nodeadkeys) ;; *) echo "VARIANT must be empty, oss or nodeadkeys" >&2; exit 1 ;; esac
MODEL=pc105
# PROFILE, DECIMAL and CAPS chosen with "system" are saved here, so running "system" again (after an update, or to repair the
# settings) keeps a Comma or Linux Caps Lock choice instead of silently going back to the defaults.
CHOICES=/var/lib/belgian-azerty-windows/choices
saved_choice() { [ -r "$CHOICES" ] && sed -n "s/^$1=\([a-z]*\)\$/\1/p" "$CHOICES" | tail -1; }
if [ -n "${DECIMAL:-}" ]; then DECIMAL_FROM="given"
elif DECIMAL=$(saved_choice DECIMAL) && [ -n "$DECIMAL" ]; then DECIMAL_FROM="kept from the last run"
elif grep -qE '^XKBOPTIONS=.*kpdl:comma' /etc/default/keyboard 2>/dev/null; then DECIMAL=comma; DECIMAL_FROM="kept from /etc/default/keyboard"
else DECIMAL=period; DECIMAL_FROM="default"; fi
case "$DECIMAL" in period|comma) ;; *) echo "DECIMAL must be period or comma" >&2; exit 1 ;; esac
if [ -n "${PROFILE:-}" ]; then PROFILE_FROM="given"; PROFILE_GIVEN=1
elif PROFILE=$(saved_choice PROFILE) && [ -n "$PROFILE" ]; then PROFILE_FROM="kept from the last run"
else PROFILE=windows; PROFILE_FROM="default"; fi
case "$PROFILE" in windows|linux) ;; *) echo "PROFILE must be windows or linux" >&2; exit 1 ;; esac
if [ -n "${CAPS:-}" ]; then CAPS_FROM="given"
elif [ "${PROFILE_GIVEN:-0}" = 1 ]; then CAPS=$PROFILE; CAPS_FROM="from the profile"
elif CAPS=$(saved_choice CAPS) && [ -n "$CAPS" ]; then CAPS_FROM="kept from the last run"
else CAPS=$PROFILE; CAPS_FROM="from the profile"; fi
case "$CAPS" in windows|linux) ;; *) echo "CAPS must be windows or linux" >&2; exit 1 ;; esac
XKB_RULES=/usr/share/X11/xkb/rules/evdev
XKB_CAPS=/usr/share/X11/xkb/symbols/be_capslock
# Cinnamon (Mint) ships a schema default for its xkb-options, which beats /etc/default/keyboard for every user who has
# no setting of their own (new users, reset settings). This override (written by "system", removed by "uninstall" and
# by removing the package) makes that default carry our options. GNOME (Zorin) has no such default and follows
# /etc/default/keyboard, so nothing is written there.
CINNAMON_OVERRIDE=/usr/share/glib-2.0/schemas/zz_belgian-azerty-windows.gschema.override
# Files written by be-azerty-fix.sh before the Caps Lock option moved into a package (removed when found).
LEGACY_APT_HOOK=/etc/apt/apt.conf.d/99be-azerty-xkb
LEGACY_ENSURE=/usr/local/sbin/be-azerty-xkb-ensure
LEGACY_RULE_MARK='// be-azerty-fix.sh: Caps Lock as on Windows Belgian'
ok()   { printf '  \033[32m✔\033[0m %s\n' "$*"; }
bad()  { printf '  \033[31m✘\033[0m %s\n' "$*"; FAILED=1; }
info() { printf '  · %s\n' "$*"; }
FAILED=0

usage() { sed -n '2,/^set -u$/{/^set -u$/d;s/^# \{0,1\}//;p}' "$0"; }

# ---------- helpers -------------------------------------------------------------------------------
target_user() {            # the human user, even when run through sudo or pkexec
  if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != root ]; then echo "$SUDO_USER"
  elif [ -n "${PKEXEC_UID:-}" ] && [ "$PKEXEC_UID" != 0 ]; then id -nu "$PKEXEC_UID"
  else id -un; fi
}
user_gsettings() {         # run gsettings as the target user on their session bus
  local u; u=$(target_user)
  local uid; uid=$(id -u "$u")
  local bus="unix:path=/run/user/$uid/bus"
  if [ "$(id -un)" = "$u" ]; then
    DBUS_SESSION_BUS_ADDRESS="$bus" gsettings "$@"
  else
    sudo -u "$u" DBUS_SESSION_BUS_ADDRESS="$bus" gsettings "$@"
  fi
}
has_schema() { gsettings list-schemas 2>/dev/null | grep -qx "$1"; }
desktop() {
  case "${XDG_CURRENT_DESKTOP:-}" in
    *Cinnamon*) echo cinnamon ;;
    *MATE*) echo mate ;;
    *GNOME*|*Zorin*) echo gnome ;;
    *) if has_schema org.cinnamon.desktop.interface; then echo cinnamon; else echo gnome; fi ;;
  esac
}
is_live() { [ "$(findmnt -no FSTYPE / 2>/dev/null)" = overlay ]; }
pkg_installed() { dpkg-query -W -f='${db:Status-Status}' "$1" 2>/dev/null | grep -qx installed; }
keyd_bin() { command -v keyd.rvaiya || command -v keyd; }   # Debian names the binary keyd.rvaiya
session_type() {           # x11, wayland, tty ... of the target user's graphical session
  # sudo drops XDG_SESSION_TYPE, so ask logind about the user's session; without an answer fall back to the variable.
  local u sid t=""; u=$(target_user)
  if [ "$(id -un)" = "$u" ] && [ -n "${XDG_SESSION_TYPE:-}" ]; then echo "$XDG_SESSION_TYPE"; return; fi
  sid=$(loginctl show-user "$u" -p Display --value 2>/dev/null)
  [ -n "$sid" ] && t=$(loginctl show-session "$sid" -p Type --value 2>/dev/null)
  echo "${t:-${XDG_SESSION_TYPE:-unknown}}"
}
# setxkbmap only on a real X server: on Wayland it would change Xwayland alone (and print a warning).
x11_session() { [ -n "${DISPLAY:-}" ] && [ "$(session_type)" != wayland ] && command -v setxkbmap >/dev/null; }

# XKB options with our choices applied: drop any kpdl:* option and our caps:be_windows, add kpdl:comma for
# DECIMAL=comma and caps:be_windows for CAPS=windows (only once the XKB files for it are in place), keep everything
# else (lv3:ralt_switch, terminate:ctrl_alt_bksp, ...). In and out: comma-separated list.
want_options() {
  local out="" o
  local IFS=,
  for o in $1; do
    case "$o" in ""|kpdl:*|caps:be_windows) ;; *) out="${out:+$out,}$o" ;; esac
  done
  [ "$DECIMAL" = comma ] && out="${out:+$out,}kpdl:comma"
  [ "$CAPS" = windows ] && caps_xkb_ready && out="${out:+$out,}caps:be_windows"
  echo "$out"
}
without_caps_option() {    # "a,caps:be_windows,b" -> "a,b"
  local out="" o
  local IFS=,
  for o in $1; do [ -z "$o" ] || [ "$o" = caps:be_windows ] || out="${out:+$out,}$o"; done
  echo "$out"
}

# The Caps Lock option is the package belgian-azerty-windows: /usr/share/X11/xkb/symbols/be_capslock plus a rule in
# the evdev rules file, which the package keeps in place across xkb-data upgrades (dpkg diversion + trigger). The same
# files serve X11 (Xorg), Wayland (libxkbcommon) and ckbcomp (whose console keymap does not change). An option the
# rules do not know is ignored by all three, so a missing rule only means Linux Caps behaviour, never a broken keyboard.
caps_xkb_ready() { [ -f "$XKB_CAPS" ] && grep -q 'caps:be_windows' "$XKB_RULES" 2>/dev/null; }
caps_needs_package() {
  if [ "$CAPS" = windows ] && ! caps_xkb_ready; then
    info "Caps Lock as on Windows needs the belgian-azerty-windows package (sudo apt install ./belgian-azerty-windows_*.deb); Caps Lock keeps the Linux behaviour for now"
  fi
}
remove_legacy_caps_files() {   # pieces an older be-azerty-fix.sh wrote by hand
  local removed=0
  if [ -e "$LEGACY_APT_HOOK" ]; then rm -f "$LEGACY_APT_HOOK"; removed=1; fi
  if [ -e "$LEGACY_ENSURE" ]; then rm -f "$LEGACY_ENSURE"; removed=1; fi
  if ! dpkg-divert --list "$XKB_RULES" 2>/dev/null | grep -q belgian-azerty-windows && grep -qF "$LEGACY_RULE_MARK" "$XKB_RULES" 2>/dev/null; then
    sed -i "\\#^$LEGACY_RULE_MARK\$#,/caps:be_windows/d" "$XKB_RULES"; removed=1
  fi
  if [ -f "$XKB_CAPS" ] && ! dpkg -S "$XKB_CAPS" >/dev/null 2>&1; then rm -f "$XKB_CAPS"; removed=1; fi
  if [ "$removed" = 1 ]; then ok "removed the hand-installed Caps Lock files of an older be-azerty-fix.sh"
  else ok "no files of an older be-azerty-fix.sh"; fi
}
gvariant_list() {          # "a,b" -> ['a', 'b']
  local out="" o
  local IFS=,
  for o in $1; do out="${out:+$out, }'$o'"; done
  echo "[$out]"
}
gsettings_options() {      # ['a', 'b'] -> a,b
  user_gsettings get "$1" xkb-options 2>/dev/null | sed -E "s/^@as //; s/[][' ]//g"
}
set_default_keyboard() {   # KEY VALUE: set (or add) one line of /etc/default/keyboard
  if grep -q "^$1=" /etc/default/keyboard 2>/dev/null; then sed -i "s|^$1=.*|$1=\"$2\"|" /etc/default/keyboard
  else printf '%s="%s"\n' "$1" "$2" >> /etc/default/keyboard; fi
}

# ---------- Cinnamon defaults for new users and reset settings ------------------------------------
cinnamon_defaults() {
  if ! has_schema org.cinnamon.desktop.input-sources; then
    info "no Cinnamon on this system: new users and reset settings follow /etc/default/keyboard"; return 0
  fi
  if [ -f "$CINNAMON_OVERRIDE" ]; then rm -f "$CINNAMON_OVERRIDE"; glib-compile-schemas /usr/share/glib-2.0/schemas 2>/dev/null; fi
  # The distribution's default (Mint: ['terminate:ctrl_alt_bksp']), read without any user setting.
  local dist want
  dist=$(GSETTINGS_BACKEND=memory gsettings get org.cinnamon.desktop.input-sources xkb-options 2>/dev/null | sed -E "s/^@as //; s/[][' ]//g")
  want=$(want_options "$dist")
  if [ "$want" = "$dist" ]; then ok "Cinnamon default options already match (${dist:-none}); no override needed"; return 0; fi
  printf '%s\n' "# Written by be-azerty-fix system; removed by be-azerty-fix uninstall and by removing belgian-azerty-windows." \
    "# Default keyboard options for Cinnamon users without a setting of their own (new users, reset settings)." \
    "[org.cinnamon.desktop.input-sources]" "xkb-options=$(gvariant_list "$want")" > "$CINNAMON_OVERRIDE"
  if glib-compile-schemas /usr/share/glib-2.0/schemas 2>/dev/null && \
     [ "$(GSETTINGS_BACKEND=memory gsettings get org.cinnamon.desktop.input-sources xkb-options 2>/dev/null)" = "$(gvariant_list "$want")" ]; then
    ok "Cinnamon default for new users and reset settings: $want"
  else
    rm -f "$CINNAMON_OVERRIDE"; glib-compile-schemas /usr/share/glib-2.0/schemas 2>/dev/null
    bad "could not set the Cinnamon default; new users get the distribution's Caps Lock and numpad behaviour"
  fi
}

# ---------- check ---------------------------------------------------------------------------------
check() {
  echo "Packages:"
  local p
  for p in belgian-azerty-windows keyd-belgian-windows keyd; do
    if pkg_installed "$p"; then ok "$p $(dpkg-query -W -f='${Version}' "$p")"; else info "$p not installed"; fi
  done
  echo "Profile:"
  case "$(saved_choice PROFILE)" in
    windows) info "Windows profile (Ctrl+Alt as AltGr, Caps Lock as on Windows); switch: sudo PROFILE=linux be-azerty-fix system" ;;
    linux) info "Linux-standard profile (Linux conventions); switch: sudo PROFILE=windows be-azerty-fix system" ;;
    *) info "no profile saved yet (\"sudo be-azerty-fix system\" saves one; the default is windows)" ;;
  esac
  if [ -e "$LEGACY_APT_HOOK" ] || [ -e "$LEGACY_ENSURE" ]; then info "files of an older be-azerty-fix.sh found; sudo be-azerty-fix system replaces them"; fi

  echo "System default (/etc/default/keyboard), used by the console, the boot prompt and the login screen:"
  if [ -r /etc/default/keyboard ]; then
    local l v; l=$(. /etc/default/keyboard; echo "${XKBLAYOUT:-}"); v=$(. /etc/default/keyboard; echo "${XKBVARIANT:-}")
    [ "$l" = "$LAYOUT" ] && ok "XKBLAYOUT=$l XKBVARIANT=$v" || bad "XKBLAYOUT=$l XKBVARIANT=$v (want $LAYOUT)"
    local o; o=$(. /etc/default/keyboard; echo "${XKBOPTIONS:-}")
    case ",$o," in *,kpdl:comma,*) info "numpad decimal: comma (Windows \"Belgian (Comma)\"), XKBOPTIONS=$o" ;;
                   *) info "numpad decimal: period (Windows \"Belgian (Period)\"), XKBOPTIONS=$o" ;; esac
    case ",$o," in *,caps:be_windows,*) info "Caps Lock: Windows behaviour (caps:be_windows)" ;;
                   *) info "Caps Lock: Linux behaviour (letters and é è ç à only)" ;; esac
    caps_xkb_ready && ok "Caps Lock option files present" || info "Caps Lock option files not installed"
    [ -r "$CHOICES" ] && info "choices saved by the last \"system\" run: $(tr '\n' ' ' < "$CHOICES")"
  else bad "file missing"; fi

  if command -v localectl >/dev/null; then
    echo "systemd-localed:"; localectl status 2>/dev/null | sed 's/^/  /' | grep -E 'Layout|Keymap|Variant' || info "no data"
  fi

  echo "Running X11 session:"
  if x11_session; then setxkbmap -query 2>/dev/null | sed 's/^/  /'
  else info "no X11 session (Wayland or console); see the desktop setting below"; fi

  echo "Desktop setting ($(desktop)):"
  case "$(desktop)" in
    gnome)
      user_gsettings get org.gnome.desktop.input-sources sources 2>/dev/null | sed 's/^/  /'
      info "xkb-options: $(gsettings_options org.gnome.desktop.input-sources)" ;;
    mate)
      user_gsettings get org.mate.peripherals-keyboard-xkb.kbd layouts 2>/dev/null | sed 's/^/  /' ;;
    cinnamon)
      # Cinnamon 6 has both stores (seen on Mint 22.3): csd-keyboard reads libgnomekbd, input-sources mirrors the X layout
      has_schema org.gnome.libgnomekbd.keyboard && user_gsettings get org.gnome.libgnomekbd.keyboard layouts 2>/dev/null | sed 's/^/  /'
      if has_schema org.cinnamon.desktop.input-sources; then
        user_gsettings get org.cinnamon.desktop.input-sources sources 2>/dev/null | sed 's/^/  /'
        info "xkb-options: $(gsettings_options org.cinnamon.desktop.input-sources)"
        if [ -f "$CINNAMON_OVERRIDE" ]; then ok "new users and reset settings start with: $(sed -n 's/^xkb-options=//p' "$CINNAMON_OVERRIDE")"
        else info "new users and reset settings start with the distribution default: $(GSETTINGS_BACKEND=memory gsettings get org.cinnamon.desktop.input-sources xkb-options 2>/dev/null)"; fi
      fi ;;
  esac

  echo "AccountsService record for $(target_user):"
  local f; f="/var/lib/AccountsService/users/$(target_user)"
  if [ -r "$f" ]; then grep -iE 'xkb|layout' "$f" | sed 's/^/  /' || info "no layout keys"; else info "not readable (needs sudo) or absent"; fi

  echo "Login screen:"
  if [ -d /etc/gdm3 ]; then
    info "GDM: follows the system default unless the gdm user overrides it"
    [ -r /var/lib/gdm3/.config/dconf/user ] && info "gdm user has a dconf database (may override the layout)"
  fi
  [ -d /etc/lightdm ] && info "LightDM: follows the system default; slick-greeter can show a layout indicator"

  echo "Input method:"
  if pgrep -x ibus-daemon >/dev/null; then info "ibus-daemon is running (can override the layout per app; very fast typing can swap characters, see README)"; else ok "no ibus-daemon"; fi

  echo "Windows-style Ctrl+Alt = AltGr (keyd):"
  if [ -n "$(keyd_bin)" ]; then
    if [ -r /etc/keyd/be-winaltgr.conf ]; then ok "keyd installed with the Belgian Ctrl+Alt rules"; else info "keyd installed, but /etc/keyd/be-winaltgr.conf is missing (install keyd-belgian-windows)"; fi
    if [ "$(saved_choice PROFILE)" = linux ]; then
      systemctl is-active --quiet keyd 2>/dev/null && bad "Linux-standard profile, but keyd is running (Ctrl+Alt acts as AltGr)" \
        || ok "Linux-standard profile: keyd off, Ctrl+Alt stays Ctrl+Alt"
    else
      systemctl is-active --quiet keyd 2>/dev/null && ok "keyd service running" || bad "keyd service not running"
    fi
  else info "keyd not installed: Ctrl+Alt+2 will not type @ in graphical apps (only AltGr does)"; fi

  echo "Boot image:"
  if is_live; then
    info "live session (root is an overlay): no boot image to check"
  elif [ -r /etc/default/keyboard ] && ls /boot/initrd.img-* >/dev/null 2>&1; then
    local newest; newest=$(ls -t /boot/initrd.img-* | head -1)
    [ "$newest" -nt /etc/default/keyboard ] && ok "initramfs newer than /etc/default/keyboard" || bad "initramfs older than /etc/default/keyboard: run sudo update-initramfs -u"
  fi
}

# ---------- running session (no persistence) -----------------------------------------------------
live() {
  [ "${IN_SYSTEM:-0}" = 1 ] || echo "Choices: profile $PROFILE ($PROFILE_FROM), numpad decimal $DECIMAL ($DECIMAL_FROM), Caps Lock $CAPS ($CAPS_FROM)"
  caps_needs_package
  if x11_session; then
    local xo; xo=$(want_options "$(setxkbmap -query 2>/dev/null | sed -n 's/^options: *//p')")
    if setxkbmap -layout "$LAYOUT" ${VARIANT:+-variant "$VARIANT"} -model "$MODEL" -option "" ${xo:+-option "$xo"}; then
      ok "setxkbmap $LAYOUT $VARIANT ${xo:+(options $xo)}"
    else bad "setxkbmap failed"; fi
  fi
  case "$(desktop)" in
    gnome)
      user_gsettings set org.gnome.desktop.input-sources sources "[('xkb', '$LAYOUT${VARIANT:++$VARIANT}')]" \
        && ok "GNOME input source set" || bad "could not set the GNOME input source"
      user_gsettings set org.gnome.desktop.input-sources xkb-options "$(gvariant_list "$(want_options "$(gsettings_options org.gnome.desktop.input-sources)")")" \
        && ok "GNOME numpad decimal: $DECIMAL, Caps Lock: $CAPS" || bad "could not set the GNOME keyboard options" ;;
    mate)
      user_gsettings set org.mate.peripherals-keyboard-xkb.kbd layouts "['$LAYOUT\t$VARIANT']" \
        && ok "MATE layouts set" || bad "could not set the MATE layouts" ;;
    cinnamon) # Cinnamon 6 ships both stores (csd-keyboard reads libgnomekbd; the settings UI also knows input-sources); set both
      if has_schema org.gnome.libgnomekbd.keyboard; then
        user_gsettings set org.gnome.libgnomekbd.keyboard layouts "['$LAYOUT\t$VARIANT']" \
          && ok "Cinnamon libgnomekbd layouts set" || bad "could not set the libgnomekbd layouts"
      fi
      if has_schema org.cinnamon.desktop.input-sources; then
        user_gsettings set org.cinnamon.desktop.input-sources sources "[('xkb', '$LAYOUT${VARIANT:++$VARIANT}')]" \
          && ok "Cinnamon input-sources set" || bad "could not set the Cinnamon input sources"
        user_gsettings set org.cinnamon.desktop.input-sources xkb-options \
          "$(gvariant_list "$(want_options "$(gsettings_options org.cinnamon.desktop.input-sources)")")" \
          && ok "Cinnamon numpad decimal: $DECIMAL, Caps Lock: $CAPS" || bad "could not set the Cinnamon keyboard options"
      fi ;;
  esac
  [ "${IN_SYSTEM:-0}" = 1 ] || info "This lasts until reboot. For a USB stick that boots Belgian, use the Belgian ISO (make_belgian_iso.sh) or add  keyboard-configuration/layoutcode=$LAYOUT  to the boot line (press e at the boot menu)."
}

# ---------- installed system ----------------------------------------------------------------------
apply_default_keyboard() {   # OPTIONS: write debconf + /etc/default/keyboard, rebuild console keymap and boot image
  printf '%s\n' \
    "keyboard-configuration keyboard-configuration/layoutcode string $LAYOUT" \
    "keyboard-configuration keyboard-configuration/variantcode string $VARIANT" \
    "keyboard-configuration keyboard-configuration/modelcode string $MODEL" \
    "keyboard-configuration keyboard-configuration/optionscode string $1" \
    "keyboard-configuration keyboard-configuration/layout select Belgian" \
    | debconf-set-selections
  set_default_keyboard XKBLAYOUT "$LAYOUT"; set_default_keyboard XKBVARIANT "$VARIANT"
  set_default_keyboard XKBMODEL "$MODEL"; set_default_keyboard XKBOPTIONS "$1"
  DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive keyboard-configuration >/dev/null 2>&1 \
    && ok "/etc/default/keyboard written (options: ${1:-none})" || bad "dpkg-reconfigure keyboard-configuration failed"
  if command -v setupcon >/dev/null; then setupcon --save >/dev/null 2>&1 && ok "console keymap applied and cached" || bad "setupcon failed"; fi
  echo "Boot image (so the disk-encryption prompt types the same)"
  if is_live; then info "live session: the boot image cannot change here; skipped"
  else update-initramfs -u >/dev/null 2>&1 && ok "initramfs rebuilt" || bad "update-initramfs failed"; fi
}

install_packages() {         # install the .deb files shipped next to this script, if any
  local here; here=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
  local debs=() d n
  for n in keyd keyd-belgian-windows belgian-azerty-windows; do
    pkg_installed "$n" && continue
    d=$(ls "$here"/dist/"${n}"_*.deb "$here"/"${n}"_*.deb 2>/dev/null | sort -V | tail -1)
    [ -n "$d" ] && debs+=("$d")
  done
  [ ${#debs[@]} -gt 0 ] || return 0
  if DEBIAN_FRONTEND=noninteractive apt-get install -y "${debs[@]}" >/dev/null 2>&1; then ok "installed ${debs[*]##*/}"
  else bad "apt-get install ${debs[*]##*/} failed"; fi
}

system() {
  if [ "$(id -u)" -ne 0 ]; then bad "run with sudo"; exit 1; fi
  echo "Choices: profile $PROFILE ($PROFILE_FROM), numpad decimal $DECIMAL ($DECIMAL_FROM), Caps Lock $CAPS ($CAPS_FROM)."
  echo "  Change with PROFILE=windows|linux DECIMAL=period|comma CAPS=windows|linux"
  echo "0. Packages"
  install_packages
  remove_legacy_caps_files
  caps_needs_package
  echo "1. System default (console-setup / keyboard-configuration)"
  apply_default_keyboard "$(want_options "$(. /etc/default/keyboard 2>/dev/null; echo "${XKBOPTIONS:-}")")"

  echo "2. Defaults for new users and reset settings"
  cinnamon_defaults

  echo "3. Your desktop ($(desktop)) for user $(target_user)"
  # At boot (e.g. the first start after installing from the Belgian stick) or over ssh there is no desktop session to
  # change; desktops started later follow the system default written in step 1 (and the Cinnamon default of step 2).
  if [ "$(target_user)" = root ] || [ ! -S "/run/user/$(id -u "$(target_user)")/bus" ]; then
    info "no desktop session for $(target_user) right now: skipped; desktops started later follow the system default"
  else IN_SYSTEM=1 live; fi

  echo "4. Login screen"
  if [ -d /etc/gdm3 ] && [ -f /var/lib/gdm3/.config/dconf/user ]; then
    # GIO_USE_VFS=local: otherwise GIO starts gvfsd-fuse for gdm, which keeps our stdout open (a caller piping this
    # script, e.g. "| tee log", would then wait forever). All fds go to /dev/null for the same reason.
    timeout -k 5 30 sudo -u gdm -H env GIO_USE_VFS=local dbus-run-session gsettings reset org.gnome.desktop.input-sources sources </dev/null >/dev/null 2>&1
    local gdmsrc; gdmsrc=$(sudo -u gdm -H dconf read /org/gnome/desktop/input-sources/sources 2>/dev/null </dev/null)
    [ -z "$gdmsrc" ] && ok "GDM override cleared; greeter follows the system default" || bad "GDM still overrides the layout: $gdmsrc"
  elif [ -d /etc/gdm3 ]; then ok "GDM follows /etc/default/keyboard (no override)"; fi
  [ -d /etc/lightdm ] && ok "LightDM follows /etc/default/keyboard (already set)"

  mkdir -p "${CHOICES%/*}" && printf 'PROFILE=%s\nDECIMAL=%s\nCAPS=%s\n' "$PROFILE" "$DECIMAL" "$CAPS" > "$CHOICES" \
    || bad "could not save the choices in $CHOICES"

  echo "5. Windows-style Ctrl+Alt = AltGr (keyd)"
  if [ -n "$(keyd_bin)" ] && [ -r /etc/keyd/be-winaltgr.conf ] && [ "$PROFILE" = linux ]; then
    # Linux-standard profile: switch the keyd service off (stays off after reboots and package updates, which only
    # restart keyd when it is enabled). Only when our rules are keyd's only configuration, so other keyd users keep theirs.
    local others; others=$(find /etc/keyd -maxdepth 1 -name '*.conf' ! -name be-winaltgr.conf 2>/dev/null | head -1)
    if [ -n "$others" ]; then
      bad "keyd has other configuration ($others): not switching keyd off; remove /etc/keyd/be-winaltgr.conf by hand instead"
    elif systemctl disable --now keyd >/dev/null 2>&1; then
      systemctl reset-failed keyd.service >/dev/null 2>&1 || true
      ok "Linux-standard profile: keyd switched off, Ctrl+Alt stays Ctrl+Alt (AltGr types @ and €)"
    else bad "could not switch keyd off"; fi
  elif [ -n "$(keyd_bin)" ] && [ -r /etc/keyd/be-winaltgr.conf ]; then
    if ! systemctl is-enabled --quiet keyd 2>/dev/null || ! systemctl is-active --quiet keyd; then
      systemctl enable --now keyd >/dev/null 2>&1 || true
    fi
    systemctl is-active --quiet keyd && ok "keyd with the Belgian rules is installed and running" || bad "keyd is installed but not running"
  else
    info "keyd-belgian-windows not installed: Ctrl+Alt+2 keeps doing nothing in graphical apps (AltGr works)"
  fi

  echo
  if [ "$FAILED" = 0 ]; then echo "Done. Log out and back in (or reboot), then run:  be-azerty-fix check"
  else echo "Finished with errors (marked ✘ above)."; exit 1; fi
}

# ---------- uninstall -----------------------------------------------------------------------------
uninstall() {
  if [ "$(id -u)" -ne 0 ]; then bad "run with sudo"; exit 1; fi
  echo "1. Caps Lock option out of every setting this script can reach"
  local o keep; o=$(. /etc/default/keyboard 2>/dev/null; echo "${XKBOPTIONS:-}")
  keep=$(without_caps_option "$o")
  case ",$keep," in *,kpdl:comma,*) DECIMAL=comma ;; *) DECIMAL=period ;; esac
  CAPS=linux
  if [ "$keep" != "$o" ]; then apply_default_keyboard "$keep"; else ok "/etc/default/keyboard has no caps:be_windows"; fi
  local schema uo
  for schema in org.gnome.desktop.input-sources org.cinnamon.desktop.input-sources; do
    has_schema "$schema" || continue
    uo=$(gsettings_options "$schema")
    case ",$uo," in *,caps:be_windows,*)
      user_gsettings set "$schema" xkb-options "$(gvariant_list "$(without_caps_option "$uo")")" \
        && ok "$schema for $(target_user): caps:be_windows removed" || bad "could not change $schema for $(target_user)" ;;
    esac
  done
  if x11_session; then
    local xo; xo=$(without_caps_option "$(setxkbmap -query 2>/dev/null | sed -n 's/^options: *//p')")
    setxkbmap -option "" ${xo:+-option "$xo"} 2>/dev/null && ok "running X session: Caps Lock back to Linux behaviour"
  fi
  echo "2. Cinnamon defaults"
  if [ -f "$CINNAMON_OVERRIDE" ]; then
    rm -f "$CINNAMON_OVERRIDE"
    glib-compile-schemas /usr/share/glib-2.0/schemas 2>/dev/null && ok "removed $CINNAMON_OVERRIDE" || bad "glib-compile-schemas failed"
  else ok "no override to remove"; fi
  echo "3. Files of older versions"
  remove_legacy_caps_files
  rm -f "$CHOICES"; rmdir "${CHOICES%/*}" 2>/dev/null
  echo "4. Packages"
  local pk=() p
  for p in belgian-azerty-windows keyd-belgian-windows; do pkg_installed "$p" && pk+=("$p"); done
  # keyd itself goes too when it is our build (version ...~ubuntu24.04.N, or the older ...beazerty build), unless
  # KEEP_KEYD=1; a keyd from the distribution is left alone.
  if pkg_installed keyd && [ "${KEEP_KEYD:-0}" != 1 ]; then
    case "$(dpkg-query -W -f='${Version}' keyd)" in *~ubuntu24.04.*|*beazerty*) pk+=(keyd) ;; esac
  fi
  if [ ${#pk[@]} -gt 0 ]; then
    if DEBIAN_FRONTEND=noninteractive apt-get purge -y "${pk[@]}" >/dev/null 2>&1; then ok "purged ${pk[*]}"; else bad "apt-get purge ${pk[*]} failed"; fi
    # keyd exits with status 15 when stopped, so systemd would keep listing the removed unit as "failed".
    systemctl reset-failed keyd.service >/dev/null 2>&1 || true
  else ok "no packages of this project installed"; fi
  echo
  if [ "$FAILED" = 0 ]; then
    echo "Done. The keyboard stays Belgian (numpad: $DECIMAL); Caps Lock has the Linux behaviour; Ctrl+Alt is no longer AltGr."
    echo "Other users who had the Caps Lock option keep its name in their own settings; it is ignored (Linux Caps Lock)."
  else echo "Finished with errors (marked ✘ above)."; exit 1; fi
}

case "${1:-check}" in
  check) check ;;
  live) live ;;
  system) system ;;
  uninstall) uninstall ;;
  -h|--help|help) usage ;;
  *) usage; exit 1 ;;
esac
