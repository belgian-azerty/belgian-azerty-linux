# Other distributions: Fedora, openSUSE, Arch Linux, and NixOS, Gentoo, Slackware, Void, Solus

**Status (3 November 2026): tested in test containers only. Nothing is published for these systems**: no Fedora or
openSUSE repository, no AUR entry, no ready-made packages on the release page. The project itself is made for Linux
Mint 22.3 and Zorin OS 18.1 (see the README); these files are the first step towards other Linux families. Fedora, openSUSE and Arch have package files (below);
for NixOS, Gentoo, Slackware, Void and Solus there is a small script instead (see "No package: the script").

The packages give the same three keyboard options as the Debian/Ubuntu package of 0.9.12: `caps:be_windows` (Caps Lock
as on Windows), `be_azerty:accents` (Shift+AltGr accents as on Windows) and `be_azerty:mac` (Belgian Apple keyboards),
plus the Ctrl+Alt = AltGr rules for keyd.

## How it differs from the Debian/Ubuntu package

- **No file of the system is changed.** The rules go to `/etc/xkb/rules/evdev` (the system's own rules, included, then
  our lines) and the Caps Lock file to `/etc/xkb/symbols/be_capslock`. libxkbcommon reads `/etc/xkb` before the system
  folder; that this path is built in was checked on Fedora 44 and 45, openSUSE Tumbleweed and Leap 16.0, and Arch.
  The system's own keyboard package stays unchanged (`rpm -V` or `pacman -Qkk` give the same answer before and after).
- **Where it works**: programs that use libxkbcommon, which includes the Wayland desktops. Expected, not tested: GNOME
  on Wayland. Unknown: KDE Plasma. **Not read** by a pure X11 session (the X server has its own folder) or by the text
  console.
- **keyd**: Fedora has no keyd package, so `fedora/keyd.spec` builds keyd 2.6.0 unchanged from the official release.
  openSUSE (Tumbleweed 2.6.0, Leap 16.0 2.5.0 from Backports) and Arch (2.6.0 in [extra]) have their own, which our
  `keyd-belgian-windows` package uses.
- **keyd is switched on when `keyd-belgian-windows` is installed** (if systemd runs), as on Debian and Ubuntu: Ctrl+Alt
  = AltGr is the reason to install it. On Arch this is unusual (Arch packages normally leave services off); this may
  still change.
- **A rules file of your own in `/etc/xkb` is kept.** Ours is then put beside it (`evdev.rpmnew` or `evdev.pacnew`) and
  the package says so: copy its lines into your file, or the three options stay unknown.
- **No `be-azerty-fix` in these packages**, and the options do not appear in the desktop's keyboard settings. To
  switch them on for the whole system (login screen and new users):
  `sudo localectl set-x11-keymap be pc105 "" caps:be_windows,be_azerty:accents` (checked in the test containers).
  For one GNOME user: `gsettings set org.gnome.desktop.input-sources xkb-options "['caps:be_windows','be_azerty:accents']"`
  (not tested on these systems). On Fedora, `sudo bash be-azerty-fix.sh system` from this repository does the
  system part and the users' stored GNOME settings (tested in containers only, see below). On openSUSE and Arch the
  script stops without changing anything.

## Build and install

Everything below builds from the release archive of the matching tag (here v0.9.12); the version is in the spec file
or PKGBUILD. Run it as a normal user, with `sudo` only for the install.

**Fedora 44 or 45**
```
sudo dnf install rpm-build rpmdevtools gcc make kernel-headers systemd-rpm-macros git
git clone https://github.com/belgian-azerty/belgian-azerty-linux && cd belgian-azerty-linux
rpmdev-setuptree
for s in packaging/fedora/*.spec; do spectool -g -R "$s" && rpmbuild -ba "$s"; done
R=$(rpm --eval %_rpmdir); sudo dnf install $R/x86_64/keyd-2.6.0-*.rpm $R/noarch/*-0.9.12-*.rpm
```

