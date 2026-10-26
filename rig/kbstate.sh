#!/bin/bash
# kbstate: one-line-per-store dump of every place the keyboard layout lives, plus keyd. Run after each durability event.
echo "=== kbstate $(date -u +%H:%M:%SZ) $1 ==="
echo "default:  $(grep -E 'XKBLAYOUT|XKBVARIANT|XKBOPTIONS' /etc/default/keyboard | tr '\n' ' ')"
echo "localed:  $(localectl status 2>/dev/null | grep -E 'Layout|Keymap' | tr -s ' ' | tr '\n' ' ')"
[ -n "$DISPLAY" ] && echo "x11:      $(setxkbmap -query 2>/dev/null | grep -E 'layout|variant|options' | tr -s ' ' | tr '\n' ' ')"
echo "gkbd:     $(gsettings get org.gnome.libgnomekbd.keyboard layouts 2>/dev/null)"
echo "gnome:    $(gsettings get org.gnome.desktop.input-sources sources 2>/dev/null) mru=$(gsettings get org.gnome.desktop.input-sources mru-sources 2>/dev/null) opts=$(gsettings get org.gnome.desktop.input-sources xkb-options 2>/dev/null) session=$XDG_SESSION_TYPE"
echo "cinnamon: $(gsettings get org.cinnamon.desktop.input-sources sources 2>/dev/null)"
echo "accounts: $(sudo -n grep -ihE 'xkb|layout' /var/lib/AccountsService/users/$USER 2>/dev/null | tr '\n' ' ')"
echo "greeter:  $(grep -hE 'keyboard|layout' /etc/lightdm/*.conf /etc/lightdm/lightdm.conf.d/* 2>/dev/null | tr '\n' ' ') gdm=$(v=$(sudo -n -u gdm -H dconf read /org/gnome/desktop/input-sources/sources 2>/dev/null </dev/null); echo "${v:-(default)}")"
echo "keyd:     $(systemctl is-active keyd 2>/dev/null) $(systemctl is-enabled keyd 2>/dev/null) conf=$(ls /etc/keyd/*.conf 2>/dev/null | tr '\n' ' ')"
echo "initrd:   $(ls -l --time-style=+%H:%M /boot/initrd.img-$(uname -r) 2>/dev/null | cut -d" " -f6-) vs /etc/default/keyboard $(ls -l --time-style=+%H:%M /etc/default/keyboard | cut -d" " -f6)"
