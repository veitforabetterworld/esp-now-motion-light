# Gemeinsame Bauteil- und Netzdefinition fuer Schaltplan und Platine (Funklicht v1.2)
# Platzierung nach dem Relayout vom 26.11.2026, auf 1,27-mm-Raster (bezogen auf Pin 1 des D1 mini)
# und symmetrisch zur Modulmitte ausgerichtet.
import os, sys
# Skripte mit KiCads python.exe starten: share/kicad liegt dann neben bin/. Sonst KICAD_SHARE setzen.
KICAD = (os.environ.get("KICAD_SHARE") or
         os.path.join(os.path.dirname(sys.executable), "..", "share", "kicad"))
KICAD = os.path.normpath(KICAD).replace("\\", "/")
PRJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__))).replace("\\", "/")
NAME = "Funklicht"

# Modulkoordinaten: Pin 1 (RST) des D1 mini = (0,0), x nach rechts, y nach unten, Raster 1,27 mm.
# Platinenkoordinaten = Modulkoordinaten + MOFF. Platine symmetrisch zur Modulmitte (x = 11,43).
MOFF = (2.8, 9.0)
W, H = 28.46, 57.0
YT = 42.545                 # Schraubklemmen-Pins (33,5 x 1,27)
def M(x, y): return (x + MOFF[0], y + MOFF[1])

# ref: (lib, symbol, value, footprint, {pin: net}, (sch_x, sch_y), (pcb_x, pcb_y, rot))
PARTS = {
    "U1": ("RF_Module", "WEMOS_D1_mini", "WEMOS D1 mini (ESP8266)", "Funklicht:WEMOS_D1_mini_Sockel",
           {"9": "+5V", "10": "GND", "14": "/LAMP_EN", "4": "/BTN", "5": "/PIR"},
           (203.2, 88.9), (*M(0, 0), 0)),
    "U2": ("Regulator_Linear", "L7805", "L7805", "Package_TO_SOT_THT:TO-220-3_Vertical",
           {"1": "/VIN", "2": "GND", "3": "+5V"}, (127.0, 45.72), (*M(16.51, 29.845), 0)),
    "Q1": ("Transistor_FET", "IRLB8721PBF", "IRLB8721PBF", "Package_TO_SOT_THT:TO-220-3_Vertical",
           {"1": "/GATE", "2": "/LAMP-", "3": "GND"}, (127.0, 101.6), (*M(21.59, 33.02), 180)),
    "R1": ("Device", "R", "220", "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal",
           {"1": "/LAMP_EN", "2": "/GATE"}, (152.4, 96.52), (*M(19.05, 8.89), -90)),
    "R2": ("Device", "R", "10k", "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal",
           {"1": "/LAMP_EN", "2": "GND"}, (165.1, 111.76), (*M(13.97, 1.27), -90)),
    "D1": ("Device", "D", "1N4007", "Diode_THT:D_DO-41_SOD81_P10.16mm_Horizontal",
           {"1": "/VIN", "2": "+12V"}, (76.2, 45.72), (*M(6.35, 24.13), 90)),
    "C1": ("Device", "C", "1u", "Capacitor_THT:C_Disc_D3.0mm_W1.6mm_P2.50mm",
           {"1": "/VIN", "2": "GND"}, (101.6, 55.88), (*M(11.2, 24.13), 90)),   # Nutzer 26.11.: nach rechts
    "C2": ("Device", "C_Polarized", "10u 16V, max. 6 mm", "Capacitor_THT:CP_Radial_D5.0mm_P2.50mm",
           {"1": "+5V", "2": "GND"}, (152.4, 55.88), (*M(13.97, 16.51), 180)),
    "J1": ("Connector", "Screw_Terminal_01x02", "12V", "TerminalBlock_Phoenix:TerminalBlock_Phoenix_MKDS-1,5-2-5.08_1x02_P5.08mm_Horizontal",
           {"1": "+12V", "2": "GND"}, (50.8, 48.26), (*M(2.54, YT), 0)),
    "J2": ("Connector", "Screw_Terminal_01x02", "Lampe", "TerminalBlock_Phoenix:TerminalBlock_Phoenix_MKDS-1,5-2-5.08_1x02_P5.08mm_Horizontal",
           {"1": "+12V", "2": "/LAMP-"}, (63.5, 101.6), (*M(15.24, YT), 0)),
    "J3": ("Connector_Generic", "Conn_01x03", "HC-SR501", "Funklicht:Loetaugen_1x03_P2.54mm",
           {"1": "+12V", "2": "/PIR", "3": "GND"}, (63.5, 147.32), (*M(0, 21.59), 0)),
    "SW1": ("Switch", "SW_Push", "Taster 6x6x5", "Button_Switch_THT:SW_PUSH_6mm",
            {"1": "/BTN", "2": "GND"}, (127.0, 147.32), (*M(6.35, 34.29), 90)),
}
FLAGS = [("+12V", (38.1, 25.4)), ("GND", (50.8, 25.4)), ("/VIN", (63.5, 25.4))]

OUTLINE = [(0, 0), (W, 0), (W, H), (0, H)]
# Befestigungsloecher M3 (Modulkoordinaten); H2/H3 liegen unter dem D1 mini -> vor dem Aufstecken schrauben
# H2 vom Nutzer am 26.11.2026 verschoben: Platinenkoordinate (24,0 / 32,0)
PCB_HOLES_M = [(1.27, 32.385), (21.2, 23.0), (5.08, 2.54)]
HOLE_FP = ("Funklicht", "MountingHole_3.2mm_M3_Kopf5.5")
