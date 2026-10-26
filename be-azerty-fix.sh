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
#   be-azerty-fix ibus-skip [list]    show which apps skip the ibus input method (no sudo: for your own user)
#   be-azerty-fix ibus-skip auto on|off|default   the automatic skip for the Terminal, the text editor and VS Code
#   be-azerty-fix ibus-skip on APP... let more apps skip ibus; APP is the app's menu file name (org.gnome.Terminal,
#                                     org.x.editor, com.microsoft.VSCode ...) or terminal, text-editor, vscode
#   be-azerty-fix ibus-skip off APP...  |  be-azerty-fix ibus-skip off --all     undo it (--all: the automatic part too)
#
# ibus skip: very fast typing can swap two characters (@€ arrives as €@) while the ibus input method sits between the
# keyboard and the app. An app that skips ibus gets GTK_IM_MODULE=gtk-im-context-simple: GTK then handles the keys
# itself (layout, dead keys and Compose still work) and the swaps measured with ibus do not happen there. (The short
# name "simple" works in GTK 4 only; GTK 3.24, as in gnome-terminal, needs the long one.) It is a workaround, not a fix:
# it only helps GTK apps (Qt and other toolkits ignore the variable), and in a skipped app ibus features are gone
# (Chinese/Japanese/Korean input methods, the ibus emoji picker).
# Automatic (Windows profile, with the belgian-azerty-windows package): at every login the Terminal and the text
# editor skip ibus, unless the user has an input method set up (an ibus engine in the keyboard settings or in the ibus
# preferences, or another framework such as fcitx); then they keep ibus until it is removed. Off with the Linux-standard
# profile; each user can switch it with "ibus-skip auto on|off" or the "Belgian keyboard" window.
# Done through a copy of the app's menu file in ~/.local/share/applications (with "env GTK_IM_MODULE=..." in front of
# the command), or, for an app that a systemd user service starts (gnome-terminal), a drop-in for that service. Apps
# added by hand are listed in ~/.config/belgian-azerty/ibus-skip, the automatic choice in ibus-skip-auto next to it;
# at every login the copies are made again from the current menu files.
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
#                                     "system" run, else the profile; on GNOME (Zorin) the profile alone gives linux,
#                                     because of a GNOME problem with Caps Lock in password fields on Wayland (see
#                                     README, "Caps Lock on Zorin"); CAPS=windows still switches it on there.
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
# Status: see NOTES.md for what was run where. Version 0.9.7 (2026-10-25, not published yet): 0.9.6 + VS Code in the automatic ibus skip (current menu file name).
set -u
[ "${1:-}" = ibus-skip ] || for a in "${@:2}"; do
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

# Caps Lock on GNOME (Zorin): there the Windows profile leaves Caps Lock as on Linux unless CAPS=windows is given.
# On GNOME's Wayland session (Zorin's default) a short Caps Lock tap in a GNOME Shell password field (lock screen,
# password dialogs) puts apps and GNOME Shell out of step until the next login; with caps:be_windows the keys
# 2 6 7 9 0 and % then give é § è ç à ù with and without Shift (GNOME problem; research/CAPS-DIALOG-DESYNC.md).
# Choices given on the command line or saved by an earlier run are kept as they are.
if [ "$CAPS" = windows ] && [ "$CAPS_FROM" = "from the profile" ] && [ "$(desktop)" = gnome ]; then
  CAPS=linux; CAPS_FROM="Windows profile on GNOME, where Windows Caps Lock is opt-in: CAPS=windows"
