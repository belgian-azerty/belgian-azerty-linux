# wf.sh FILE SECONDS: wait for an upload
for i in $(seq $2); do [ -e /root/be-rig/k94/uploads/$1 ] && exit 0; sleep 1; done; echo "timeout $1"; exit 1
