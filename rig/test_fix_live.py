import subprocess, time
VM = "mate"
def rig(*a): return subprocess.run(["python3", "qemu_rig.py", *a], capture_output=True, text=True).stdout
def keys(s, d="0.4"): rig("keys", VM, s, "--delay", d)
def typ(mode, text): rig("type", VM, text, "--as", mode, "--delay", "0.12")
def shot(n): rig("shot", VM, f"fix-{n}.png"); print("shot", n, flush=True)

keys("esc"); time.sleep(4)
keys("ctrl-alt-t"); time.sleep(40); shot("1-terminal")
# session is US at this point, so type commands on US positions
typ("us", "wget -q http://10.0.2.2:8000/be-azerty-fix.sh && bash be-azerty-fix.sh check\n"); time.sleep(20); shot("2-check-before")
typ("us", "clear; bash be-azerty-fix.sh live\n"); time.sleep(15); shot("3-live")
# now the session should be Belgian: type on Belgian positions
typ("be", "clear; setxkbmap -query; echo azerty 123 'é@#{}[]|' \n"); time.sleep(10); shot("4-after")
