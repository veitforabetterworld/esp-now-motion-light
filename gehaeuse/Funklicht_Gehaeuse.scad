// Funklicht v2.0 – Aussengehaeuse fuer die Platine 28,46 x 57 mm
// Aufbau:
//   - Gehaeuse: Haube mit fester Front (PIR-Fenster + Taster), wird von hinten bestueckt
//   - Klemmendeckel vorne: kleiner Schraubdeckel ueber den Schraubklemmen, eigene Dichtung.
//     Ein Quersteg ueber den Klemmen trennt den Klemmenraum vorne ab und traegt die Dichtung.
//   - Bodendeckel (Wandseite): traegt die Platine und die Wandlaschen, mit 4 M3-Senkkopfschrauben
//     von hinten an das Gehaeuse geschraubt, rundum gedichtet (Nut im Gehaeuserand).
//     Die Dichtflaeche liegt damit an der geschuetzten Wandseite.
// HC-SR501 an seinen zwei Befestigungsloechern von innen an die Front geschraubt (M2).
// Taster von aussen: Stift mit Kopf, gefuehrt in einem Rohr an der Front, Kopf liegt auf dem Taster.
// Material: PETG (gehaeuse, bodendeckel, klemmdeckel, tastenstift, regenschutz)
//           TPU 95A (dichtung, klemmdichtung, linsendichtung)
// Export:  openscad -D 'part="gehaeuse"' -o gehaeuse.stl Funklicht_Gehaeuse.scad
part = "baugruppe";
$fn = 64;

// ---------------- Hauptmasse (mm) ----------------
iw = 34;  ih = 73.5;  id = 36;   // Innenraum (Breite: PIR-Platine 32 mm; Laenge: Platine + Eckbloecke oben und unten)
t = 4;  tb = 4;  tl = 3;         // Wand, Bodendeckel, Front
ri = 1;  ro = 4;
H = tb + id;                     // Innenseite der Front bei Z = H, Dichtflaeche bei Z = tb

ins_d = 4.0; ins_l = 6.4;        // Einschmelzmutter M3 (z. B. M3 x 5,7, Aussen-D 4,6)
gw = 2.0; gd = 2.0; g_in = 0.8;  // Dichtungsnut (beginnt 0,8 mm hinter der Innenkante)
sw = 1.8; sh = 2.6;              // TPU-Dichtschnur (0,6 mm Verpressung)

// ---------------- Platine (aus KiCad) ----------------
pcb_w = 28.46; pcb_h = 57.0; pcb_t = 1.6;
pcb_holes = [[4.07, 41.385], [24.0, 32.0], [7.88, 11.54]];   // H1, H2 (am 26.11. verschoben), H3
bx0 = (iw - pcb_w) / 2;  by0 = 8.5;   // 1,5 mm Luft zu den unteren Eckbloecken; Klemmen 3,9 mm hinter den Kontermuttern
standoff_h = 6;  standoff_d = 6.5;   // D 6,5: frei neben den Loetstellen (R1 an H2: 0,45 mm Luft)
pcb_z = tb + standoff_h;
function b2g(p) = [bx0 + p[0], by0 + pcb_h - p[1]];
function m2g(p) = b2g([p[0] + 2.8, p[1] + 9.0]);

// ---------------- Verschraubung Bodendeckel ----------------
// Eckbloecke am hinteren Rand, ausserhalb des Platinenumrisses (die Platine muss in Z-Richtung durchpassen)
cb = 7;                          // Blockgroesse
cb_h = 7.5;                      // Blockhoehe ab Dichtflaeche (Einschmelzmutter 6,4 tief)
deck_pts = [[0, 0], [iw, 0], [0, ih], [iw, ih]];

