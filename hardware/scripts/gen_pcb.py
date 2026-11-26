# Erzeugt die einseitige Platine Funklicht.kicad_pcb (Leiterbahnen nur auf B.Cu)
import sys, json, pcbnew
sys.path.insert(0, __file__.replace('\\', '/').rsplit('/', 1)[0])
from design import *

OX, OY = 100.0, 100.0           # Platinenursprung auf dem Blatt
mm = pcbnew.FromMM
P = lambda x, y: pcbnew.VECTOR2I(mm(OX + x), mm(OY + y))

def ohne_druck(fp):
    """Bestueckungsdruck des Footprints auf die Fab-Ebene verschieben (wird nicht gedruckt).
    Eigener Druck nur auf der Unterseite: labels.py. (fp.Remove() bringt die SWIG-Typen in KiCad 10 durcheinander.)"""
    for g in list(fp.GraphicalItems()):
        if g.GetLayer() in (pcbnew.F_SilkS, pcbnew.B_SilkS):
            g.SetLayer(pcbnew.F_Fab)
    for t in (fp.Reference(), fp.Value()):
        t.SetLayer(pcbnew.F_Fab)
    return fp

uids = json.load(open(__file__.replace('gen_pcb.py', 'uids.json')))
board = pcbnew.BOARD()
nets = {}
def net(name):
    if name not in nets:
        n = pcbnew.NETINFO_ITEM(board, name)
        board.Add(n)
        nets[name] = n
    return nets[name]

NC = {'U1': {n: f'unconnected-(U1-{p}-Pad{n})' for n, p in {'1': '~{RST}', '2': 'A0', '3': 'D0', '6': 'MOSI{slash}D7', '7': 'CS{slash}D8', '8': '3V3', '11': 'D4', '12': 'D3', '13': 'SDA{slash}D2', '15': 'RX', '16': 'TX'}.items()}}
fps = {}
for ref, (lib, sym, val, fpid, pinnets, _sch, (x, y, rot)) in PARTS.items():
    flib, fname = fpid.split(':')
    path = f'{PRJ}/lib/{flib}.pretty' if flib == 'Funklicht' else f'{KICAD}/footprints/{flib}.pretty'
    fp = ohne_druck(pcbnew.FootprintLoad(path, fname))
    fp.SetFPID(pcbnew.LIB_ID(flib, fname))
    fp.SetReference(ref)
    fp.SetValue(val)
    fp.SetPath(pcbnew.KIID_PATH('/' + uids[ref]))
    fp.SetSheetname('/')
    fp.SetSheetfile(f'{NAME}.kicad_sch')
    board.Add(fp)
    fp.SetPosition(P(x, y))
    fp.SetOrientationDegrees(rot)
    if ref == 'SW1':
        fp.SetDuplicatePadNumbersAreJumpers(True)  # gleiche Pinnummern sind im Taster verbunden
    for pad in fp.Pads():
        n = pinnets.get(pad.GetNumber()) or NC.get(ref, {}).get(pad.GetNumber())
        if n:
            pad.SetNet(net(n))
    fps[ref] = fp

def pad(ref, num, i=0):
    ps = [p for p in fps[ref].Pads() if p.GetNumber() == num]
    v = ps[i].GetPosition()
    return (pcbnew.ToMM(v.x) - OX, pcbnew.ToMM(v.y) - OY)

if __name__ == '__main__' and '--pads' in sys.argv:
    for ref, fp in fps.items():
        print(ref, ' '.join(f'{p.GetNumber()}:({pcbnew.ToMM(p.GetPosition().x)-OX:.2f},{pcbnew.ToMM(p.GetPosition().y)-OY:.2f})' for p in fp.Pads()))
    sys.exit()

