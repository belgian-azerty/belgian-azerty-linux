# GTK 4 window with a multi-line text box; every change is written to /tmp/typed.txt
import gi; gi.require_version('Gtk','4.0'); from gi.repository import Gtk
def act(app):
    w=Gtk.ApplicationWindow(application=app); v=Gtk.TextView(); w.set_child(v); b=v.get_buffer()
    b.connect('changed',lambda x: open('/tmp/typed.txt','w').write(x.get_text(x.get_start_iter(),x.get_end_iter(),True)))
    w.present(); v.grab_focus()
a=Gtk.Application(application_id='be.test.Text'); a.connect('activate',act); a.run(None)
