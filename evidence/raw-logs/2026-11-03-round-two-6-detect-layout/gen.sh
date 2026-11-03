#!/bin/bash
# $1 = variant dir name under /tmp (km$1), $2 = output tree, $3 = optional -u list
cd /tmp/cs/Keyboard; U=${3:-$(grep -v "^#" keymaptree.use | xargs | sed "s/ /,/g")}
SECONDS=0; PYTHONPATH=/tmp/km$1 gen_keymap -o $2 -v -I tree-keymaps/pc105 -u $U tree-keymaps/pc105.list > /tmp/gk$1.log 2>&1; rc=$?
echo "$1 rc=$rc ${SECONDS}s $(grep -c ^MAP $2 2>/dev/null) maps, FIND $(grep -c "^FIND " $2 2>/dev/null), FINDP $(grep -c ^FINDP $2 2>/dev/null), steps $(grep -c ^STEP $2 2>/dev/null)"
[ $rc = 0 ] || tail -2 /tmp/gk$1.log | cut -c1-200