# ---------------- Leiterbahnen (alle auf B.Cu) ----------------
def track(netname, width, *pts):
    pts = [pad(*p) if isinstance(p[0], str) else p for p in pts]
    for a, b in zip(pts, pts[1:]):
        t = pcbnew.PCB_TRACK(board)
        t.SetStart(P(*a)); t.SetEnd(P(*b))
        t.SetWidth(mm(width)); t.SetLayer(pcbnew.B_Cu)
        t.SetNet(net(netname))
        board.Add(t)

PWR, MID, SIG = 1.5, 0.8, 0.5   # Lampenstrom / Versorgung / Signale
exec(open(__file__.replace('gen_pcb.py', 'routes.py'), encoding='utf-8').read())

# ---------------- Umriss, Befestigungsloecher, Beschriftung ----------------
def seg(layer, a, b, w=0.1):
    s = pcbnew.PCB_SHAPE(board)
    s.SetShape(pcbnew.SHAPE_T_SEGMENT)
    s.SetStart(P(*a)); s.SetEnd(P(*b)); s.SetLayer(layer); s.SetWidth(mm(w))
    board.Add(s)
corners = OUTLINE
for a, b in zip(corners, corners[1:] + corners[:1]):
    seg(pcbnew.Edge_Cuts, a, b)

HOLES = [M(*p) for p in PCB_HOLES_M]
HOLE_FPS = []
for i, (x, y) in enumerate(HOLES):
    fp = ohne_druck(pcbnew.FootprintLoad(f'{PRJ}/lib/{HOLE_FP[0]}.pretty', HOLE_FP[1]))
    fp.SetReference(f'H{i+1}')
    fp.SetValue('M3')
    fp.SetFPID(pcbnew.LIB_ID(*HOLE_FP))
    fp.SetAttributes(fp.GetAttributes() | pcbnew.FP_BOARD_ONLY | pcbnew.FP_EXCLUDE_FROM_BOM | pcbnew.FP_EXCLUDE_FROM_POS_FILES)
    fp.Reference().SetVisible(False)
    board.Add(fp)
    fp.SetPosition(P(x, y))
    HOLE_FPS.append(fp)

def text(s, x, y, size=1.2, layer=pcbnew.F_SilkS, bold=False, angle=0):
    t = pcbnew.PCB_TEXT(board)
    t.SetText(s); t.SetPosition(P(x, y)); t.SetLayer(layer)
    t.SetTextSize(pcbnew.VECTOR2I(mm(size), mm(size))); t.SetTextThickness(mm(max(0.15, size * (0.2 if bold else 0.15))))   # JLCPCB: Strich >= 0,15 mm
    t.SetTextAngleDegrees(angle)
    if layer == pcbnew.B_SilkS or layer == pcbnew.B_Cu:
        t.SetMirrored(True)
    board.Add(t)
exec(open(__file__.replace('gen_pcb.py', 'labels.py'), encoding='utf-8').read())

# Designregeln (JLCPCB-tauglich, grosszuegig fuer Handloeten)
ds = board.GetDesignSettings()
ds.SetCopperLayerCount(2)
ds.m_TrackMinWidth = mm(0.3)
ds.m_MinClearance = mm(0.3)
ds.m_HoleClearance = mm(0.3)
ds.m_CopperEdgeClearance = mm(0.5)
board.SetFileName(f'{PRJ}/{NAME}.kicad_pcb')
pcbnew.SaveBoard(f'{PRJ}/{NAME}.kicad_pcb', board)
# Footprint-Druck ist absichtlich auf F.Fab verschoben -> Abweichung von der Bibliothek ist gewollt.
# SaveBoard schreibt die Projektdatei neu, daher danach anpassen.
pro = f'{PRJ}/{NAME}.kicad_pro'
txt = open(pro, encoding='utf-8').read()
open(pro, 'w', encoding='utf-8', newline='\n').write(
    txt.replace('"lib_footprint_mismatch": "warning"', '"lib_footprint_mismatch": "ignore"'))
print('Platine geschrieben')
