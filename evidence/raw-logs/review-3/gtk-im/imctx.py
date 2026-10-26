import sys, gi
v = sys.argv[1]
gi.require_version('Gtk', v + '.0')
from gi.repository import Gtk
if v == '3':
    Gtk.init([])
else:
    Gtk.init()
c = Gtk.IMMulticontext()
w = Gtk.Window()
if v == '3':
    w.show_all(); c.set_client_window(w.get_window())
else:
    w.present(); c.set_client_widget(w)
c.focus_in()
print("gtk", v, "context =", c.get_context_id())
