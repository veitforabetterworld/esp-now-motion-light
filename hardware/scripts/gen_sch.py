# Erzeugt den Schaltplan Funklicht.kicad_sch – zusammenhaengend verdrahtet
# (Versorgung links -> D1 mini Mitte -> Lampenschaltung rechts, GND-Schiene unten, +12V-Schiene oben)
import json, sys, uuid
sys.path.insert(0, __file__.replace('\\', '/').rsplit('/', 1)[0])
from sexp import lib_symbol, pins, dump, q
from design import *

U = lambda: str(uuid.uuid4())
ROOT = "6f1c2d3e-0a1b-4c5d-9e8f-102030405060"
UIDS_FILE = __file__.replace('gen_sch.py', 'uids.json')
try:
    uids = json.load(open(UIDS_FILE))      # gleiche UUIDs behalten -> Platine bleibt zugeordnet
except Exception:
    uids = {}
out, libsyms = [], {}

def fmt(v): return f"{v:.2f}".rstrip('0').rstrip('.')
def font(hide=False, justify=None):
    e = ['effects', ['font', ['size', '1.27', '1.27']]]
    if justify: e.append(['justify', justify])
    if hide: e.append(['hide', 'yes'])
    return e
def prop(name, val, x, y, hide=False, justify=None):
    return ['property', q(name), q(val), ['at', fmt(x), fmt(y), '0'], font(hide, justify)]
def get_lib(lib, name):
    key = f'{lib}:{name}'
    if key not in libsyms: libsyms[key] = lib_symbol(KICAD + '/symbols', lib, name)
    return key, libsyms[key]

# ---------------- Platzierung ----------------
# ref: (x, y, Drehung 0/180, gespiegelt, (Ref x, y), (Wert x, y), Ausrichtung)
PLACE = {
    'J1':  (38.10, 58.42, 0, True,  (38.10, 53.34),  (38.10, 66.04), None),
    'D1':  (63.50, 58.42, 180, False, (63.50, 54.61), (63.50, 62.23), None),
    'C1':  (76.20, 64.77, 0, False, (78.74, 63.50),  (78.74, 66.04), 'left'),
    'U2':  (93.98, 58.42, 0, False, (93.98, 50.80),  (96.52, 69.85), None),
    'C2':  (111.76, 64.77, 0, False, (114.30, 63.50), (114.30, 66.04), 'left'),
    'U1':  (147.32, 88.90, 0, False, (152.40, 60.96), (152.40, 63.50), 'left'),
    'SW1': (177.80, 91.44, 0, False, (185.42, 90.17), (185.42, 92.71), 'left'),
    'J3':  (172.72, 101.60, 0, False, (172.72, 107.95), (172.72, 110.49), None),
    'R2':  (203.20, 85.09, 0, False, (205.74, 83.82), (205.74, 86.36), 'left'),
    'R1':  (213.36, 73.66, 180, False, (215.90, 72.39), (215.90, 74.93), 'right'),   # 180 Grad: 'right' wirkt wie links
    'Q1':  (228.60, 66.04, 0, False, (233.68, 64.77), (233.68, 67.31), 'left'),
    'J2':  (251.46, 53.34, 0, False, (254.00, 50.80), (254.00, 58.42), 'left'),
}

def pin_xy(ref, num):
    x, y, rot, mir = PLACE[ref][:4]
    lib, sym = PARTS[ref][0], PARTS[ref][1]
    px, py, _ = pins(get_lib(lib, sym)[1])[num]
    if mir: px = -px
    if rot == 180: px, py = -px, -py
    return (round(x + px, 2), round(y - py, 2))

