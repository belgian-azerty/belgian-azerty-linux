#!/bin/bash
# Read-only: openSUSE Tumbleweed and Leap 16.0 ISO names and sizes.
sz() { curl -sIL "$1" | grep -i '^content-length' | tail -1 | tr -d '\r'; }
echo "== Tumbleweed"
curl -sL https://download.opensuse.org/tumbleweed/iso/ | grep -oE 'href="[^"]*(Live|DVD|NET)[^"]*Current\.iso"' | sed 's/href="//;s/"$//' | sort -u | while read f; do echo "$f $(sz https://download.opensuse.org/tumbleweed/iso/$f)"; done
echo "== Leap 16.0"
curl -sL https://download.opensuse.org/distribution/leap/16.0/ | grep -oE 'href="[^"]+/"' | head -20 | tr '\n' ' '; echo
for d in offline installer iso; do curl -sL https://download.opensuse.org/distribution/leap/16.0/$d/ | grep -oE 'href="[^"]*\.iso"' | sed 's/href="//;s/"$//' | sort -u | while read f; do echo "$d/$f $(sz https://download.opensuse.org/distribution/leap/16.0/$d/$f)"; done; done
