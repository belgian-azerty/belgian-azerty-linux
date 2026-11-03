# Round two, item 1: GNOME Shell drops every key when ibus answers with an error ("fail open")

3 Nov 2026, 23:00-23:10 Belgian time. Cloud container only (no real login screen, no real hardware). Not yet sent upstream. Evidence: `evidence/raw-logs/2026-11-03-round-two-1-gnome-fail-open/`.

## Kort (Nederlands)
- Op het Zorin-loginscherm (24 Oct) ging elke toets verloren met de melding "Error processing key on IM ... InputContext_2
  bestaat niet". Oorzaak in GNOME Shell: als ibus een fout teruggeeft, schrijft de shell alleen een logregel en gooit de
  toets weg.
- Dat hebben we nu nagebootst op GNOME 46 (Ubuntu 24.04, dezelfde GNOME-versie als Zorin 18; Zorins eigen build zelf niet getest): met de stock shell komt het woord
  "belgique" niet aan (0 van 8 letters). Met de patch van 3 regels komt alles aan, ook snel typen, hoofdletters, é, è en &.
- De patch geldt ook voor de nieuwste GNOME-code (main van 2 Nov 2026): daar zit dezelfde fout.

## What was wrong ✔
`js/misc/inputMethod.js`, `vfunc_filter_key_event()`: GNOME Shell tells Clutter "I took this key" (`return true`) and sends
it to ibus. If ibus answers with an error, the `catch` block only logs `Error processing key on IM` and never calls
`notify_key_event()`, so Clutter never gets the key back. A broken ibus therefore eats every key silently.
- Same code in gnome-46 ✔ (Ubuntu 24.04 package 46.0-0ubuntu6~24.04.17 is byte-identical to upstream gnome-46 ✔) and in
  main (commit 7904014f5b1a, 2026-11-02) ✔.
- Mutter's `clutter_input_method_notify_key_event(im, event, FALSE)` puts a copy of the key back into the event queue,
  marked as already seen by the input method ✔ (mutter gnome-46 `clutter-input-method.c` line 321). So "not filtered" is
  the existing, normal way to let a key through.
- The Zorin login-screen journal (24 Oct, `evidence/raw-logs/installed-run-2026-10-24/boot1-journal.txt` lines 1382-1409)
  shows 51 such errors, all "object does not exist at /org/freedesktop/IBus/InputContext_2" ✔.

## The patch (3 lines of behaviour)
`patches/gnome-shell-main-inputMethod-fail-open.diff` (main) and `patches/gnome-shell-46-inputMethod-fail-open.diff` (46):
on any error other than "cancelled", log as before and then call `this.notify_key_event(event, false)`. The normal path
(ibus answers) is untouched. "Cancelled" keeps today's behaviour (that happens when the shell itself drops the context).

## Test ✔ (headless GNOME Shell 46.0, mutter 46.2, ibus 1.5.29, Ubuntu 24.04 container, Belgian layout)
ibus started by the shell itself (no systemd user service, as on the GDM login screen). Keys sent as physical key codes
through Mutter's RemoteDesktop API into a GTK 4 text box. Patched file loaded with `G_RESOURCE_OVERLAYS` (checked inside
the running shell: "overlay in use: true").

| Phase | What happens | Stock shell typed | Patched shell typed |
|---|---|---|---|
| A | healthy ibus | `azerty` ✔ | `azerty` ✔ |
| B | the shell's ibus input context points at an object that does not exist (the login-screen error, same message) | nothing (19 errors) | `belgique` ✔ (same 19 errors logged) |
| B2 | same, typed fast (5 ms per key event), with Shift, é, è, & | nothing (44 more errors) | `BébéBelgique&Liège` ✔, in order |
| C | ibus-daemon replaced with `-r --xim` (what GNOME Shell does when Xwayland starts) | `clavier` | `clavier` |

Files: `stock/` and `patched/` (result.txt, shell.log, typed.txt), scripts `t1.sh`, `typekeys.py`, `textview.py`, `run1.sh`,
`Dockerfile`, both inputMethod.js copies.

## Honest limits
- Phase B makes the error by hand (a context on a non-existent path). It is the same error class and message as on the
  Zorin login screen ✔, but the real race that produced it (two ibus daemons at the login screen) was **not** reproduced:
  in phase C the replaced daemon simply disconnected the shell (context became null, keys passed) ✔. Why the login
  screen ended up with a dead context stays an inference ✱.
- Not tested: a real GDM login screen, Zorin's own gnome-shell build, an ibus that **hangs** (no answer at all; the patch
  does not cover that), an active input-method engine (Chinese etc.) during the error, GNOME 47-49 at run time (only the
  code was compared).
- After the error the shell keeps the broken context, so every key still makes one failed ibus call (keys arrive, but an
  engine such as Chinese input would stay off until the shell reconnects). A second, larger patch could rebuild the
  context after the first error ✱ (not written; upstream may prefer to discuss that).

## Upstream (later, not now)
- No existing report found for "keys dropped on IM error" (GNOME GitLab API search, 3 Nov ~22:08Z, three searches) ◐.
  The related merge request 813 ("Compare ibus context before processing key event result", merged) is the code this
  patch sits in.
- Form when the time comes: a GNOME Shell merge request with this diff, plus an issue text with the login-screen journal
  lines and this test. Built with AI help (Claude). Not sent yet.
