# Belgian AZERTY like on Windows, openSUSE build (from the Fedora spec). Unlike the Debian
# package, nothing of openSUSE's is touched: the rules and symbols go to /etc/xkb, which libxkbcommon (and so GNOME's
# mutter on Wayland) reads before the system folder. Not read by a pure X11 session or the text console.
Name:           belgian-azerty-windows
Version:        0.9.12
Release:        2%{?dist}
Summary:        Belgian AZERTY like on Windows: Caps Lock, Shift+AltGr accents, Apple option
License:        MIT
URL:            https://github.com/belgian-azerty/belgian-azerty-linux
Source0:        https://github.com/belgian-azerty/belgian-azerty-linux/archive/refs/tags/v%{version}/belgian-azerty-linux-%{version}.tar.gz
BuildArch:      noarch
Requires:       libxkbcommon0 >= 1.0
Requires:       xkeyboard-config
# With SELinux (Fedora; openSUSE's new installs), /etc/xkb must get the label of the system's own keyboard files, or
# confined programs such as systemd-localed cannot read it (localectl then refuses every layout): see %%post.
Requires(post): (policycoreutils if selinux-policy-targeted)
Requires(postun): (policycoreutils if selinux-policy-targeted)

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
# the SELinux label for /etc/xkb (same text as packaging/selinux/belgian_azerty_xkb.cil in the repository; written
# here because the release source archive this builds from does not have that file yet)
install -d %{buildroot}%{_datadir}/selinux/packages/%{name}
cat > %{buildroot}%{_datadir}/selinux/packages/%{name}/belgian_azerty_xkb.cil <<'CIL'
; belgian-azerty-windows: /etc/xkb (our Caps Lock and rules files) gets usr_t, the label the system's own keyboard
; files in /usr/share/X11/xkb have, so that confined programs such as systemd-localed may read it as they read those.
(filecon "/etc/xkb(/.*)?" any (system_u object_r usr_t ((s0) (s0))))
CIL

%check
grep -qx '! include %%S/evdev' %{buildroot}%{_sysconfdir}/xkb/rules/evdev
test "$(grep -c '^// belgian-azerty-windows: ' %{buildroot}%{_sysconfdir}/xkb/rules/evdev)" = 2

%post
# A rules file the user already had in /etc/xkb is kept (rpm puts ours next to it as .rpmnew): say so, because then our
# three options stay unknown until the user adds our lines to their own file.
if [ -f %{_sysconfdir}/xkb/rules/evdev.rpmnew ]; then
  echo "belgian-azerty-windows: /etc/xkb/rules/evdev was already there and is kept. Our rules are in"        "/etc/xkb/rules/evdev.rpmnew: copy its lines into your file, or our options stay unknown." >&2
fi
# SELinux: give /etc/xkb the label usr_t (as /usr/share/X11/xkb). Installed whenever a policy is present, so that it
# also holds if SELinux is switched on later; never fails the installation.
if [ -e %{_sysconfdir}/selinux/config ] && command -v semodule >/dev/null 2>&1; then
  semodule -i %{_datadir}/selinux/packages/%{name}/belgian_azerty_xkb.cil >/dev/null 2>&1 || echo "belgian-azerty-windows: could not add the SELinux label for /etc/xkb (semodule failed)" >&2
  command -v restorecon >/dev/null 2>&1 && restorecon -R %{_sysconfdir}/xkb >/dev/null 2>&1 || :
fi

%postun
# removal (not an update): take the SELinux label module out again
if [ "$1" = 0 ] && command -v semodule >/dev/null 2>&1 && semodule -l 2>/dev/null | grep -qx belgian_azerty_xkb; then
  semodule -r belgian_azerty_xkb >/dev/null 2>&1 || :
fi

%files
%license LICENSE
%dir %{_sysconfdir}/xkb
%dir %{_sysconfdir}/xkb/rules
%dir %{_sysconfdir}/xkb/symbols
%config(noreplace) %{_sysconfdir}/xkb/rules/evdev
%config(noreplace) %{_sysconfdir}/xkb/symbols/be_capslock
%dir %{_datadir}/selinux
%dir %{_datadir}/selinux/packages
%{_datadir}/selinux/packages/%{name}

%changelog
* Wed Nov 04 2026 Younes <linuxbelgiumkeyboard.rc0g4@aleeas.com> - 0.9.12-2
- SELinux: /etc/xkb gets the label usr_t (small file-context module, added on install, removed with the package).
  Without it systemd-localed may not read our rules file and localectl refuses every layout (openSUSE, enforcing).

* Tue Nov 03 2026 Younes <linuxbelgiumkeyboard.rc0g4@aleeas.com> - 0.9.12-1
- First openSUSE build (from the Fedora spec): files in /etc/xkb or /etc/keyd only; no be-azerty-fix command yet.