fi

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
    windows) if [ "$(saved_choice CAPS)" = linux ]; then
               info "Windows profile (Ctrl+Alt as AltGr; Caps Lock as on Linux, CAPS=windows switches Windows Caps Lock on); switch: sudo PROFILE=linux be-azerty-fix system"
             else
               info "Windows profile (Ctrl+Alt as AltGr, Caps Lock as on Windows); switch: sudo PROFILE=linux be-azerty-fix system"
             fi ;;
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
    case ",$o," in *,caps:be_windows,*) info "Caps Lock: Windows behaviour (caps:be_windows)"
                     [ "$(desktop)" = gnome ] && info "GNOME: after a Caps Lock tap in a password field (lock screen, password dialog) 2 6 7 9 0 % can stop working until you log out and in (README, \"Caps Lock on Zorin\")" ;;
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

  echo "Fast typing: apps that skip ibus, for $(target_user):"
  if [ "$(id -un)" = "$(target_user)" ]; then (skip_paths; skip_status)
  else
    local sl; sl="$(getent passwd "$(target_user)" | cut -d: -f6)/.config/belgian-azerty"
    info "automatic: $(head -1 "$sl/ibus-skip-auto" 2>/dev/null || echo "from the profile"); added by hand: $( [ -s "$sl/ibus-skip" ] && tr '\n' ' ' < "$sl/ibus-skip" || echo none) (details: be-azerty-fix ibus-skip, without sudo)"
  fi

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
  [ "${IN_SYSTEM:-0}" = 1 ] || skip_after_change
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
  [ "$(target_user)" != root ] && [ -S "/run/user/$(id -u "$(target_user)")/bus" ] && skip_after_change

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

