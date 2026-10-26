# results-vscode-097: laptop VS Code ibus-skip run with v3.sh (copy of /root/be-rig/ibus-auto/up-vsc3)

Guest script v3.sh sha256 dea3eb89...; packages 0.9.6 with be-azerty-fix patched 54eda415... -> d4a4988f...

- `mint/`: Mint 22.3 live, 20:37-20:52Z UTC. Complete.
- `zorin/`: Zorin OS 18.1 live, 20:53-21:13Z UTC. Final state: up-vsc3 was watched for 2 minutes (21:14-21:16Z), with no
  new writes and no rig commands running, then VM ba-zor was stopped. Files checked identical to up-vsc3 by sha256.
- Both runs were driven by an earlier session; this pass scored and copied them, it did not re-run them.

Score (blockscore.py "10:ctrlalt-slow,30:ctrlalt-o30,30:altgr-o30,3:dead" + charcount.py on vsc-auto.txt), same for both:
10/10, 30/30, 30/30, 3/3, 0 swapped; 73 lines; @ 560/560, € 560/560, '€€' 0, '@@' 0; dead-key strings 3/3.

Paused step, both distros: `env-paused.txt` lists no processes because in paused mode there is no menu copy to launch;
`env-paused-stock.txt` is the paused check launched from the stock /usr/share/applications entry
(main process im-ibus loaded: 5).
