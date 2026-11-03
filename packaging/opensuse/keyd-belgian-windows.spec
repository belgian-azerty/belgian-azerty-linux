# Ctrl+Alt = AltGr as on Windows, for Belgian keyboards (keyd rules), openSUSE build. keyd itself comes from openSUSE
# (Tumbleweed Oss 2.6.0, Leap 16.0 Backports 2.5.0).
Name:           keyd-belgian-windows
Version:        0.9.12
Release:        1%{?dist}
Summary:        Ctrl+Alt works as AltGr, as on Windows (keyd rules for Belgian keyboards)
License:        MIT
URL:            https://github.com/belgian-azerty/belgian-azerty-linux
Source0:        https://github.com/belgian-azerty/belgian-azerty-linux/archive/refs/tags/v%{version}/belgian-azerty-linux-%{version}.tar.gz
BuildArch:      noarch
Requires:       keyd >= 2.5.0
BuildRequires:  systemd-rpm-macros

%description
keyd rules that make Ctrl+Alt+key arrive as AltGr+key for the 15 keys that
carry an AltGr symbol on the Windows Belgian layout, and AltGr+4/5 give { [
as on Windows. Other Ctrl+Alt shortcuts pass through. Restarts keyd if it
is ever killed.

%prep
%autosetup -n belgian-azerty-linux-%{version}

%install
install -Dm644 keyd/be-winaltgr.conf %{buildroot}%{_sysconfdir}/keyd/be-winaltgr.conf
install -Dm644 packaging/keyd-belgian-windows/belgian-windows-restart.conf \
  %{buildroot}%{_unitdir}/keyd.service.d/belgian-windows-restart.conf

%post
if [ -d /run/systemd/system ]; then
  systemctl daemon-reload >/dev/null 2>&1 || :
  [ "$1" = 1 ] && systemctl enable keyd.service >/dev/null 2>&1 || :
  systemctl restart keyd.service >/dev/null 2>&1 || :
fi
for f in %{_sysconfdir}/keyd/*.conf; do
  [ -f "$f" ] && [ "$f" != %{_sysconfdir}/keyd/be-winaltgr.conf ] || continue
  echo "keyd-belgian-windows: $f exists. keyd uses one configuration per keyboard; put the Belgian rules into your own file, or limit one file under [ids]." >&2
done

%postun
if [ -d /run/systemd/system ]; then
  systemctl daemon-reload >/dev/null 2>&1 || :
  systemctl try-restart keyd.service >/dev/null 2>&1 || :
fi

%files
%license LICENSE
%config(noreplace) %{_sysconfdir}/keyd/be-winaltgr.conf
%dir %{_unitdir}/keyd.service.d
%{_unitdir}/keyd.service.d/belgian-windows-restart.conf

%changelog
* Tue Nov 03 2026 Younes <linuxbelgiumkeyboard.rc0g4@aleeas.com> - 0.9.12-1
- First openSUSE build (from the Fedora spec): files in /etc/xkb or /etc/keyd only; no be-azerty-fix command yet.