// ---------------- Klemmenraum vorne (Schraubdeckel) ----------------
// Schraubklemmen (3D-Modell Phoenix MKDS 1,5): Schraube ueber dem Pin, Oberkante 13,8 mm
term_top = pcb_z + pcb_t + 13.8;
term_screw_y = m2g([0, 42.545 + 0.2])[1];
beam_y0 = term_screw_y + 1.95;   // Schraubendreher D 3 mm hat Platz
beam_y1 = beam_y0 + 3.6;         // Quersteg (endet vor dem MOSFET)
beam_z0 = term_top + 1.0;        // Unterkante Steg (ueber den Klemmen)
shoulder_z0 = pcb_z + pcb_t + 20 + 0.6;   // Verstaerkung unter der Frontkante: 0,6 mm ueber L7805/MOSFET
shoulder_w = 3.0;                // so weit reicht sie unter die Front
kcb = 6;  kblk_z0 = 33.0;        // Schraubbloecke an der Front (Einschmelzmutter 6,4 tief), frei ueber den Klemmen
klemm_pts = [[0, 0], [iw, 0], [0, beam_y0 - 1], [iw, beam_y0 - 1]];
kgw = gw; k_in = g_in; ksw = sw; ksh = sh;      // gleiche Dichtschnur wie am Bodendeckel
y_split = beam_y0 + k_in + kgw + 0.8;            // Stoss Klemmendeckel / Front (0,5 mm Ueberdeckung hinter der Nut)

gland_d = 12.4;  glands_x = [9, 25];      // M12 x 1,5
gland_z = tb + 16;               // etwas tiefer als Raummitte: naeher an den Klemmeneingaengen, Kontermutter frei ueber den Eckbloecken
gland_nut_af = 15;  gland_nut_t = 5;      // Kontermutter innen (fuer die Kollisionspruefung)
lug_l = 11;  lug_w = 22;  lug_hole = 4.8; // Wandlaschen am Bodendeckel
lug_slot = 3;                    // Langloch: Verschiebeweg (Mitte zu Mitte)
lug_r = 3;  lug_fillet = 2;      // Rundung der Laschenecken / Uebergang zum Deckel
// Langloecher um 45 Grad gedreht, oben und unten gespiegelt -> zusammen in jede Richtung verschiebbar
lug_slots = [[ih + t + lug_l / 2, 45], [-t - lug_l / 2, -45]];

// ---------------- HC-SR501 ----------------
pir_c = [iw / 2, (y_split + ih + t) / 2];   // mittig auf der Front hinter dem Klemmendeckel
pir_pcb = [32, 24]; pir_pcb_t = 1.6;  // HC-SR501: 32 x 24 mm
pir_hole_dx = 14.0;              // Lochabstand 28 mm (am Bauteil gemessen)
lens_plate = 24; lens_plate_t = 2; dome_r = 11.5;
lens_gasket_t = 1.0; lens_gasket_press = 0.3;
pir_boss_h = lens_plate_t + lens_gasket_t - lens_gasket_press;   // Platine liegt auf den Domen

// ---------------- Taster-Durchfuehrung ----------------
sw_c = m2g([8.6, 31.04]);
sw_top = pcb_z + pcb_t + 5.0;    // Taster 6x6x5
pin_d = 4.0;  pin_clear = 0.4;   // Stift / Spiel im Rohr (Bohrung 4,4)
tube_od = 7.6;                   // Fuehrungsrohr an der Front
pin_head_d = 6.5;  pin_head_t = 1.5;
pin_play = 1.0;                  // Luft zwischen Stiftkopf und Rohrende (Stift kann nicht nach aussen fallen)
pin_proj = 1.0;                  // Stift steht im Ruhezustand so weit aus der Front
tube_z0 = sw_top + pin_head_t + pin_play;        // Unterkante Rohr
pin_len = H + tl + pin_proj - sw_top;            // Gesamtlaenge Stift inkl. Kopf

