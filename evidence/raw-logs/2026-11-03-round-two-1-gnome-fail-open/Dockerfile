ARG BASE
FROM ${BASE}
ARG EXTRA=""
# Optional: behind a TLS proxy, copy its CA certificate here first:
# COPY proxy-ca.crt /usr/local/share/ca-certificates/proxy-ca.crt
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    ca-certificates systemd systemd-sysv dbus dbus-user-session sudo libglib2.0-bin dconf-gsettings-backend dconf-cli \
    gsettings-desktop-schemas cinnamon-desktop-data libgnomekbd-common ibus keyboard-configuration console-setup \
    gpg-agent python3 xkb-data libxkbcommon-tools python3-pip python3-cffi python3-dev pkg-config libxkbcommon-dev \
    build-essential initramfs-tools gnome-shell gnome-settings-daemon python3-gi python3-dbus gir1.2-gtk-4.0 xauth \
    libgl1-mesa-dri locales $EXTRA >/tmp/apt.log 2>&1; rc=$?; tail -5 /tmp/apt.log; update-ca-certificates >/dev/null; \
    sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen 2>/dev/null; locale-gen en_US.UTF-8 >/dev/null 2>&1; exit $rc
RUN pip install --break-system-packages -q xkbcommon==1.5.1 2>&1 | tail -2; python3 -c "import xkbcommon; print('xkbcommon ok')"
CMD ["/sbin/init"]
