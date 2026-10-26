#!/bin/bash
# get.sh: fetch the k94 kit files from the host into /tmp/k (debs in d93/ d94/) and check their hashes
mkdir -p /tmp/k/d93 /tmp/k/d94; cd /tmp/k
U=http://10.0.2.2:8010
for f in p.sh t.sh up.sh stick-probe.sh seq.txt seq8.txt keylog.py be-azerty-fix.sh s1.sh hl.sh sc.sh k7.sh st.sh run.sh sums.txt; do
  wget -q "$U/$f" -O "$f" || echo "FAILED $f"
done
for f in d93/keyd_2.5.0-5~ubuntu24.04.1_amd64.deb d93/keyd-belgian-windows_0.9.3_all.deb d93/belgian-azerty-windows_0.9.3_all.deb \
         d94/keyd_2.5.0-5~ubuntu24.04.2_amd64.deb d94/keyd-belgian-windows_0.9.4_all.deb d94/belgian-azerty-windows_0.9.4_all.deb; do
  wget -q "$U/$f" -O "$f" || echo "FAILED $f"
done
cp p.sh t.sh up.sh stick-probe.sh keylog.py /tmp/
sha256sum -c sums.txt 2>&1 | tee /tmp/k/get-check.txt | grep -v ': OK$'
echo "get.sh: $(grep -c ': OK$' /tmp/k/get-check.txt) files OK"
wget -q --post-file=/tmp/k/get-check.txt "http://10.0.2.2:8011/$(hostname)-get-check.txt" -O /dev/null