// ---------------- 2D-Formen ----------------
module rr(w, h, r) { translate([r, r]) offset(r = r) square([w - 2 * r, h - 2 * r]); }
module outer2d() { translate([-t, -t]) rr(iw + 2 * t, ih + 2 * t, ro); }
// Gedichteter Innenraum = Innenquerschnitt ohne die Eckbloecke
module seal_region2d() {
    difference() {
        square([iw, ih]);
        for (x = [0, iw - cb], y = [0, ih - cb]) translate([x, y]) square(cb);
    }
}
module groove2d(w) {
    c = g_in + gw / 2;
    difference() { offset(r = c + w / 2) seal_region2d(); offset(r = c - w / 2) seal_region2d(); }
}
// Klemmenraum: Oeffnung in der Front ohne die vier Schraubbloecke
module klemm_region2d() {
    difference() {
        square([iw, beam_y0]);
        for (x = [0, iw - kcb], y = [0, beam_y0 - kcb]) translate([x, y]) square(kcb);
    }
}
module kgroove2d(w) {
    c = k_in + kgw / 2;
    difference() { offset(r = c + w / 2) klemm_region2d(); offset(r = c - w / 2) klemm_region2d(); }
}
module klemmdeckel2d() { intersection() { outer2d(); translate([-t - 1, -t - 1]) square([iw + 2 * t + 2, y_split - 0.3 + t + 1]); } }
module bodendeckel2d() {
    // aussen gerundete Laschenecken, innen Hohlkehle zum Gehaeuseumriss (dessen Radius 4 bleibt erhalten)
    offset(r = lug_r) offset(delta = -lug_r) offset(r = -lug_fillet) offset(delta = lug_fillet) {
        outer2d();
        for (y = [-t - lug_l, ih + t - 0.01]) translate([iw / 2 - lug_w / 2, y]) square([lug_w, lug_l + 0.01]);
    }
}
module langloch2d(d, l) { hull() for (s = [-1, 1]) translate([s * l / 2, 0]) circle(d = d); }

// Eckblock am hinteren Rand: von der Dichtflaeche bis cb_h, darueber 45-Grad-Fase zur Seitenwand
// (Gehaeuse wird mit der Front aufs Bett gedruckt -> Fase ist die Unterseite, druckbar ohne Stuetzen)
// Unten ohne Fase (dort sitzen die Kontermuttern der Kabelverschraubungen); 7 mm in der Ecke ueberbrueckt PETG problemlos
module eckblock(x0, y0, wand_links, fase = true) {
    z0 = tb;  z1 = tb + cb_h;
    hull() {
        translate([x0, y0, z0]) cube([cb, cb, z1 - z0]);
        if (fase) translate([wand_links ? x0 : x0 + cb - 0.01, y0, z1 + cb]) cube([0.01, cb, 0.01]);
    }
}

