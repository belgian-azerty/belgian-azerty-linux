#!/usr/bin/python3
"""Check that a system tree has the keyd-team PPA source and that the source's key is the PPA's signing key.
   check-ppa-key.py ROOT FINGERPRINT
Handles both forms: Ubuntu's deb822 file with the key inline (Signed-By: followed by the key block) and Mint's
one-line .list file with signed-by=/etc/apt/keyrings/... . Exit 0 and print the source file(s) when all is well."""
import glob, os, re, subprocess, sys, tempfile

root, fingerprint = sys.argv[1], sys.argv[2].upper()
sources = [f for f in sorted(glob.glob(root + "/etc/apt/sources.list.d/*"))
           if "keyd-team" in open(f, errors="ignore").read()]
if not sources:
    sys.exit("the keyd-team PPA was not added")
for f in sources:
    text = open(f, errors="ignore").read()
    path = re.search(r"signed-by=([^\]\s]+)", text) or re.search(r"^Signed-By:[ \t]*(/\S+)", text, re.M)
    if path:
        keyfile = root + path.group(1)
        if not os.path.isfile(keyfile):
            sys.exit(f"{f[len(root):]} points to {path.group(1)}, which is missing (fetching the key failed)")
        key = open(keyfile, "rb").read()
    else:
        block = re.search(r"^Signed-By:[ \t]*\n((?:[ \t].*(?:\n|$))+)", text, re.M)
        if not block:
            sys.exit(f"{f[len(root):]} has no Signed-By key")
        key = "\n".join("" if l.strip() == "." else l.strip() for l in block.group(1).splitlines()).encode() + b"\n"
    with tempfile.TemporaryDirectory() as home:
        out = subprocess.run(["gpg", "--homedir", home, "--batch", "--show-keys", "--with-colons"],
                             input=key, capture_output=True).stdout.decode()
    if fingerprint not in [l.split(":")[9] for l in out.splitlines() if l.startswith("fpr:")]:
        sys.exit(f"the key for {f[len(root):]} is not the keyd-team signing key {fingerprint}")
    print(f"{f[len(root):]}: key {fingerprint} OK")