**openSUSE Tumbleweed or Leap 16.0**
```
sudo zypper install rpm-build systemd-rpm-macros git curl
git clone https://github.com/belgian-azerty/belgian-azerty-linux && cd belgian-azerty-linux
SRC=$(rpm --eval %_sourcedir); mkdir -p "$SRC"
curl -L -o "$SRC"/belgian-azerty-linux-0.9.12.tar.gz https://github.com/belgian-azerty/belgian-azerty-linux/archive/refs/tags/v0.9.12.tar.gz
for s in packaging/opensuse/*.spec; do rpmbuild -ba "$s"; done
sudo zypper install --allow-unsigned-rpm $(rpm --eval %_rpmdir)/noarch/*-0.9.12-*.rpm
```

**Arch Linux**
```
sudo pacman -S --needed base-devel git
git clone https://github.com/belgian-azerty/belgian-azerty-linux && cd belgian-azerty-linux/packaging/arch
(cd belgian-azerty-windows && makepkg -si)
(cd keyd-belgian-windows && makepkg -si)
```
makepkg checks the archive against the SHA256 in the PKGBUILD.

To remove: `sudo dnf remove`, `sudo zypper remove` or `sudo pacman -R` with `belgian-azerty-windows keyd-belgian-windows`
(keyd itself stays and can be removed on its own).

## No package: the script (NixOS, Gentoo, Slackware, Void, Solus, and others)

For systems without package files of this project, `packaging/etc-xkb/be-azerty-etc-xkb.sh` puts the same two files
in `/etc/xkb` (the Caps Lock file, and the rules file: the system's own rules included, then our lines). It changes no
file of the system and needs only `sh`:
```
git clone https://github.com/belgian-azerty/belgian-azerty-linux && cd belgian-azerty-linux
sudo sh packaging/etc-xkb/be-azerty-etc-xkb.sh install
sh packaging/etc-xkb/be-azerty-etc-xkb.sh status
sudo sh packaging/etc-xkb/be-azerty-etc-xkb.sh remove      # takes out only our two files
```
- A rules file of your own in `/etc/xkb` is kept: ours is written beside it as `evdev.belgian-azerty` with a message.
  A `be_capslock` file of your own is never overwritten.
- The script does not switch the options on and does not set up keyd. Switch the options on in your system's
  keyboard setting (`localectl` where systemd runs, as above; otherwise your desktop's or X server's own file).
  keyd: Void and NixOS have keyd 2.6.0, Solus 2.5.0; on Gentoo it is in the GURU overlay, on Slackware on
  SlackBuilds.org (none of these were run here). The rules file to give keyd is `keyd/be-winaltgr.conf`.
- On NixOS `/etc` is managed by the system configuration. Whether a rebuild keeps files it did not create in
  `/etc/xkb` was not checked; the NixOS way is to put the two files into `environment.etc` in your configuration
  (not tested).
- **Only for desktops that use libxkbcommon** (the Wayland desktops). An X11 session does not read `/etc/xkb`; many
  of these systems still run X11 (Slackware 15.0 by default).

## What was tested (3 November 2026, test containers, no desktop)

Built from the public v0.9.12 archive on each system. The tests are in `tests/`:

- `tests/rpm-cycle.sh` (Fedora 44 and 45, openSUSE Tumbleweed and Leap 16.0) and `tests/arch-cycle.sh` (Arch):
  install, the options known, Caps Lock 0 differences from Windows, the accents option exactly its 3 changes, a normal
  user gets the options, an update of the keyboard data keeps them, an upgrade to a rebuilt package, removal (options
  gone, keyboard still compiles, nothing of the system's left changed), and a user's own files in `/etc/xkb` and
  `/etc/keyd` kept. keyd's own check of our rules: no errors (keyd 2.6.0; Leap's 2.5.0 has no check command).
- `tests/fedora-fix.sh` (Fedora 44 and 45): `be-azerty-fix.sh` with systemd-localed (27 checks).
- The build steps above, followed as written by a normal user, on Fedora 44, Tumbleweed, Leap 16.0 and Arch.
- The script (`packaging/etc-xkb/`): with the keyboard library and data of Void, NixOS 26.05 and unstable, Gentoo,
  Slackware current and 15.0, and Solus (Slackware and Solus: their own packages on another base system, as no
  container exists for them). See `HOW-WE-TESTED.md`.
- Results per system: `HOW-WE-TESTED.md`.

**Not tested**: a desktop session (GNOME, KDE), the login screen, keyd running (Ctrl+Alt as AltGr in use), the text
console, disk unlock, a real installation or a real PC. Older Fedora (42 and before) and Fedora's relatives (RHEL,
Alma, Rocky) were not run.