// ---------------- Gehaeuse (Einbaulage, Front = +Z, offen nach hinten) ----------------
module gehaeuse() {
    difference() {
        union() {
            difference() {
                translate([0, 0, tb]) linear_extrude(H - tb) outer2d();
                translate([0, 0, tb - 1]) linear_extrude(H - tb + 2) rr(iw, ih, ri);
            }
            // Front nur hinter dem Klemmendeckel (keine koplanare Schnittflaeche bei Z = H -> kein Z-Fighting in der Vorschau)
            translate([0, 0, H - 0.01]) linear_extrude(tl + 0.01) intersection() {
                outer2d();
                translate([-t - 1, y_split]) square([iw + 2 * t + 2, ih + 2 * t]);
            }
            for (x = [0, iw - cb], y = [0, ih - cb]) eckblock(x, y, x == 0, y > 0);
            // Quersteg und Schraubbloecke fuer den Klemmendeckel (wachsen beim Druck von der Front aus)
            translate([0, beam_y0, beam_z0]) cube([iw, beam_y1 - beam_y0, H - beam_z0]);
            // Schulter: Front und Quersteg sind sonst nur ueber eine Kante verbunden (Duennstelle)
            translate([0, beam_y0, shoulder_z0]) cube([iw, y_split + shoulder_w - beam_y0, H - shoulder_z0]);
            for (x = [0, iw - kcb], y = [0, beam_y0 - kcb]) translate([x, y, kblk_z0]) cube([kcb, kcb, H - kblk_z0]);
            // Dome fuer den PIR (M2) und den Tastenhalter (Einschmelzmutter M3)
            for (s = [-1, 1]) translate([pir_c[0] + s * pir_hole_dx, pir_c[1], H - pir_boss_h]) cylinder(d = 3.8, h = pir_boss_h + 0.01);   // D 3,8: frei neben der Linsenplatte
            translate([sw_c[0], sw_c[1], tube_z0]) cylinder(d = tube_od, h = H - tube_z0 + 0.01);   // Fuehrungsrohr fuer den Tastenstift
        }
        // Dichtungsnut fuer den Klemmendeckel + Einschmelzmuttern
        translate([0, 0, H - gd]) linear_extrude(gd + 1) kgroove2d(kgw);
        for (p = klemm_pts) translate([p[0], p[1], H - ins_l]) cylinder(d = ins_d, h = ins_l + 1);
        // Dichtungsnut im hinteren Rand
        translate([0, 0, tb - 1]) linear_extrude(gd + 1) groove2d(gw);
        // Einschmelzmuttern fuer den Bodendeckel
        for (p = deck_pts) translate([p[0], p[1], tb - 1]) cylinder(d = ins_d, h = ins_l + 1);
        // Kabelverschraubungen unten
        for (x = glands_x) translate([x, 1, gland_z]) rotate([90, 0, 0]) cylinder(d = gland_d, h = t + 2);
        // Linsenoeffnung mit 45-Grad-Fase
        translate([pir_c[0], pir_c[1], H - 1]) cylinder(d = 2 * dome_r + 0.6, h = tl + 2);
        translate([pir_c[0], pir_c[1], H + 0.5]) cylinder(d1 = 2 * dome_r + 0.6, d2 = 2 * dome_r + 0.6 + 2 * (tl - 0.5) + 0.02, h = tl - 0.5 + 0.01);
        // PIR-Schrauben M2 (Kunststoff-Schneidschraube), nicht durchgehend
        for (s = [-1, 1]) translate([pir_c[0] + s * pir_hole_dx, pir_c[1], H - pir_boss_h - 1]) cylinder(d = 1.7, h = pir_boss_h + 1 + tl - 0.6);
        // Tastendurchfuehrung + Markierungsring aussen
        translate([sw_c[0], sw_c[1], tube_z0 - 1]) cylinder(d = pin_d + pin_clear, h = H + tl - tube_z0 + 2);
        translate([sw_c[0], sw_c[1], H + tl - 0.5]) cylinder(d1 = pin_d + pin_clear, d2 = pin_d + pin_clear + 1.02, h = 0.51);   // Fase aussen
        translate([sw_c[0], sw_c[1], H + tl - 0.3]) difference() { cylinder(d = 9.6, h = 1); cylinder(d = 8.4, h = 1); }
    }
}

