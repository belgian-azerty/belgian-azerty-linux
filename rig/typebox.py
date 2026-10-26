#!/usr/bin/env python3
"""typebox.py OUT [3|4]: a maximized GTK 3 or 4 window with one text area. Every change of the text is written to
OUT at once; Ctrl+D closes the window. Used to type into a plain GTK app with a chosen input-method setup, e.g.
  GTK_IM_MODULE=simple python3 typebox.py /tmp/out.txt 4      (no ibus for this app)
  IBUS_ENABLE_SYNC_MODE=1 GDK_BACKEND=x11 python3 typebox.py /tmp/out.txt 3   (X11 app with ibus in sync mode)
"""
import sys
import gi
OUT = sys.argv[1]
VER = sys.argv[2] if len(sys.argv) > 2 else "3"
gi.require_version("Gtk", VER + ".0")
from gi.repository import Gtk, GLib


def save(buf):
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(buf.get_text(buf.get_start_iter(), buf.get_end_iter(), True))


if VER == "3":
    from gi.repository import Gdk
    w = Gtk.Window(title="typebox"); tv = Gtk.TextView(); w.add(tv)
    tv.get_buffer().connect("changed", save)
    def key(_w, e):
        if e.keyval in (Gdk.KEY_d, Gdk.KEY_D) and e.state & Gdk.ModifierType.CONTROL_MASK and not e.state & Gdk.ModifierType.MOD1_MASK:
            Gtk.main_quit(); return True
        return False
    w.connect("key-press-event", key); w.connect("destroy", Gtk.main_quit)
    w.maximize(); w.show_all(); tv.grab_focus(); w.present()
    Gtk.main()
else:
    from gi.repository import Gdk
    loop = GLib.MainLoop()
    w = Gtk.Window(title="typebox"); tv = Gtk.TextView(); w.set_child(tv)
    tv.get_buffer().connect("changed", save)
    c = Gtk.EventControllerKey(); c.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
    def key(_c, keyval, _code, state):
        if keyval in (Gdk.KEY_d, Gdk.KEY_D) and state & Gdk.ModifierType.CONTROL_MASK and not state & Gdk.ModifierType.ALT_MASK:
            loop.quit(); return True
        return False
    c.connect("key-pressed", key); w.add_controller(c)
    w.connect("close-request", lambda *_: (loop.quit(), False)[1])
    w.maximize(); w.present(); tv.grab_focus()
    loop.run()
