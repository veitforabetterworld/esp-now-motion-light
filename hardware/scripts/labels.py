# Bestueckungsdruck NUR auf der Unterseite (B.SilkS), Platinenkoordinaten in mm.
# Die Oberseite bleibt ohne Druck. Jedes Bauteil ist mit Symbol und Wert eingezeichnet,
# so dass die Platine allein anhand des Drucks bestueckt werden kann. Alle Umrisse liegen
# an der echten Bauteilposition (von unten gesehen also spiegelbildlich zur Oberseite).
import math
SB = pcbnew.B_SilkS
LW = 0.15                         # Linienbreite Druck

# (Footprint-Druck wird schon beim Laden entfernt: ohne_druck() in gen_pcb.py)

def ln(a, b, w=LW):
    seg(SB, a, b, w)

def rect(x0, y0, x1, y1, w=LW):
    for a, b in (((x0, y0), (x1, y0)), ((x1, y0), (x1, y1)), ((x1, y1), (x0, y1)), ((x0, y1), (x0, y0))):
        ln(a, b, w)

def circle(cx, cy, r, w=LW, fill=False):
    s = pcbnew.PCB_SHAPE(board)
    s.SetShape(pcbnew.SHAPE_T_CIRCLE)
    s.SetCenter(P(cx, cy)); s.SetEnd(P(cx + r, cy))
    s.SetLayer(SB); s.SetWidth(mm(w)); s.SetFilled(fill)
    board.Add(s)

def poly(pts, w=0.05):
    s = pcbnew.PCB_SHAPE(board)
    s.SetShape(pcbnew.SHAPE_T_POLY)
    s.SetPolyPoints([P(*p) for p in pts])
    s.SetLayer(SB); s.SetWidth(mm(w)); s.SetFilled(True)
    board.Add(s)

def tb(s, x, y, size=0.8, angle=0, bold=False):
    text(s, x, y, size, layer=SB, bold=bold, angle=angle)

def widerstand(ref, x, ya, yb, wert):
    """Widerstand liegend, senkrecht zwischen den Pads (ya < yb): Draht - Koerper mit Wert - Draht"""
    k0, k1 = ya + 1.6, yb - 1.6
    ln((x, ya + 1.0), (x, k0)); ln((x, k1), (x, yb - 1.0))
    rect(x - 1.0, k0, x + 1.0, k1)
    tb(wert, x, (k0 + k1) / 2, 0.8, angle=90)
    tb(ref, x - 1.75, (k0 + k1) / 2, 0.8, angle=90)

# ---------- Titel und D1 mini ----------
tb('FUNKLICHT v1.2', 14.23, 2.2, 1.0, bold=True)
tb('WEMOS D1 mini', 14.23, 4.4, 0.8)
tb('Antenne hier', 14.23, 6.1, 0.8)
rect(1.4, 7.6, 4.2, 28.18)        # Buchsenleisten 1x8 (Pin 1 = RST oben links)
rect(24.26, 7.6, 27.06, 28.18)
poly([(0.35, 8.4), (0.35, 9.6), (1.1, 9.0)])   # Pin-1-Markierung
tb('RST', 5.7, 9.0, 0.8)

# ---------- Widerstaende ----------
widerstand('R2', 16.77, 10.27, 20.43, '10kΩ')
widerstand('R1', 21.85, 17.89, 28.05, '220Ω')

# ---------- Diode 1N4007 (Kathode = Ring = Pad 1 unten) ----------
x = 9.15
rect(x - 1.2, 24.6, x + 1.2, 31.5)
for dy in (0.0, 0.2, 0.4):                      # Kathodenring
    ln((x - 1.2, 30.4 + dy), (x + 1.2, 30.4 + dy))
poly([(x - 0.75, 26.4), (x + 0.75, 26.4), (x, 28.0)])   # Diodensymbol: Pfeil zur Kathode
ln((x - 0.75, 28.05), (x + 0.75, 28.05))
tb('1N4007', 6.45, 28.05, 0.8, angle=90)

# ---------- C1 1 uF Keramik ----------
x = 14.0
ln((x - 0.9, 31.7), (x + 0.9, 31.7)); ln((x - 0.9, 32.06), (x + 0.9, 32.06))   # Kondensatorsymbol
ln((x - 1.05, 30.0), (x - 1.05, 33.76)); ln((x + 1.05, 30.0), (x + 1.05, 33.76))
tb('1µF', x, 34.75, 0.8)

# ---------- C2 10 uF Elko (+ = Pad 1 rechts, Minusstreifen links) ----------
cx, cy, r = 15.52, 25.51, 2.6
circle(cx, cy, r)
ln((18.55, 27.2), (19.45, 27.2)); ln((19.0, 26.75), (19.0, 27.65))   # Plus (Pad 1, eckig)
ln((11.6, 27.2), (12.5, 27.2))                                         # Minus (Streifen am Elko)
tb('10µF 16V', cx, 29.1, 0.8)

# ---------- L7805 und IRLB8721 (TO-220 stehend, Doppellinie = Kuehlfahne/Rueckseite) ----------
rect(16.74, 35.59, 26.96, 40.2)
ln((16.74, 36.97), (26.96, 36.97))
tb('L7805', 21.85, 36.28, 0.8, bold=True)
rect(16.74, 40.66, 26.96, 45.28)
ln((16.74, 43.9), (26.96, 43.9))
tb('IRLB8721', 21.85, 44.59, 0.8, bold=True)

# ---------- Taster 6x6 ----------
ln((8.15, 37.8), (8.15, 42.3)); ln((14.65, 37.8), (14.65, 42.3))
ln((10.6, 36.54), (12.2, 36.54)); ln((10.6, 43.54), (12.2, 43.54))
circle(11.4, 40.04, 1.7)
tb('SW1', 11.4, 40.04, 0.8)

# ---------- PIR-Anschluss J3 ----------
for s_, y_ in (('V', 30.59), ('O', 33.13), ('G', 35.67)):
    tb(s_, 0.95, y_, 0.8, bold=True)
tb('PIR', 4.75, 33.13, 0.8, angle=90)

# ---------- Schraubklemmen (Kabeleinfuehrung zum Rand) ----------
for x0, titel, pins in ((2.68, '12V', (('+12V', 5.34), ('GND', 10.42))),
                        (15.38, 'LAMPE', (('+', 18.04), ('-', 23.12)))):
    rect(x0, 46.22, x0 + 10.4, 56.27)
    ln((x0, 55.65), (x0 + 10.4, 55.65))
    tb(titel, x0 + 5.2, 47.2, 0.8, bold=True)
    for s_, x_ in pins:
        tb(s_, x_, 48.85, 0.9, bold=True)
