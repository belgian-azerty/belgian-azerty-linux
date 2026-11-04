#!/bin/bash
# Cinnamon (Linux Mint) layout lookup: does CinnamonDesktop.XkbInfo, which Cinnamon's keyboard settings use, find
# every layout of world/layouts.tsv? Before install (none), after install (all), after removal (none).
# DISPOSABLE Ubuntu 24.04 container, as root:  world/tests/cinnamon-lookup.sh WORLD_DEB REPO_DIR
# This is the lookup only, not a Cinnamon session.
export DEBIAN_FRONTEND=noninteractive; WO=$(realpath "$1"); REPO=$(realpath "$2")
apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq --no-install-recommends gjs gir1.2-cinnamondesktop-3.0 gsettings-desktop-schemas cinnamon-desktop-data xvfb xauth >/dev/null 2>&1; dpkg-query -W gir1.2-cinnamondesktop-3.0 gjs
IDS=$(tail -n +2 "$REPO/world/layouts.tsv" | awk -F'\t' '{id=($5=="basic")?$4:$4"+"$5; printf "%s\"%s\"", (NR>1?",":""), id}')
J='imports.gi.versions.Gtk="3.0"; imports.gi.Gtk.init(null); const C=imports.gi.CinnamonDesktop; const x=(C.XkbInfo.new_with_extras ? C.XkbInfo.new_with_extras() : C.XkbInfo.new()); let n=0; const ids=["be",'"$IDS"']; for (const id of ids) { const r=x.get_layout_info(id); if (r[0]) n++; print(id+": found="+r[0]+" name="+r[1]+" layout="+r[3]+" variant="+r[4]); } print("FOUND "+n+" of "+ids.length);'
echo "== before our package"; xvfb-run -a gjs -c "$J" 2>&1 | grep -v Gtk-WARNING | grep "FOUND\|^be:"
apt-get install -y -qq "$WO" >/dev/null 2>&1
echo "== after our package"; xvfb-run -a gjs -c "$J" 2>&1 | grep -v Gtk-WARNING
apt-get remove -y -qq world-keyboard-windows >/dev/null 2>&1
echo "== after removal"; xvfb-run -a gjs -c "$J" 2>&1 | grep -v Gtk-WARNING | grep "FOUND\|^be:"
