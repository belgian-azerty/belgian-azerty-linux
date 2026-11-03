# Belgian AZERTY like on Windows, openSUSE build (from the Fedora spec). Unlike the Debian
# package, nothing of openSUSE's is touched: the rules and symbols go to /etc/xkb, which libxkbcommon (and so GNOME's
# mutter on Wayland) reads before the system folder. Not read by a pure X11 session or the text console.
Name:           belgian-azerty-windows
Version:        0.9.12
Release:        1%{?dist}
Summary:        Belgian AZERTY like on Windows: Caps Lock, Shift+AltGr accents, Apple option
License:        MIT
URL:            https://github.com/belgian-azerty/belgian-azerty-linux
Source0:        https://github.com/belgian-azerty/belgian-azerty-linux/archive/refs/tags/v%{version}/belgian-azerty-linux-%{version}.tar.gz
BuildArch:      noarch
Requires:       libxkbcommon0 >= 1.0
Requires:       xkeyboard-config

%description
Adds three XKB options for the Belgian layout, without changing any file of
the system: caps:be_windows (Caps Lock as on Windows), be_azerty:accents
(Shift+AltGr accents as on Windows) and be_azerty:mac (Belgian Apple
keyboards). The files go to /etc/xkb, which libxkbcommon reads first.

%prep
%autosetup -n belgian-azerty-linux-%{version}

%build
# The rules: the system's own (include) followed by exactly the blocks the Debian package's update-xkb-rules writes.
mkdir -p gen; : > gen/evdev.distrib
sed "s|^RULES=.*|RULES=$PWD/gen/evdev|" packaging/belgian-azerty-windows/update-xkb-rules > gen/update-xkb-rules
sh gen/update-xkb-rules
{ echo '// belgian-azerty-windows (openSUSE): the system rules, then our three options. Removed with the package.'
  echo '! include %%S/evdev'; cat gen/evdev; } > gen/evdev.etc

%install
install -Dm644 gen/evdev.etc %{buildroot}%{_sysconfdir}/xkb/rules/evdev
install -Dm644 xkb/symbols/be_capslock %{buildroot}%{_sysconfdir}/xkb/symbols/be_capslock

%check
grep -qx '! include %%S/evdev' %{buildroot}%{_sysconfdir}/xkb/rules/evdev
test "$(grep -c '^// belgian-azerty-windows: ' %{buildroot}%{_sysconfdir}/xkb/rules/evdev)" = 2

%post
# A rules file the user already had in /etc/xkb is kept (rpm puts ours next to it as .rpmnew): say so, because then our
# three options stay unknown until the user adds our lines to their own file.
if [ -f %{_sysconfdir}/xkb/rules/evdev.rpmnew ]; then
  echo "belgian-azerty-windows: /etc/xkb/rules/evdev was already there and is kept. Our rules are in"        "/etc/xkb/rules/evdev.rpmnew: copy its lines into your file, or our options stay unknown." >&2
fi

%files
%license LICENSE
%dir %{_sysconfdir}/xkb
%dir %{_sysconfdir}/xkb/rules
%dir %{_sysconfdir}/xkb/symbols
%config(noreplace) %{_sysconfdir}/xkb/rules/evdev
%config(noreplace) %{_sysconfdir}/xkb/symbols/be_capslock

%changelog
* Tue Nov 03 2026 Younes <linuxbelgiumkeyboard.rc0g4@aleeas.com> - 0.9.12-1
- First openSUSE build (from the Fedora spec): files in /etc/xkb or /etc/keyd only; no be-azerty-fix command yet.