symbols_pins = []   # alle Pin-Anschlusspunkte (fuer Verbindungspunkte)
for ref, (lib, sym, val, fp, nets, *_r) in PARTS.items():
    x, y, rot, mir, rp, vp, just = PLACE[ref]
    key, s = get_lib(lib, sym)
    uid = uids.get(ref) or U()
    uids[ref] = uid
    e = ['symbol', ['lib_id', q(key)], ['at', fmt(x), fmt(y), str(rot)]]
    if mir: e.append(['mirror', 'y'])
    e += [['unit', '1'], ['exclude_from_sim', 'no'], ['in_bom', 'yes'], ['on_board', 'yes'], ['dnp', 'no'],
          ['uuid', q(uid)],
          prop('Reference', ref, *rp, justify=just), prop('Value', val, *vp, justify=just),
          prop('Footprint', fp, x, y, True), prop('Datasheet', '', x, y, True)]
    for p in pins(s):
        e.append(['pin', q(p), ['uuid', q(U())]])
        pt = pin_xy(ref, p)
        if p in nets: symbols_pins.append(pt)
        else: out.append(['no_connect', ['at', fmt(pt[0]), fmt(pt[1])], ['uuid', q(U())]])
    e.append(['instances', ['project', q(NAME), ['path', q('/' + ROOT), ['reference', q(ref)], ['unit', '1']]]])
    out.append(e)

pwr_n = [0]
def power(net, pt, rot=0):
    pwr_n[0] += 1
    key, _ = get_lib('power', net)
    ref = f'#{"FLG" if net == "PWR_FLAG" else "PWR"}{pwr_n[0]:02d}'
    out.append(['symbol', ['lib_id', q(key)], ['at', fmt(pt[0]), fmt(pt[1]), str(rot)], ['unit', '1'],
                ['exclude_from_sim', 'no'], ['in_bom', 'no'], ['on_board', 'no'], ['dnp', 'no'], ['uuid', q(U())],
                prop('Reference', ref, pt[0], pt[1] - 5, True),
                prop('Value', net, pt[0], pt[1] - (3.81 if net != 'PWR_FLAG' else 4.6)),
                prop('Footprint', '', pt[0], pt[1], True), prop('Datasheet', '', pt[0], pt[1], True),
                ['pin', q('1'), ['uuid', q(U())]],
                ['instances', ['project', q(NAME), ['path', q('/' + ROOT), ['reference', q(ref)], ['unit', '1']]]]])
    symbols_pins.append(pt)

# ---------------- Leitungen ----------------
P = pin_xy
Y12, YG = 45.72, 116.84          # +12V-Schiene oben, GND-Schiene unten
WIRES = [
    # 12 V Eingang -> Verpolschutz -> L7805, +12V-Schiene
    [P('J1', '1'), (50.80, 58.42), P('D1', '2')],
    [(50.80, 58.42), (50.80, Y12), (241.30, Y12), (241.30, 53.34), P('J2', '1')],
    [P('D1', '1'), (76.20, 58.42), P('U2', '1')],
    [(76.20, 58.42), P('C1', '1')],
    # 5 V
    [P('U2', '3'), (111.76, 58.42), (144.78, 58.42), P('U1', '9')],
    [(111.76, 58.42), P('C2', '1')],
    # GND-Schiene
    [P('J1', '2'), (48.26, 60.96), (48.26, YG), (231.14, YG), P('Q1', '3')],
    [P('C1', '2'), (76.20, YG)],
    [P('U2', '2'), (93.98, YG)],
    [P('C2', '2'), (111.76, YG)],
    [P('U1', '10'), (147.32, YG)],
    # Taster
    [P('U1', '4'), P('SW1', '1')],
    [P('SW1', '2'), (182.88, YG)],
    # PIR
    [P('U1', '5'), (162.56, 93.98), (162.56, 101.60), P('J3', '2')],
    [P('J3', '3'), (165.10, 104.14), (165.10, YG)],
    [P('J3', '1'), (165.10, 99.06)],
    # Lampe schalten
    [P('U1', '14'), (203.20, 81.28), (213.36, 81.28), P('R1', '1')],
    [P('R2', '1'), (203.20, 81.28)],
    [P('R2', '2'), (203.20, YG)],
    [P('R1', '2'), (213.36, 66.04), P('Q1', '1')],
    [P('Q1', '2'), (231.14, 55.88), P('J2', '2')],
]
# Netznamen (wie auf der Platine): Versorgungssymbole auf den Schienen, Labels auf den Signalleitungen
power('+12V', (66.04, Y12))
power('+12V', (165.10, 99.06))                     # PIR-Versorgung (sonst Kreuzung mit den Signalleitungen)
power('+5V', (127.00, 58.42))
power('GND', (68.58, YG))
for p in ((55.88, Y12), (81.28, 58.42), (55.88, YG)):   # PWR_FLAG: +12V, VIN, GND
    power('PWR_FLAG', p, 0 if p[1] != YG else 180)
