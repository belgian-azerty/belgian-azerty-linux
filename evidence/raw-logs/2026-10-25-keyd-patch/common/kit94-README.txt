Kit for "Ship the keyd Ctrl+Alt patch in 0.9.4" (2026-10-25, Younes's go 2026-10-24 23:41Z: build in the cloud, test on the laptop).

dist/        the 0.9.4 packages under test, expected sha256:
  946cc443bf5c355ec8383765c6a1696d9001fbccc9f0d5062dc90dd835540468  keyd_2.5.0-5~ubuntu24.04.2_amd64.deb   (Debian keyd 2.5.0-5 + our patch 0012)
  f9de04365e1c601a82101f3e29e3f624d9dfeedb629a564ed4222405dd33589c  keyd-belgian-windows_0.9.4_all.deb
  6e50c62f8e6414cd94f1496652e2f642e25c786005d1cceec49e42b3f7b880da  belgian-azerty-windows_0.9.4_all.deb
dist-0.9.3/  the previous release, only for the upgrade test on Mint:
  4067e4cd92cb0693fb0bfa17dc592b1d4c255cda4288af8d1cdf65b86b3c3e67  keyd_2.5.0-5~ubuntu24.04.1_amd64.deb
  7f3c70248a95612a572d13ccd018827d9afda4df34620ad0e4f214f3354fc369  keyd-belgian-windows_0.9.3_all.deb
  62ddfe6a602bcc67f452cf6edb5c404f35b9d86fa6e8dfb156a04ea1c19716be  belgian-azerty-windows_0.9.3_all.deb
be-azerty-fix.sh   sha256 6d6b3d923b5b903366a71dc1420c421a68cd56a4c6c58dd714476457fbaae941 (same script as in the package)
0012-...patch      the patch inside the keyd package (for reference)
rig/         current cloud copy of the rig (qemu_rig.py, keylog.py, upload_server.py ...). The fast-typing tool
             rig/swaptest.py is NOT in here: use the one in the laptop git folder (rig/swaptest.py, swap thread).
guest/       guest helpers from the extra-tests kit: p.sh NAME (probe), t.sh NAME (typing capture until Ctrl+D),
             up.sh FILE NAME (send a file to the host), seq.txt (QEMU key sequence). Serve guest/ and dist*/ over
             http on 127.0.0.1:8000 and run rig/upload_server.py on 8001.

seq.txt typed into t.sh must give exactly:   |@#{[^{}€[]\ |@#{[^{}€[]\ 12 &é
  (12 Ctrl+Alt symbols, space, the same 12 with AltGr, space, Caps Lock on + 1 2 + Caps Lock off = "12", space, 1 2 = "&é")

Held-Ctrl+Alt line (the case the patch changes): hold Ctrl+Alt the whole time and press 2, E, 2, E ... 8 pairs,
120 ms from one key press to the next, no overlap. Expected: @€@€@€@€@€@€@€@€ . With rig/keylog.py running in the
guest, keyd's output should show AltGr (rightalt) down once, then only 2 down/up and E down/up, no Ctrl/Alt events
between the keys (2 events per character).
