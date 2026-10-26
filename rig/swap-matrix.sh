#!/bin/bash
# swap-matrix.sh VM PREFIX N [BLOCK...]: run fast-typing order blocks one after the other (see swap-run.sh).
# A block is LABEL:KEYD:IBUS:PATTERN:GAP[:roll|-[:APP]] where APP is e.g. box4+GTK_IM_MODULE=simple (+ = space).
# Without blocks, the standard set below runs.
cd "$(dirname "$0")"
VM=$1; PFX=$2; N=$3; shift 3
STD="on-ag120:on:on:altgr:120 on-ag60:on:on:altgr:60 on-ag30r:on:on:altgr:30:roll
on-ca120:on:on:ctrlalt:120 on-ca60:on:on:ctrlalt:60 on-ca30r:on:on:ctrlalt:30:roll
on-ag1-60:on:on:altgr1:60 on-ca1-60:on:on:ctrlalt1:60 on-pl30r:on:on:plain:30:roll on-mx60:on:on:mixed:60
off-ag120:off:on:altgr:120 off-ag60:off:on:altgr:60 off-ag30r:off:on:altgr:30:roll
off-ag1-60:off:on:altgr1:60 off-pl30r:off:on:plain:30:roll off-mx60:off:on:mixed:60
noibus-ca60:on:off:ctrlalt:60 noibus-ag30r:on:off:altgr:30:roll noibus-ag60:on:off:altgr:60"
BLOCKS=${*:-$STD}
for b in $BLOCKS; do
  IFS=: read -r L K I P G R A <<< "$b"
  [ "$R" = roll ] && R=--roll || R=
  APP=${A//+/ } bash swap-run.sh "$VM" "$PFX-$L" "$K" "$I" "$P" "$N" "$G" $R || echo "BLOCK FAILED: $PFX-$L"
  sleep 2
done
# leave the guest as it was found: keyd on, ibus on
bash swap-run.sh "$VM" "$PFX-restore" on on altgr 1 120 > /dev/null