# ---------- ibus skip (per app, per user) -----------------------------------------------------------
# Automatic (from the profile; Windows profile: on): the Terminal, the text editor and VS Code (when installed) skip
# ibus while the user has no input method set up (no Chinese/Japanese-style ibus engine, no other input-method framework); it pauses by itself at
# the next login once one is added. Users can turn it off (ibus-skip auto off, or the tick box in the "Belgian
# keyboard" window) and add or remove apps by hand. Every file written here carries a marker, and only marked files
# are ever changed or removed.
SKIP_MARK=X-BelgianAzerty-IbusSkip
SKIP_DROPIN=zz-belgian-azerty-ibus-skip.conf
SKIP_AUTO_APPS="terminal text-editor vscode"
skip_paths() {             # per-user locations, from the HOME this runs with
  SKIP_CONF=${XDG_CONFIG_HOME:-$HOME/.config}
  SKIP_LIST=$SKIP_CONF/belgian-azerty/ibus-skip
  SKIP_AUTO=$SKIP_CONF/belgian-azerty/ibus-skip-auto
  SKIP_APPS=${XDG_DATA_HOME:-$HOME/.local/share}/applications
  SKIP_UNITS=$SKIP_CONF/systemd/user
}
skip_source() {            # ID: the app's menu file from the system (never the user's own copy)
  local d IFS=:
  for d in ${XDG_DATA_DIRS:-/usr/local/share:/usr/share} /usr/local/share /usr/share; do
    [ -f "$d/applications/$1.desktop" ] && { echo "$d/applications/$1.desktop"; return 0; }
  done
  return 1
}
skip_unit() {              # ID: the systemd user service D-Bus starts this app with (gnome-terminal-server), if any
  local d f u IFS=:
  for d in ${XDG_DATA_DIRS:-/usr/local/share:/usr/share} /usr/share; do
    f="$d/dbus-1/services/$1.service"
    [ -f "$f" ] || continue
    u=$(sed -n 's/^SystemdService=//p' "$f" | head -1)
    [ -n "$u" ] && { echo "$u"; return 0; }
  done
  return 0
}
skip_resolve() {           # NAME: desktop id for a menu file name or a short name; first installed candidate wins
  local n=${1%.desktop} c
  case "$n" in
    terminal) set -- org.gnome.Terminal ;;
    text-editor) set -- org.gnome.TextEditor org.x.editor org.gnome.gedit xed gnome-text-editor ;;   # Zorin, Mint, Ubuntu (older)
    vscode) set -- com.microsoft.VSCode code code-oss codium ;;   # VS Code 1.143 renamed code.desktop
    *) set -- "$n" ;;
  esac
  for c in "$@"; do skip_source "$c" >/dev/null && { echo "$c"; return 0; }; done
  echo "$1"
}
skip_listed() { [ -f "$SKIP_LIST" ] && grep -qxF "$1" "$SKIP_LIST"; }
skip_own_copy() {          # ID: the user has their own (unmarked) menu file for this app
  [ -z "$(skip_unit "$1")" ] && [ -e "$SKIP_APPS/$1.desktop" ] && ! grep -q "^$SKIP_MARK=" "$SKIP_APPS/$1.desktop"
}
SKIP_AUTOSTART=/etc/xdg/autostart/be-azerty-ibus-skip.desktop
skip_auto_choice() {       # on | off: the user's own choice, else the saved profile's (Linux-standard: off, else on)
  local c
  [ -f "$SKIP_AUTOSTART" ] || { echo off; return 0; }   # script used without the package: no login refresh, no clean-up
  c=$(head -1 "$SKIP_AUTO" 2>/dev/null)
  case "$c" in on|off) echo "$c"; return 0 ;; esac
  [ "$(saved_choice PROFILE)" = linux ] && echo off || echo on
}
skip_auto_from() {
  if [ ! -f "$SKIP_AUTOSTART" ]; then echo "needs the belgian-azerty-windows package"
  elif [ -s "$SKIP_AUTO" ]; then echo "your choice"
  elif [ "$(saved_choice PROFILE)" = linux ]; then echo "default of the Linux-standard profile"
  else echo "default of the Windows profile"; fi
}
skip_unsafe() {            # why skipping ibus automatically would take something from this user (nothing printed: safe)
  # Another input-method framework (fcitx, uim, xim ...) chosen for the session: leave every app alone.
  case "${GTK_IM_MODULE:-ibus}" in
    ibus|gtk-im-context-simple|simple) ;;
    *) echo "another input method is in use (GTK_IM_MODULE=$GTK_IM_MODULE)"; return 0 ;;
  esac
  command -v gsettings >/dev/null || { echo "the input settings cannot be read (gsettings missing)"; return 0; }
  local k s e found=0
  # An ibus engine added in the desktop's keyboard settings: ('ibus', 'anthy') next to ('xkb', 'be').
  for k in org.gnome.desktop.input-sources org.cinnamon.desktop.input-sources; do
    s=$(gsettings get "$k" sources 2>/dev/null) || continue
    found=1
    e=$(printf '%s\n' "$s" | grep -o "('ibus', '[^']*')" | sed "s/('ibus', '\([^']*\)')/\1/" | head -3 | tr '\n' ' ')
    [ -n "$e" ] && { echo "an input method is set up in the keyboard settings: ${e% }"; return 0; }
  done
  # An engine added with ibus's own preferences (ibus-setup): anything but the plain xkb: layouts.
  if s=$(gsettings get org.freedesktop.ibus.general preload-engines 2>/dev/null); then
    found=1
    e=$(printf '%s\n' "$s" | grep -o "'[^']*'" | tr -d "'" | grep -v '^xkb:' | head -3 | tr '\n' ' ')
    [ -n "$e" ] && { echo "an input method is set up in the ibus preferences: ${e% }"; return 0; }
  fi
  [ "$found" = 1 ] || echo "the input settings of this desktop cannot be read"
  return 0
}
skip_auto_ids() {          # the automatic apps that are installed and not overridden by a menu file of the user's own
  local n id
  for n in $SKIP_AUTO_APPS; do
    id=$(skip_resolve "$n")
    skip_source "$id" >/dev/null && ! skip_own_copy "$id" && echo "$id"
  done
  return 0
}
skip_wanted() {            # every app that should skip ibus now: the user's own list, plus the automatic ones when on and safe
  { [ -f "$SKIP_LIST" ] && grep -v '^$' "$SKIP_LIST"
    if [ "$(skip_auto_choice)" = on ] && [ -z "$(skip_unsafe)" ]; then skip_auto_ids; fi
  } | awk '!seen[$0]++'
}
skip_apply() {             # ID [quiet]: write the drop-in or the menu-file copy for one app
  local id=$1 q=${2:-} src unit own f
  if ! src=$(skip_source "$id"); then
    [ -n "$q" ] || bad "$id: no menu file $id.desktop found (is the app installed? see: ls /usr/share/applications)"
    own="$SKIP_APPS/$id.desktop"; [ -f "$own" ] && grep -q "^$SKIP_MARK=" "$own" && rm -f "$own"
    return 1
  fi
  unit=$(skip_unit "$id")
  if [ -n "$unit" ]; then
    # The app is a client that asks a service to open the window (gnome-terminal -> gnome-terminal-server), so the
    # variable has to reach the service. Environment= in a drop-in wins over the session's GTK_IM_MODULE.
    f="$SKIP_UNITS/$unit.d/$SKIP_DROPIN"
    mkdir -p "${f%/*}" || { bad "$id: cannot create ${f%/*}"; return 1; }
    printf '%s\n' "# Written by be-azerty-fix ibus-skip ($SKIP_MARK). Remove with: be-azerty-fix ibus-skip off $id" \
      "[Service]" "Environment=GTK_IM_MODULE=gtk-im-context-simple" > "$f.tmp" && mv -f "$f.tmp" "$f" \
      || { bad "$id: cannot write $f"; return 1; }
    systemctl --user daemon-reload >/dev/null 2>&1 || true
    [ -n "$q" ] || ok "$id: skips ibus (drop-in for $unit)"
    if [ -z "$q" ] && systemctl --user is-active --quiet "$unit" 2>/dev/null; then
      info "$unit is running with ibus now: close every window of the app; the next one skips ibus"
    fi
    return 0
  fi
  own="$SKIP_APPS/$id.desktop"
  if skip_own_copy "$id"; then
    [ -n "$q" ] || bad "$id: you already have your own $own; not touching it (put env GTK_IM_MODULE=gtk-im-context-simple in front of its Exec= lines by hand)"
    return 1
  fi
  mkdir -p "$SKIP_APPS" || { bad "$id: cannot create $SKIP_APPS"; return 1; }
  # Same entry, with the variable in front of every command (the main one and the right-click actions). DBusActivatable
  # goes, so that menus start the command instead of asking D-Bus to start the app without the variable.
  { printf '# Written by be-azerty-fix ibus-skip from %s (sha256 %s)\n# Remove with: be-azerty-fix ibus-skip off %s\n' \
      "$src" "$(sha256sum < "$src" | cut -d' ' -f1)" "$id"
    awk -v mark="$SKIP_MARK=true" '
      /^\[/ { print; if ($0 == "[Desktop Entry]" && !m++) print mark; next }
      /^DBusActivatable[ \t]*=/ { next }
      /^Exec[ \t]*=/ { sub(/^Exec[ \t]*=[ \t]*/, ""); print "Exec=env GTK_IM_MODULE=gtk-im-context-simple " $0; next }
      { print }' "$src"; } > "$own.tmp" && mv -f "$own.tmp" "$own" || { rm -f "$own.tmp"; bad "$id: cannot write $own"; return 1; }
  if [ -z "$q" ]; then
    ok "$id: skips ibus (menu entry $own)"
    grep -qE '^Categories=.*(^|;|=)(Qt|KDE)(;|$)' "$src" && info "$id looks like a Qt/KDE app: GTK_IM_MODULE has no effect there"
    info "takes effect the next time $id starts from the menu or the dock; close it completely first"
  fi
  return 0
}
skip_unapply() {           # ID: remove this app's marked files
  local id=$1 own="$SKIP_APPS/$1.desktop" unit removed=0
  if [ -f "$own" ] && grep -q "^$SKIP_MARK=" "$own"; then rm -f "$own" && removed=1; fi
  unit=$(skip_unit "$id")
  if [ -n "$unit" ] && [ -f "$SKIP_UNITS/$unit.d/$SKIP_DROPIN" ]; then
    rm -f "$SKIP_UNITS/$unit.d/$SKIP_DROPIN" && removed=1; rmdir "$SKIP_UNITS/$unit.d" 2>/dev/null
    systemctl --user daemon-reload >/dev/null 2>&1 || true
    systemctl --user is-active --quiet "$unit" 2>/dev/null && info "$unit still runs without ibus until all its windows are closed"
  fi
  [ "$removed" = 1 ]
}
skip_unapply_all() {       # every marked file of this user, wanted or not, and the user's list
  local f
  for f in "$SKIP_APPS"/*.desktop; do [ -f "$f" ] && grep -q "^$SKIP_MARK=" "$f" && rm -f "$f"; done
  for f in "$SKIP_UNITS"/*.d/"$SKIP_DROPIN"; do [ -f "$f" ] && rm -f "$f" && rmdir "${f%/*}" 2>/dev/null; done
  systemctl --user daemon-reload >/dev/null 2>&1 || true
  rm -f "$SKIP_LIST"
  return 0
}
skip_refresh() {           # make the marked files match skip_wanted: new copies from the current menu files, stale ones out
  local f id keep w; w=$(skip_wanted)
  for f in "$SKIP_APPS"/*.desktop; do
    [ -f "$f" ] && grep -q "^$SKIP_MARK=" "$f" || continue
    id=${f##*/}; id=${id%.desktop}
    printf '%s\n' "$w" | grep -qxF "$id" || rm -f "$f"
  done
  for f in "$SKIP_UNITS"/*.d/"$SKIP_DROPIN"; do
    [ -f "$f" ] || continue
    keep=0
    while read -r id; do [ -n "$id" ] && [ "$(skip_unit "$id")" = "$(basename "${f%/*}" .d)" ] && keep=1; done <<< "$w"
    [ "$keep" = 1 ] || { rm -f "$f"; rmdir "${f%/*}" 2>/dev/null; systemctl --user daemon-reload >/dev/null 2>&1; }
  done
  while read -r id; do [ -n "$id" ] && skip_apply "$id" quiet; done <<< "$w"
  return 0
}
skip_status_one() {        # ID LABEL: is this app's file in place, and does the running app already skip ibus
  local id=$1 l=$2 unit pid
  unit=$(skip_unit "$id")
  if ! skip_source "$id" >/dev/null; then info "$id$l: the app is not installed"
  elif [ -n "$unit" ]; then
    if [ -f "$SKIP_UNITS/$unit.d/$SKIP_DROPIN" ]; then
      pid=$(systemctl --user show -p MainPID --value "$unit" 2>/dev/null)
      if [ -n "$pid" ] && [ "$pid" != 0 ] && [ -r "/proc/$pid/environ" ]; then
        tr '\0' '\n' < "/proc/$pid/environ" | grep -qx 'GTK_IM_MODULE=gtk-im-context-simple' \
          && ok "$id$l: skips ibus (running now without ibus)" \
          || info "$id$l: skips ibus from its next start (still running with ibus: close all its windows)"
      else ok "$id$l: skips ibus (drop-in for $unit)"; fi
    else info "$id$l: skips ibus from your next login (or now: be-azerty-fix ibus-skip refresh)"; fi
  elif grep -qs "^$SKIP_MARK=" "$SKIP_APPS/$id.desktop"; then ok "$id$l: skips ibus (menu entry $SKIP_APPS/$id.desktop)"
  else info "$id$l: skips ibus from your next login (or now: be-azerty-fix ibus-skip refresh)"; fi
}
skip_status() {
  local id why auto
  auto=$(skip_auto_choice); why=$(skip_unsafe)
  if [ "$auto" = off ]; then
    info "automatic: off ($(skip_auto_from)); turn on: be-azerty-fix ibus-skip auto on"
  elif [ -n "$why" ]; then
    info "automatic: paused, because $why (the Terminal, the text editor and VS Code keep ibus; it resumes at the next login after that is removed)"
  else
    info "automatic: on ($(skip_auto_from)): the Terminal, the text editor and VS Code skip ibus; turn off: be-azerty-fix ibus-skip auto off"
    while read -r id; do [ -n "$id" ] && ! skip_listed "$id" && skip_status_one "$id" " (automatic)"; done <<< "$(skip_auto_ids)"
  fi
  if [ -s "$SKIP_LIST" ]; then
    while read -r id; do [ -n "$id" ] && skip_status_one "$id" ""; done < "$SKIP_LIST"
  elif [ "$auto" = off ] || [ -n "$why" ]; then
    info "no app skips ibus. Per app by hand: be-azerty-fix ibus-skip on terminal"
  fi
  info "only when started from the menu, the dock or a shortcut (and gnome-terminal however it starts); undo all: be-azerty-fix ibus-skip off --all"
}
ibus_skip() {
  if [ "$(id -u)" -eq 0 ] && [ "$(target_user)" != root ]; then
    # Per-user files: write them as that user (under sudo or pkexec), so the user owns them.
    local u uid; u=$(target_user); uid=$(id -u "$u")
    exec runuser -u "$u" -- env -u SUDO_USER -u PKEXEC_UID HOME="$(getent passwd "$u" | cut -d: -f6)" XDG_RUNTIME_DIR="/run/user/$uid" \
      DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" "$(readlink -f "$0")" ibus-skip "$@"
  fi
  skip_paths
  local cmd=${1:-list} n id
  [ $# -gt 0 ] && shift
  case "$cmd" in
    list|status) echo "ibus skip for $(id -un):"; skip_status ;;
    auto)
      case "${1:-}" in
        on|off)
          mkdir -p "${SKIP_AUTO%/*}" && echo "$1" > "$SKIP_AUTO" || { bad "could not save the choice in $SKIP_AUTO"; exit 1; }
          skip_refresh
          if [ "$1" = off ]; then
            ok "automatic ibus skip off: the Terminal, the text editor and VS Code use ibus again from their next start"
            [ -s "$SKIP_LIST" ] && info "apps you added yourself still skip ibus: $(tr '\n' ' ' < "$SKIP_LIST")"
          elif [ -n "$(skip_unsafe)" ]; then info "automatic ibus skip on, but paused: $(skip_unsafe)"
          else ok "automatic ibus skip on: the Terminal, the text editor and VS Code skip ibus (close them completely and start them again)"; fi ;;
        default) rm -f "$SKIP_AUTO"; skip_refresh; ok "automatic ibus skip follows the profile again: $(skip_auto_choice)" ;;
        "") echo "ibus skip for $(id -un):"; skip_status ;;
        *) echo "usage: be-azerty-fix ibus-skip auto [on | off | default]" >&2; exit 1 ;;
      esac ;;
    on)
      [ $# -gt 0 ] || { echo "usage: be-azerty-fix ibus-skip on APP...   (APP: terminal, text-editor, vscode, or a menu file name)" >&2; exit 1; }
      for n in "$@"; do
        id=$(skip_resolve "$n")
        if skip_apply "$id"; then
          skip_listed "$id" || { mkdir -p "${SKIP_LIST%/*}" && echo "$id" >> "$SKIP_LIST"; } || bad "could not save $id in $SKIP_LIST"
        fi
      done ;;
    off)
      [ $# -gt 0 ] || { echo "usage: be-azerty-fix ibus-skip off APP...   or   be-azerty-fix ibus-skip off --all" >&2; exit 1; }
      if [ "$1" = --all ]; then
        # Also the automatic part, or the next login would bring the Terminal, the text editor and VS Code back.
        skip_unapply_all; mkdir -p "${SKIP_AUTO%/*}" && echo off > "$SKIP_AUTO"
        ok "no app skips ibus any more (stock behaviour; the automatic skip stays off: be-azerty-fix ibus-skip auto on brings it back)"
      else
        for n in "$@"; do
          id=$(skip_resolve "$n")
          if [ -f "$SKIP_LIST" ]; then grep -vxF "$id" "$SKIP_LIST" > "$SKIP_LIST.tmp"; mv -f "$SKIP_LIST.tmp" "$SKIP_LIST"; fi
          if printf '%s\n' "$(skip_wanted)" | grep -qxF "$id"; then
            info "$id is one of the automatic apps: to give it ibus back, turn the automatic skip off (be-azerty-fix ibus-skip auto off)"
          else skip_unapply "$id" && ok "$id: uses ibus again from its next start" || info "$id: was not skipping ibus"; fi
        done
        [ -s "$SKIP_LIST" ] || rm -f "$SKIP_LIST"
      fi ;;
    refresh)
      # At login (autostart entry of the package) and after "live"/"system": make the files match the wish again, so
      # a menu file changed by an app update is copied afresh, the automatic apps follow the input settings, and
      # marked files of apps no longer wanted go.
      skip_refresh; return 0 ;;
    purge)
      # uninstall and package removal: every marked file, the list and the automatic choice.
      skip_unapply_all; rm -f "$SKIP_AUTO"; rmdir "${SKIP_LIST%/*}" 2>/dev/null
      rmdir "$SKIP_UNITS" "${SKIP_UNITS%/*}" 2>/dev/null   # only when empty (left by the drop-in)
      return 0 ;;
    *) echo "usage: be-azerty-fix ibus-skip [list | auto [on|off|default] | on APP... | off APP... | off --all | refresh]" >&2; exit 1 ;;
  esac
  [ "$FAILED" = 0 ] || exit 1
}
skip_after_change() {      # after live/system: apply the ibus skip for the desktop user now instead of at the next login
  if ( ibus_skip refresh ) >/dev/null 2>&1; then
    info "fast typing: ibus skip brought up to date for $(target_user) (see: be-azerty-fix ibus-skip)"
  else info "fast typing: the ibus skip could not be brought up to date now; it is at the next login"; fi
}
skip_cleanup_all_users() { # root: remove every user's ibus-skip files (uninstall)
  local u uid home self n=0; self=$(readlink -f "$0")
  while IFS=: read -r u _ uid _ _ home _; do
    { [ "$uid" -ge 1000 ] && [ "$uid" -lt 60000 ]; } || [ "$uid" = 0 ] || continue
    [ -d "$home" ] || continue
    [ -e "$home/.config/belgian-azerty/ibus-skip" ] || [ -e "$home/.config/belgian-azerty/ibus-skip-auto" ] \
      || ls "$home"/.config/systemd/user/*.d/"$SKIP_DROPIN" >/dev/null 2>&1 \
      || grep -qls "^$SKIP_MARK=" "$home"/.local/share/applications/*.desktop 2>/dev/null || continue
    if [ "$uid" = 0 ]; then env -u SUDO_USER -u PKEXEC_UID HOME="$home" "$self" ibus-skip purge >/dev/null
    else runuser -u "$u" -- env -u SUDO_USER -u PKEXEC_UID HOME="$home" XDG_RUNTIME_DIR="/run/user/$uid" "$self" ibus-skip purge >/dev/null; fi \
      && ok "ibus skip removed for $u" || bad "could not remove the ibus skip files of $u"
    n=$((n + 1))
  done < <(getent passwd)
  [ "$n" -gt 0 ] || ok "no user has apps that skip ibus"
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
  echo "4. ibus skip per app (files in the users' home folders)"
  skip_cleanup_all_users
  echo "5. Packages"
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
  ibus-skip) shift; ibus_skip "$@" ;;
  -h|--help|help) usage ;;
  *) usage; exit 1 ;;
esac
