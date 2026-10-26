#!/bin/bash
# t14line.sh VM ctrlalt|altgr N : type N lines of 8 x @€ with the given modifier, Enter after each
R="python3 $(dirname "$0")/rig/qemu_rig.py"
case $2 in ctrlalt) P="ctrl-alt-2 ctrl-alt-e" ;; altgr) P="alt_r-2 alt_r-e" ;; esac
for ((i=0;i<$3;i++)); do $R keys $1 "$P $P $P $P $P $P $P $P ret" --delay ${DELAY:-0.15} >/dev/null; done
