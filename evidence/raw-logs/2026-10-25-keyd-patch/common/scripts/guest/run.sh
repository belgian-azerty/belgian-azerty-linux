#!/bin/bash
# run.sh LABEL CMD...: run CMD, keep its output and exit code in /tmp/k/LABEL.txt, upload it
L=$1; shift
{ echo "== $(date -u +%FT%TZ) $*"; "$@"; echo "exit $?"; } > /tmp/k/$L.txt 2>&1
wget -q --post-file=/tmp/k/$L.txt http://10.0.2.2:8011/$L.txt -O /dev/null
clear; sed 's/\x1b\[[0-9;]*m//g' /tmp/k/$L.txt | tail -15
