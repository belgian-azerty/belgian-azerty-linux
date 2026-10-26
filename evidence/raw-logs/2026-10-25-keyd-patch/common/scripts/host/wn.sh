# wn.sh FILE SECONDS STAMP: wait until uploads/FILE exists and is newer than STAMP
for i in $(seq $2); do [ /root/be-rig/k94/uploads/$1 -nt $3 ] && exit 0; sleep 1; done; echo "timeout $1"; exit 1
