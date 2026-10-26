#!/usr/bin/env python3
"""Tiny upload sink for the QEMU guests: PUT/POST http://10.0.2.2:8001/<name> stores the body under ./uploads/<name>.
Guest side:  wget -q --post-file=/tmp/x.txt http://10.0.2.2:8001/x.txt   or   curl -T /tmp/x.txt http://10.0.2.2:8001/x.txt
"""
import os, sys
from http.server import BaseHTTPRequestHandler, HTTPServer

DEST = sys.argv[1] if len(sys.argv) > 1 else "uploads"
os.makedirs(DEST, exist_ok=True)


class H(BaseHTTPRequestHandler):
    def _save(self):
        n = int(self.headers.get("Content-Length", "0"))
        name = os.path.basename(self.path.split("?")[0]) or "upload.bin"
        with open(os.path.join(DEST, name), "wb") as f:
            f.write(self.rfile.read(n))
        self.send_response(200); self.end_headers(); self.wfile.write(b"ok\n")
        print("saved", name, n, "bytes", flush=True)

    do_PUT = _save
    do_POST = _save


HTTPServer(("127.0.0.1", 8011), H).serve_forever()
