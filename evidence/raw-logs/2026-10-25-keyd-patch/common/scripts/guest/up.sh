#!/bin/bash
# up.sh FILE [NAME]: send a file to the host upload sink
wget -q --post-file="$1" "http://10.0.2.2:8011/${2:-$(basename "$1")}" -O /dev/null && echo "uploaded ${2:-$(basename "$1")}"
