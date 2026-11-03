# keyd for Fedora, built by the Belgian AZERTY project from the official keyd release (github.com/rvaiya/keyd, tag
# v2.6.0, MIT). Fedora has no keyd package of its own. Nothing patched.
Name:           keyd
Version:        2.6.0
Release:        1.belgianazerty%{?dist}
Summary:        Key remapping daemon for Linux (evdev, uinput)
License:        MIT
URL:            https://github.com/rvaiya/keyd
Source0:        https://github.com/rvaiya/keyd/archive/refs/tags/v%{version}/keyd-%{version}.tar.gz

BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  kernel-headers
BuildRequires:  systemd-rpm-macros

%description
keyd remaps keys at the kernel input level (evdev, uinput), so the result works
the same in X11, Wayland, the text console and the login screen. Built
unchanged from the official keyd release.

%prep
%autosetup

%build
# keyd appends the environment CFLAGS to its own (on the command line they would replace them)
CFLAGS="%{build_cflags}" LDFLAGS="%{build_ldflags}" %make_build PREFIX=%{_prefix}

%install
%make_install PREFIX=%{_prefix} FORCE_SYSTEMD=1
mkdir -p %{buildroot}%{_sysconfdir}/keyd

%check
test "$(%{buildroot}%{_bindir}/keyd --version)" = "keyd v%{version} ()"

%post
%systemd_post keyd.service

%preun
%systemd_preun keyd.service

%postun
%systemd_postun_with_restart keyd.service

%files
%license LICENSE
%{_bindir}/keyd
%{_bindir}/keyd-application-mapper
%{_datadir}/keyd
%{_docdir}/keyd
%{_mandir}/man1/keyd.1*
%{_mandir}/man1/keyd-application-mapper.1*
%{_unitdir}/keyd.service
%{_sysusersdir}/keyd.conf
%dir %{_sysconfdir}/keyd

%changelog
* Mon Nov 02 2026 Younes <linuxbelgiumkeyboard.rc0g4@aleeas.com> - 2.6.0-1.belgianazerty
- First build for Fedora from the official keyd 2.6.0 release, unchanged.