// ---------------- Bodendeckel (Einbaulage, Wandseite = Z 0) ----------------
module bodendeckel() {
    difference() {
        union() {
            linear_extrude(tb) bodendeckel2d();
            // Zentrierkragen entlang der Waende (zwischen den Eckbloecken)
            translate([0, 0, tb - 0.01]) linear_extrude(2.01) intersection() {
                difference() { offset(r = -0.4) rr(iw, ih, ri); offset(r = -1.8) rr(iw, ih, ri); }
                union() {
                    translate([0, cb + 0.5]) square([iw, ih - 2 * cb - 1]);
                    translate([cb + 0.5, 0]) square([iw - 2 * cb - 1, ih]);
                }
            }
            // Platinendome
            for (h = pcb_holes) translate(concat(b2g(h), [tb - 0.01])) cylinder(d = standoff_d, h = standoff_h + 0.01);
        }
        for (h = pcb_holes) translate(concat(b2g(h), [pcb_z - ins_l])) cylinder(d = ins_d, h = ins_l + 1);
        // Deckelschrauben M3 Senkkopf, von der Wandseite buendig
        for (p = deck_pts) translate([p[0], p[1], -1]) {
            cylinder(d = 3.4, h = tb + 2);
            cylinder(d1 = 6.6 + 2, d2 = 3.4, h = 1 + 1.8);
        }
        // Wandlaschen
        for (sl = lug_slots) translate([iw / 2, sl[0], -1]) linear_extrude(tb + 2) rotate(sl[1]) langloch2d(lug_hole, lug_slot);
    }
}

// ---------------- Klemmendeckel (Einbaulage, aussen = +Z) ----------------
module klemmdeckel() {
    difference() {
        translate([0, 0, H]) linear_extrude(tl) klemmdeckel2d();
        // M3 Senkkopf, buendig
        for (p = klemm_pts) translate([p[0], p[1], H - 1]) {
            cylinder(d = 3.4, h = tl + 2);
            translate([0, 0, 1 + tl - 1.8]) cylinder(d1 = 3.4, d2 = 6.6, h = 1.81);
        }
    }
}

// ---------------- Tastenstift (z = 0: Unterseite Kopf, liegt auf dem Taster) ----------------
module tastenstift() {
    cylinder(d = pin_head_d, h = pin_head_t);
    cylinder(d = pin_d, h = pin_len - 0.5);
    translate([0, 0, pin_len - 0.5]) cylinder(d1 = pin_d, d2 = pin_d - 1, h = 0.5);   // Fase oben
}

// ---------------- Kleinteile ----------------
module klemmdichtung() { linear_extrude(ksh) offset(r = -(kgw - ksw) / 2) kgroove2d(kgw); }
module dichtung() { linear_extrude(sh) offset(r = -(gw - sw) / 2) groove2d(gw); }
module linsendichtung() { linear_extrude(lens_gasket_t) difference() { square([lens_plate, lens_plate], center = true); circle(r = dome_r + 0.2); } }
module regenschutz() {
    intersection() {
        difference() { cylinder(r = dome_r + 6.5, h = 14); translate([0, 0, -1]) cylinder(r = dome_r + 4.5, h = 16); }
        translate([-30, 0, 0]) cube([60, 30, 14]);
    }
    linear_extrude(1.2) difference() { intersection() { circle(r = dome_r + 9); translate([-30, 0]) square([60, 30]); } circle(r = dome_r + 4.5); }
}

// ---------------- Einbaulage ----------------
module taster_baugruppe() {
    translate([sw_c[0], sw_c[1], sw_top]) tastenstift();
}

// ---------------- Platzhalter fuer die Kollisionspruefung ----------------
pcb_parts = [ // [x, y Modulkoordinaten (Mitte), Breite, Hoehe(y), Bauhoehe, z-Start]
    [11.43, 8.9, 25.6, 34.2, 5.5, 8.5],
    [0, 8.89, 2.6, 20.4, 8.5, 0], [22.86, 8.89, 2.6, 20.4, 8.5, 0],
    [19.05, 28.6, 10.6, 4.6, 20, 0], [19.05, 34.3, 10.6, 4.6, 20, 0],          // L7805, IRLB8721
    [5.08, 42.2, 10.2, 9.8, 13.8, 0], [17.78, 42.2, 10.2, 9.8, 13.8, 0],       // Klemmen
    [8.6, 31.04, 6.2, 6.2, 3.5, 0],
    [6.35, 19.05, 3, 10.2, 3, 0], [11.2, 22.88, 3, 4, 5, 0], [12.72, 16.51, 5.5, 5.5, 6, 0],
    [19.05, 13.97, 2.6, 10.2, 2.6, 0], [13.97, 6.35, 2.6, 10.2, 2.6, 0]];
