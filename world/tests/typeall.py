# Type a whole plan (every key, every state, dead-key sequences) into GNOME Shell via Mutter RemoteDesktop; Return after each cell
import dbus, sys, time, json
plan=json.load(open(sys.argv[1]))
bus=dbus.SessionBus()
rd=bus.get_object('org.gnome.Mutter.RemoteDesktop','/org/gnome/Mutter/RemoteDesktop')
path=dbus.Interface(rd,'org.gnome.Mutter.RemoteDesktop').CreateSession()
s=dbus.Interface(bus.get_object('org.gnome.Mutter.RemoteDesktop',path),'org.gnome.Mutter.RemoteDesktop.Session')
s.Start(); time.sleep(0.5)
D=float(sys.argv[2]) if len(sys.argv)>2 else 0.01
def k(code,down): s.NotifyKeyboardKeycode(dbus.UInt32(code),down); time.sleep(D)
def tap(code): k(code,True); k(code,False)
tap(57); tap(14)  # warm-up: the very first key after start can be lost
for c in plan['cells']:
    for sc,mods,caps in c['presses']:
        if caps: tap(58)
        for m in mods: k(m,True)
        tap(sc)
        for m in reversed(mods): k(m,False)
        if caps: tap(58)
    tap(28)
time.sleep(0.5); s.Stop()
