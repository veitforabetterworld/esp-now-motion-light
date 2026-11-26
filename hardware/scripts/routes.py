# Leiterbahnen Funklicht v1.2 (nur Unterseite B.Cu, 45-Grad-Fuehrung, Modulkoordinaten, Raster 1,27/0,635 mm)
# Topologie aus dem Relayout uebernommen:
#  - PIR, Taster und +12V zum PIR laufen als drei parallele Diagonalen unter dem D1 mini
#    zwischen den Pads von D1 (1N4007) hindurch zu J3/SW1.
#  - Lampenstrom: J1+ -> Rand unten -> J2+ ; J2- -> Q1 Drain ; Q1 Source -> J1 GND (eigene breite Bahn).
#  - GND unter dem Modul (R2, C2, C1, Pin 10) ist ueber U2-GND mit Q1-Source verbunden.
T = lambda *pts: [p if isinstance(p[0], str) else M(*p) for p in pts]

# ---------- Lampenstromkreis (1,5 mm) ----------
track('+12V', PWR, *T(('J1', '1'), (2.54, 45.085), (15.24, 45.085), ('J2', '1')))
track('GND', PWR, *T(('J1', '2'), (7.62, 41.91), ('Q1', '3')))
track('/LAMP-', PWR, *T(('Q1', '2'), (19.05, 36.83), (20.32, 38.1), ('J2', '2')))

# ---------- +12V zum PIR (links am Rand) und von D1 ----------
track('+12V', MID, *T(('J1', '1'), (-1.8, 38.205), (-1.8, 23.39), ('J3', '1')))
track('+12V', MID, *T(('D1', '2'), (6.35, 14.65), (0.0, 21.0), ('J3', '1')))

# ---------- GND unten ----------
track('GND', MID, *T(('J1', '2'), (7.62, 41.91), (4.445, 38.735), (4.445, 31.115), ('J3', '3')))
track('GND', MID, *T(('SW1', '2', 0), (10.85, 38.68)))
track('GND', SIG, *T(('U2', '2'), (19.05, 31.4325), (16.51, 31.4325), ('Q1', '3')))   # zwischen den TO-220-Reihen

# Fuehrung um C1/H2 nach dem Relayout des Nutzers vom 26.11.2026 (C1 rechts, H2 rechts unter dem Modul)
# ---------- VIN: D1 -> C1 -> L7805 ----------
track('/VIN', MID, *T(('D1', '1'), ('C1', '1'), (16.51, 29.44), ('U2', '1')))

# ---------- GND unter dem Modul ----------
track('GND', MID, *T(('C2', '2'), (11.47, 18.02), (15.7, 22.25), (15.7, 26.0), (19.05, 29.35), ('U2', '2')))
track('GND', MID, *T(('C1', '2'), (13.14, 19.69)))   # auf die Diagonale C2 -> U2
track('GND', MID, *T(('C2', '2'), (11.47, 13.97), (21.59, 13.97), ('U1', '10')))
track('GND', MID, *T(('R2', '2'), (13.97, 13.97)))

# ---------- +5V: Pin 9 -> C2 -> L7805-Ausgang ----------
track('+5V', MID, *T(('U1', '9'), (22.225, 17.78), (20.955, 16.51), ('C2', '1'), (13.97, 18.52), (17.2, 21.75),
                     (17.2, 25.25), (21.59, 29.64), ('U2', '3')))

# ---------- Lampe schalten: GPIO5 -> R1 -> Gate, R2 Pull-down ----------
track('/LAMP_EN', SIG, *T(('U1', '14'), (20.32, 5.08), (19.05, 6.35), ('R1', '1')))
track('/LAMP_EN', SIG, *T(('R2', '1'), (17.78, 5.08), (20.32, 5.08)))
track('/GATE', SIG, *T(('R1', '2'), (21.75, 19.05), (24.7, 22.0), (24.7, 29.91), ('Q1', '1')))

# ---------- Signale vom linken Pinstreifen ----------
track('/BTN', SIG, *T(('U1', '4'), (7.62, 7.62), (10.16, 10.16), (10.16, 14.65), (3.81, 21.0), (3.81, 25.25), ('SW1', '1', 1)))
track('/PIR', SIG, *T(('U1', '5'), (5.08, 10.16), (8.255, 13.335), (8.255, 14.65), (2.54, 20.365), (2.54, 22.86), (1.27, 24.13), ('J3', '2')))