LABELS = [('VIN', (71.12, 58.42), 0), ('LAMP_EN', (187.96, 81.28), 0), ('GATE', (218.44, 66.04), 0),
          ('LAMP-', (236.22, 55.88), 0), ('BTN', (165.10, 91.44), 0), ('PIR', (162.56, 99.06), 90)]
for name, (x, y), ang in LABELS:
    out.append(['label', q(name), ['at', fmt(x), fmt(y), str(ang)], font(justify='left bottom'), ['uuid', q(U())]])

segs = []
for w in WIRES:
    segs += [(a, b) for a, b in zip(w, w[1:]) if a != b]
pts = set(symbols_pins) | {p for s in segs for p in s} | {p for _n, p, _a in LABELS}
def on_seg(p, a, b):
    if p in (a, b): return False
    if a[0] == b[0] == p[0]: return min(a[1], b[1]) < p[1] < max(a[1], b[1])
    if a[1] == b[1] == p[1]: return min(a[0], b[0]) < p[0] < max(a[0], b[0])
    return False
changed = True
while changed:                                      # Leitungen an allen Anschlusspunkten auftrennen
    changed = False
    for i, (a, b) in enumerate(segs):
        hit = next((p for p in pts if on_seg(p, a, b)), None)
        if hit:
            segs[i:i + 1] = [(a, hit), (hit, b)]
            changed = True
            break
deg = {}
for a, b in segs:
    for p in (a, b): deg[p] = deg.get(p, 0) + 1
for p in symbols_pins: deg[p] = deg.get(p, 0) + 1
for a, b in segs:
    out.append(['wire', ['pts', ['xy', fmt(a[0]), fmt(a[1])], ['xy', fmt(b[0]), fmt(b[1])]],
                ['stroke', ['width', '0'], ['type', 'default']], ['uuid', q(U())]])
for p, n in deg.items():
    if n >= 3: out.append(['junction', ['at', fmt(p[0]), fmt(p[1])], ['diameter', '0'], ['color', '0', '0', '0', '0'], ['uuid', q(U())]])

texts = [
    ("Funklicht – vernetzter Bewegungsmelder mit 12-V-Lampe (ESP-NOW)", 30.48, 30.48),
    ("Versorgung: 12 V -> 1N4007 (Verpolschutz) -> L7805 -> 5 V fuer den D1 mini; PIR direkt an +12 V", 30.48, 137.16),
    ("Lampe: D1 (GPIO5) -> 220 R -> Gate IRLB8721 (Logic-Level); 10k Pull-down haelt die Lampe beim Booten aus", 30.48, 142.24),
    ("Bedienung: D5 (GPIO14) Taster nach GND (INPUT_PULLUP); D6 (GPIO12) PIR-Ausgang (3,3 V)", 30.48, 147.32),
    ("Ohne Freilaufdiode: nur fuer LED-/Gluehlampen, keine induktiven Lasten", 30.48, 152.40),
]
for t, x, y in texts:
    out.append(['text', q(t), ['exclude_from_sim', 'no'], ['at', fmt(x), fmt(y), '0'], font(justify='left'), ['uuid', q(U())]])

doc = ['kicad_sch', ['version', '20250114'], ['generator', q('eeschema')], ['generator_version', q('9.0')],
       ['uuid', q(ROOT)], ['paper', q('A4')],
       ['title_block', ['title', q('Funklicht')], ['rev', q('1.2')], ['company', q('')],
        ['comment', '1', q('Wemos D1 mini, HC-SR501, IRLB8721, einseitige Platine')]],
       ['lib_symbols'] + list(libsyms.values())] + out + \
      [['sheet_instances', ['path', q('/'), ['page', q('1')]]], ['embedded_fonts', 'no']]
open(f'{PRJ}/{NAME}.kicad_sch', 'w', encoding='utf-8', newline='\n').write(dump(doc) + '\n')
json.dump(uids, open(UIDS_FILE, 'w'))
print('Schaltplan geschrieben:', len(PARTS), 'Bauteile,', len(segs), 'Leitungen')
