#!/usr/bin/env python3
"""Bare GTK 3 or GTK 4 text window for the ibus-skip test (written again for 0.9.5; the swap thread's typebox.py stayed
on the laptop). Every line typed and ended with Enter is appended to OUT. OUT.info gets, once the window has focus:
the pid, the GTK version, GTK_IM_MODULE as the app sees it, which input-method module GTK picked (context id of a
fresh IMMulticontext), and whether an ibus module library is loaded in the process.
    typebox.py --gtk 3|4 --out /tmp/tb.txt
"""
import argparse, os, sys
p = argparse.ArgumentParser(); p.add_argument("--gtk", default="4"); p.add_argument("--out", required=True)
a = p.parse_args()
import gi
gi.require_version("Gtk", a.gtk + ".0")
from gi.repository import Gtk, GLib


def info(win):
    m = Gtk.IMMulticontext()
    if a.gtk == "3":
        m.set_client_window(win.get_window()); m.focus_in()
    ctx = m.get_context_id()
    maps = open("/proc/self/maps").read()
    with open(a.out + ".info", "w") as f:
        f.write(f"pid={os.getpid()} gtk={a.gtk} GTK_IM_MODULE={os.environ.get('GTK_IM_MODULE', '(unset)')} "
                f"context={ctx} ibus_module_loaded={'im-ibus' in maps} session={os.environ.get('XDG_SESSION_TYPE')}\n")
    return False


def activate(entry):
    with open(a.out, "a") as f:
        f.write(entry.get_text() + "\n")
    entry.set_text("")


if a.gtk == "3":
    Gtk.init([])
    w = Gtk.Window(title="Typebox"); w.set_default_size(900, 120)
    e = Gtk.Entry(); w.add(e); e.connect("activate", activate); w.connect("destroy", Gtk.main_quit)
    w.show_all(); e.grab_focus(); GLib.timeout_add(1500, info, w)
    Gtk.main()
else:
    loop = GLib.MainLoop()
    w = Gtk.Window(title="Typebox"); w.set_default_size(900, 120)
    e = Gtk.Entry(); w.set_child(e); e.connect("activate", activate); w.connect("close-request", lambda *_: loop.quit())
    w.present(); e.grab_focus(); GLib.timeout_add(1500, info, w)
    loop.run()
