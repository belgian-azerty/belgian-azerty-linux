Belgian AZERTY real-hardware test (written for test build 0.9.1; the full guide is T14S-TEST-PLAN.md)

Before you start, put the three packages from dist/ and be-azerty-fix.sh in this folder, next to run-test.sh.

1. Start the laptop from the Belgian Zorin USB stick and take the first menu entry. Let the disc check finish.
2. On the Zorin desktop press Ctrl+Alt+T and type:

       bash /cdrom/t14s-test/run-test.sh

3. Follow what it says. It does everything else by itself (about 25 minutes; your part is typing short lines).
4. At the end it tells you where the results file is: belgian-t14s-results.txt, on the desktop and in this folder.
   Take that one file back to Windows and send it with your test report.

Stopped in the middle? Run the same command again: it carries on where it stopped.
