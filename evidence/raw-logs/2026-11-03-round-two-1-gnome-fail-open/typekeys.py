# Tap physical keys (evdev codes) through Mutter RemoteDesktop. Arg: word typed on a Belgian AZERTY keyboard (a-z only), then Return.
import dbus, sys, time
BE={'a':16,'z':17,'e':18,'r':19,'t':20,'y':21,'u':22,'i':23,'o':24,'p':25,'q':30,'s':31,'d':32,'f':33,'g':34,'h':35,'j':36,'k':37,'l':38,'m':39,'w':44,'x':45,'c':46,'v':47,'b':48,'n':49,'&':2,'é':3,'è':8}
bus=dbus.SessionBus()
rd=bus.get_object('org.gnome.Mutter.RemoteDesktop','/org/gnome/Mutter/RemoteDesktop')
path=dbus.Interface(rd,'org.gnome.Mutter.RemoteDesktop').CreateSession()
s=dbus.Interface(bus.get_object('org.gnome.Mutter.RemoteDesktop',path),'org.gnome.Mutter.RemoteDesktop.Session')
s.Start(); time.sleep(0.5)
D=float(sys.argv[2]) if len(sys.argv)>2 else 0.05
def k(c,d): s.NotifyKeyboardKeycode(dbus.UInt32(c),d); time.sleep(D)
def tap(c): k(c,True); k(c,False)
tap(42)  # warm-up: Shift alone; the first key of a new RemoteDesktop session can be lost
for ch in sys.argv[1]:
    if ch.isupper(): k(42,True); tap(BE[ch.lower()]); k(42,False)
    else: tap(BE[ch])
tap(28); time.sleep(0.8); s.Stop()