// Raum, den die bestueckte Platine beim Einsetzen von hinten (in +Z bis zur Endlage) ueberstreicht, 0,3 mm Luft
module platine_sweep() {
    translate([bx0 - 0.3, by0 - 0.3, 0]) cube([pcb_w + 0.6, pcb_h + 0.6, pcb_z + pcb_t]);
    z = pcb_z + pcb_t;
    for (p = pcb_parts) { g = m2g([p[0], p[1]]); translate([g[0] - p[2] / 2 - 0.3, g[1] - p[3] / 2 - 0.3, 0]) cube([p[2] + 0.6, p[3] + 0.6, z + p[5] + p[4]]); }
}
// Schraubendreher (D 3 mm) senkrecht auf die vier Klemmenschrauben, bei abgenommenem Klemmendeckel
module schraubendreher() {
    for (x = [2.54, 7.62, 15.24, 20.32]) { g = m2g([x, 42.545 + 0.2]); translate([g[0], g[1], term_top]) cylinder(d = 3, h = 40); }
}
// Kontermuttern der Kabelverschraubungen innen, Sechskant mit einer Schluesselflaeche zur Seitenwand
module kontermutter_dummy() {
    for (x = glands_x) translate([x, 0, gland_z]) rotate([-90, 0, 0]) rotate([0, 0, 30]) cylinder(d = gland_nut_af / cos(30), h = gland_nut_t, $fn = 6);
}
module platine_dummy() {
    translate([bx0, by0, pcb_z]) cube([pcb_w, pcb_h, pcb_t]);
    z = pcb_z + pcb_t;
    for (p = pcb_parts) { g = m2g([p[0], p[1]]); translate([g[0] - p[2] / 2, g[1] - p[3] / 2, z + p[5]]) cube([p[2], p[3], p[4]]); }
    // Loetstellen auf der Unterseite (Pad-Radius + 0,2 mm, 2 mm hoch) – die Abstandshalter duerfen sie nicht beruehren
    for (p = pcb_pads) translate(concat(b2g(p), [pcb_z - 2])) cylinder(r = p[2] + 0.2, h = 2);
}
// THT-Pads [x, y, Radius] in Platinenkoordinaten (aus KiCad)
pcb_pads = [[9.15, 43.29, 1.00], [9.15, 36.79, 1.00], [13.65, 43.29, 1.00], [13.65, 36.79, 1.00], [24.39, 42.02, 1.00],
    [21.85, 42.02, 1.00], [19.31, 42.02, 1.00], [16.77, 25.51, 0.80], [14.27, 25.51, 0.80], [19.31, 38.84, 1.00],
    [21.85, 38.84, 1.00], [24.39, 38.84, 1.00], [16.77, 10.27, 0.80], [16.77, 20.43, 0.80], [2.80, 30.59, 0.85],
    [2.80, 33.13, 0.85], [2.80, 35.67, 0.85], [18.04, 51.54, 1.30], [23.12, 51.54, 1.30], [5.34, 51.54, 1.30],
    [10.42, 51.54, 1.30], [9.15, 33.13, 1.10], [9.15, 22.97, 1.10], [14.00, 33.13, 0.80], [14.00, 30.63, 0.80],
    [21.85, 17.89, 0.80], [21.85, 28.05, 0.80], [2.80, 9.00, 1.00], [2.80, 11.54, 1.00], [2.80, 14.08, 1.00],
    [2.80, 16.62, 1.00], [2.80, 19.16, 1.00], [2.80, 21.70, 1.00], [2.80, 24.24, 1.00], [2.80, 26.78, 1.00],
    [25.66, 26.78, 1.00], [25.66, 24.24, 1.00], [25.66, 21.70, 1.00], [25.66, 19.16, 1.00], [25.66, 16.62, 1.00],
    [25.66, 14.08, 1.00], [25.66, 11.54, 1.00], [25.66, 9.00, 1.00]];
