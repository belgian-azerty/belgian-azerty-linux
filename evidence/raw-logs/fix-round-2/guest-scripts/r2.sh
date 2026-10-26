#!/bin/bash
# r2.sh LABEL: fix round 2 checks in a live session (packages 0.9.1 already installed): R2-5 session detection under
# sudo, R2-4 rerun keeps Comma, R2-6 systemctl stop keyd ends inactive. Output: /tmp/r2-LABEL.txt, uploaded.
L=$1; O=/tmp/r2-$L.txt; up() { wget -q --post-file="$1" "http://10.0.2.2:8001/$(basename "$1")" -O /dev/null; }
dec() { case ",$(. /etc/default/keyboard; echo "$XKBOPTIONS")," in *,kpdl:comma,*) echo comma ;; *) echo period ;; esac; }
{
echo "=== r2 $L $(date -u +%FT%TZ) $(lsb_release -ds) session=$XDG_SESSION_TYPE"
dpkg-query -W belgian-azerty-windows keyd-belgian-windows keyd
echo "--- sudo be-azerty-fix system (no DECIMAL/CAPS)"; sudo be-azerty-fix system 2>&1; echo "rc=$? decimal=$(dec)"
echo "--- under sudo, logind says: $(sudo sh -c 'loginctl show-session $(loginctl show-user '"$USER"' -p Display --value) -p Type --value'), sudo env XDG_SESSION_TYPE=$(sudo sh -c 'echo ${XDG_SESSION_TYPE:-unset}')"
echo "--- sudo DECIMAL=comma be-azerty-fix system"; sudo DECIMAL=comma be-azerty-fix system 2>&1 | grep -E 'Choices|options|decimal'; echo "decimal=$(dec)"
echo "--- rerun without DECIMAL (must keep comma)"; sudo be-azerty-fix system 2>&1 | grep -E 'Choices|options|decimal|setxkbmap|Xwayland|WARNING'; echo "decimal=$(dec)"
echo "--- saved choices: $(cat /var/lib/belgian-azerty-windows/choices | tr '\n' ' ')"
echo "--- systemctl stop keyd"; sudo systemctl stop keyd; echo "after stop: $(systemctl is-active keyd) result=$(systemctl show keyd -p Result --value)"
sudo systemctl start keyd; sleep 2; echo "after start: $(systemctl is-active keyd)"
P1=$(pidof keyd.rvaiya); sudo kill "$P1"; sleep 4; echo "after plain kill (SIGTERM) of $P1: $(systemctl is-active keyd), new pid $(pidof keyd.rvaiya)"
cat /usr/lib/systemd/system/keyd.service.d/belgian-windows-restart.conf | grep -v '^#'
echo "--- be-azerty-fix check"; be-azerty-fix check 2>&1
} > "$O" 2>&1
up "$O"; echo "r2 done: $O"