module pir_dummy() {
    zp = H - pir_boss_h;   // Vorderseite PIR-Platine
    translate([pir_c[0], pir_c[1], 0]) difference() {
        union() {
            translate([-lens_plate / 2, -lens_plate / 2, zp]) cube([lens_plate, lens_plate, lens_plate_t]);
            translate([0, 0, zp + lens_plate_t]) sphere(r = dome_r);
            translate([-pir_pcb[0] / 2, -pir_pcb[1] / 2, zp - pir_pcb_t]) cube([pir_pcb[0], pir_pcb[1], pir_pcb_t]);
            translate([-12.5, -11, zp - pir_pcb_t - 9]) cube([25, 22, 9]);
            for (p = [[14, 9.5], [-14, 9.5], [-14, -9.5], [8.5, -10]]) translate([p[0], p[1], zp - pir_pcb_t - 9]) cylinder(r = 1.6, h = 9);
            translate([-4, -pir_pcb[1] / 2 + 0.3, zp - pir_pcb_t - 9]) cube([8, 2.6, 9]);
        }
        for (s = [-1, 1]) translate([s * pir_hole_dx, 0, zp - 20]) cylinder(d = 2.0, h = 25);   // Befestigungsloecher
    }
}

// ---------------- Ausgabe ----------------
if (part == "gehaeuse") rotate([180, 0, 0]) translate([0, 0, -H - tl]) gehaeuse();   // Front aufs Bett
else if (part == "bodendeckel") bodendeckel();                                         // Wandseite aufs Bett
else if (part == "klemmdeckel") rotate([180, 0, 0]) translate([0, 0, -H - tl]) klemmdeckel();   // Aussenseite aufs Bett
else if (part == "dichtung") dichtung();
else if (part == "klemmdichtung") klemmdichtung();
else if (part == "linsendichtung") linsendichtung();
else if (part == "tastenstift") tastenstift();                                          // Kopf aufs Bett
else if (part == "regenschutz") regenschutz();
else if (part == "none") { }
// Kollisionspruefungen (muessen leer sein)
else if (part == "kollision") intersection() { union() { gehaeuse(); bodendeckel(); klemmdeckel(); } union() { platine_dummy(); pir_dummy(); } }
// Stift in Ruhelage (Kopf liegt auf dem Taster; nur der Tasterstoessel selbst ist nicht im Platinenmodell)
else if (part == "kollision_taster") intersection() { taster_baugruppe(); union() { platine_dummy(); pir_dummy(); bodendeckel(); gehaeuse(); } }
else if (part == "kollision_kontermutter") intersection() { kontermutter_dummy(); union() { gehaeuse(); bodendeckel(); klemmdeckel(); platine_dummy(); } }
else if (part == "kollision_bodendeckel") intersection() { bodendeckel(); gehaeuse(); }
else if (part == "kollision_klemmdeckel") intersection() { klemmdeckel(); gehaeuse(); }
else if (part == "kollision_schraubendreher") intersection() { gehaeuse(); schraubendreher(); }
// Bestueckte Platine muss von hinten in ihre Endlage geschoben werden koennen
else if (part == "kollision_einbau") intersection() { gehaeuse(); platine_sweep(); }
else {
    color("lightgray") translate([0, 0, 30]) gehaeuse();
    color("orange", 0.9) translate([0, 0, 50]) klemmdeckel();
    color("black") translate([0, 0, 30 + H + 8]) klemmdichtung();
    color("black") translate([0, 0, 15]) dichtung();
    color("white") bodendeckel();
    color("green") platine_dummy();
    color("ivory") translate([0, 0, 30]) { pir_dummy(); taster_baugruppe(); }
}
