// Funklicht v1.3 – Aussengehaeuse fuer die Platine 28,46 x 57 mm
// Zweiteiliger Deckel:
//   - hinterer Deckel (PIR + Taster): verschraubt, rundum gedichtet (Nut im Unterteil inkl. Quersteg)
//   - Klemmenabdeckung: wird nur eingeklipst -> Klemmenschrauben frei zugaenglich
// HC-SR501 an seinen zwei Befestigungsloechern direkt an den Deckel geschraubt (M2).
// Taster von aussen ueber nachgiebige TPU-Tastenkappe (Faltenmembran) + gefuehrten PETG-Stoessel.
// Material: PETG (unterteil, deckel, klemmdeckel, tastenhalter, stoessel, regenschutz)
//           TPU 95A (dichtung, linsendichtung, tastenkappe)
// Export:  openscad -D 'part="unterteil"' -o unterteil.stl Funklicht_Gehaeuse.scad
part = "baugruppe";
$fn = 64;

// ---------------- Hauptmasse (mm) ----------------
iw = 34;  ih = 72;  id = 36;     // Innenraum (Breite: PIR-Platine 32 mm)
t = 4;  tb = 3;  tl = 3;         // Wand, Rueckwand, Deckel
ri = 1;  ro = 4;
H = tb + id;                     // Dichtflaeche bei Z = H

ins_d = 4.0; ins_l = 6.4;        // Einschmelzmutter M3 (z. B. M3 x 5,7, Aussen-D 4,6)
gw = 2.0; gd = 2.0; g_in = 0.8;  // Dichtungsnut (beginnt 0,8 mm hinter der Innenkante)
sw = 1.8; sh = 2.6;              // TPU-Dichtschnur (0,6 mm Verpressung)

// ---------------- Platine (aus KiCad) ----------------
pcb_w = 28.46; pcb_h = 57.0; pcb_t = 1.6;
pcb_holes = [[4.07, 41.385], [24.0, 32.0], [7.88, 11.54]];   // H1, H2 (am 26.11. verschoben), H3
bx0 = (iw - pcb_w) / 2;  by0 = 13;
standoff_h = 6;  standoff_d = 6.5;   // D 6,5: frei neben den Loetstellen (R1 an H2: 0,45 mm Luft)
pcb_z = tb + standoff_h;
function b2g(p) = [bx0 + p[0], by0 + pcb_h - p[1]];
function m2g(p) = b2g([p[0] + 2.8, p[1] + 9.0]);

// Schraubklemmen (3D-Modell Phoenix MKDS 1,5): Schraube ueber dem Pin, Oberkante 13,8 mm
term_top = pcb_z + pcb_t + 13.8;
term_screw_y = m2g([0, 42.545 + 0.2])[1];

// ---------------- Trennung Klemmenraum / Elektronikraum ----------------
beam_y0 = term_screw_y + 1.95;   // Schraubendreher D 3 mm hat Platz
beam_y1 = beam_y0 + 3.6;         // Quersteg traegt die Dichtung
beam_z0 = term_top + 1.0;        // Unterkante Steg (ueber den Klemmen)
blk_y = [beam_y0 - 0.7, beam_y1 + 2.7];   // Schraubbloecke an den Stegenden
blk_w = 6.5;  blk_z0 = 33.5;     // Bloecke (mit Fase) frei ueber dem MOSFET
cb = 7;  cb_z0 = 28.0;           // Eckbloecke oben (Fase frei ueber dem D1 mini)
screw_beam_y = beam_y1 - 0.3;    // Deckelschrauben an den Stegenden
deck_pts = [[0, screw_beam_y], [iw, screw_beam_y], [0, ih], [iw, ih]];

gland_d = 12.4;  glands_x = [9, 25];      // M12 x 1,5

// Clip der Klemmenabdeckung
clip_y = [5.5, 14.5];  clip_len = 8.5;  clip_t = 1.2;  clip_hook = 0.6;

// ---------------- HC-SR501 ----------------
pir_c = [iw / 2, 48.5];
pir_pcb = [32, 25]; pir_pcb_t = 1.6;
pir_hole_dx = 14.0;              // Lochabstand 28 mm (am Bauteil gemessen)
lens_plate = 24; lens_plate_t = 2; dome_r = 11.5;
lens_gasket_t = 1.0; lens_gasket_press = 0.3;
pir_boss_h = lens_plate_t + lens_gasket_t - lens_gasket_press;   // Platine liegt auf den Domen

// ---------------- Taster-Durchfuehrung ----------------
sw_c = m2g([8.6, 31.04]);
sw_top = pcb_z + pcb_t + 5.0;    // Taster 6x6x5
cap_stem_d = 5.0;  cap_hole_d = 5.8;
cap_flange_r = [4.6, 5.5]; cap_flange_t = 1.6;
arch_r = 3.75; arch_rad = 0.85; arch_t = 0.5;     // Falte der Membran
pocket_d = 11.2; pocket_p = 1.2;
cap_proj = 0.6;
cap_h = tl + cap_proj + (cap_flange_t - pocket_p);
ret_boss = [[-9, 2.0], [9, -2.0]];                // Dome des Tastenhalters (relativ zur Tastermitte)
ret_boss_h = 4.0; ret_t = 2.0;
ring_r = [4.9, 5.6];
plunger_d = 4.0; head_d = 7.0; head_t = 1.0; plunger_gap = 0.3;

// ---------------- 2D-Formen ----------------
module rr(w, h, r) { translate([r, r]) offset(r = r) square([w - 2 * r, h - 2 * r]); }
module outer2d() { translate([-t, -t]) rr(iw + 2 * t, ih + 2 * t, ro); }
// Elektronikraum (vom hinteren Deckel gedichtet)
module seal_region2d() {
    difference() {
        translate([0, beam_y1]) square([iw, ih - beam_y1]);
        for (x = [0, iw - cb]) translate([x, ih - cb]) square(cb);
        for (x = [0, iw - blk_w]) translate([x, blk_y[0]]) square([blk_w, blk_y[1] - blk_y[0]]);
    }
}
module groove2d(w) {
    c = g_in + gw / 2;
    intersection() {
        difference() { offset(r = c + w / 2) seal_region2d(); offset(r = c - w / 2) seal_region2d(); }
        translate([-t, beam_y0]) square([iw + 2 * t, ih + t]);
    }
}
// Umriss hinterer Deckel / Klemmenabdeckung
module deckel2d()    { intersection() { outer2d(); translate([-t - 1, beam_y0]) square([iw + 2 * t + 2, ih + 2 * t]); } }
module klemmdeckel2d() { intersection() { outer2d(); translate([-t - 1, -t - 1]) square([iw + 2 * t + 2, beam_y0 - 0.3 + t + 1]); } }

// Block, der an der Wand haengt (unten 45-Grad-Fase -> druckbar ohne Stuetzen)
module haengeblock(x0, y0, w, h, z0, wand_links) {
    hull() {
        translate([x0, y0, z0]) cube([w, h, H - z0]);
        translate([wand_links ? x0 : x0 + w - 0.01, y0, z0 - w]) cube([0.01, h, 0.01]);
    }
}

// ---------------- Unterteil ----------------
module unterteil() {
    difference() {
        union() {
            difference() {
                linear_extrude(H) outer2d();
                translate([0, 0, tb]) linear_extrude(H) rr(iw, ih, ri);
            }
            // Quersteg mit Schraubbloecken
            translate([0, beam_y0, beam_z0]) cube([iw, beam_y1 - beam_y0, H - beam_z0]);
            haengeblock(0, blk_y[0], blk_w, blk_y[1] - blk_y[0], blk_z0, true);
            haengeblock(iw - blk_w, blk_y[0], blk_w, blk_y[1] - blk_y[0], blk_z0, false);
            // Eckbloecke oben
            haengeblock(0, ih - cb, cb, cb, cb_z0, true);
            haengeblock(iw - cb, ih - cb, cb, cb, cb_z0, false);
            // Wandlaschen
            for (y = [-t - 11, ih + t]) translate([iw / 2 - 11, y, 0]) cube([22, 11, tb]);
        }
        translate([0, 0, H - gd]) linear_extrude(gd + 1) groove2d(gw);
        for (p = deck_pts) translate([p[0], p[1], H - ins_l]) cylinder(d = ins_d, h = ins_l + 1);
        for (x = glands_x) translate([x, 1, tb + id / 2]) rotate([90, 0, 0]) cylinder(d = gland_d, h = t + 2);
        for (y = [-t - 5.5, ih + t + 5.5]) translate([iw / 2, y, -1]) cylinder(d = 4.8, h = tb + 2);
        // Ablauf im Klemmenraum
        translate([iw / 2, 1, tb + 1.5]) rotate([90, 0, 0]) cylinder(d = 2.5, h = t + 2);
        // Rastnischen fuer die Klemmenabdeckung
        for (x = [-clip_hook - 0.1, iw]) translate([x, clip_y[0] - 0.5, H - clip_len - 0.3]) cube([clip_hook + 0.1, clip_y[1] - clip_y[0] + 1, 2.0]);
    }
    for (h = pcb_holes) translate(concat(b2g(h), [tb - 0.01]))
        difference() { cylinder(d = standoff_d, h = standoff_h); translate([0, 0, standoff_h - ins_l]) cylinder(d = ins_d, h = ins_l + 1); }
}

// ---------------- Hinterer Deckel (Einbaulage, aussen = +Z) ----------------
module deckel() {
    difference() {
        union() {
            translate([0, 0, H]) linear_extrude(tl) deckel2d();
            // Zentrierkragen entlang der Waende (nur Seiten und oben)
            translate([0, 0, H - 2]) linear_extrude(2.01) intersection() {
                difference() { offset(r = -0.4) rr(iw, ih, ri); offset(r = -1.8) rr(iw, ih, ri); }
                translate([0, blk_y[1] + 0.5]) square([iw, ih - cb - blk_y[1] - 1]);
            }
            // Dome fuer den PIR (M2) und den Tastenhalter (Einschmelzmutter M3)
            for (s = [-1, 1]) translate([pir_c[0] + s * pir_hole_dx, pir_c[1], H - pir_boss_h]) cylinder(d = 3.8, h = pir_boss_h + 0.01);   // D 3,8: frei neben der Linsenplatte
            for (b = ret_boss) translate([sw_c[0] + b[0], sw_c[1] + b[1], H - ret_boss_h]) cylinder(d = 7.5, h = ret_boss_h + 0.01);
        }
        // Linsenoeffnung mit 45-Grad-Fase
        translate([pir_c[0], pir_c[1], H - 1]) cylinder(d = 2 * dome_r + 0.6, h = tl + 2);
        translate([pir_c[0], pir_c[1], H + 0.5]) cylinder(d1 = 2 * dome_r + 0.6, d2 = 2 * dome_r + 0.6 + 2 * (tl - 0.5) + 0.02, h = tl - 0.5 + 0.01);
        // PIR-Schrauben M2 (Kunststoff-Schneidschraube), nicht durchgehend
        for (s = [-1, 1]) translate([pir_c[0] + s * pir_hole_dx, pir_c[1], H - pir_boss_h - 1]) cylinder(d = 1.7, h = pir_boss_h + 1 + tl - 0.6);
        // Deckelschrauben M3 Senkkopf, buendig
        for (p = deck_pts) translate([p[0], p[1], H - 1]) {
            cylinder(d = 3.4, h = tl + 2);
            translate([0, 0, 1 + tl - 1.8]) cylinder(d1 = 3.4, d2 = 6.6, h = 1.81);
        }
        for (b = ret_boss) translate([sw_c[0] + b[0], sw_c[1] + b[1], H - ret_boss_h - 1]) cylinder(d = ins_d, h = ret_boss_h + 1 + tl - 0.6);
        // Tastendurchfuehrung + Markierungsring aussen
        translate([sw_c[0], sw_c[1], H - 1]) cylinder(d = cap_hole_d, h = tl + 2);
        translate([sw_c[0], sw_c[1], H - 1]) cylinder(d = pocket_d, h = 1 + pocket_p);
        translate([sw_c[0], sw_c[1], H + tl - 0.3]) difference() { cylinder(d = 9.6, h = 1); cylinder(d = 8.4, h = 1); }
    }
}

// ---------------- Klemmenabdeckung (wird eingeklipst) ----------------
module klemmdeckel() {
    difference() {
        translate([0, 0, H]) linear_extrude(tl) klemmdeckel2d();
        // Griffmulde unten (Fingernagel / Schraubendreher zum Abhebeln)
        translate([iw / 2 - 6, -t - 1, H + tl - 1.2]) cube([12, 3.5, 2]);
    }
    // Schnapphaken links und rechts
    for (s = [0, 1]) {
        x = s == 0 ? 0.3 : iw - 0.3 - clip_t;
        translate([x, clip_y[0], H - clip_len]) cube([clip_t, clip_y[1] - clip_y[0], clip_len + 0.01]);
        // Haken mit Einfuehrschraege
        translate([s == 0 ? x : x + clip_t, clip_y[0], H - clip_len]) mirror([s == 0 ? 0 : 1, 0, 0])
            rotate([90, 0, 0]) translate([0, 0, -(clip_y[1] - clip_y[0])]) linear_extrude(clip_y[1] - clip_y[0])
                polygon([[0, 0], [-clip_hook - 0.3, 1.1], [-clip_hook - 0.3, 1.6], [0, 1.6]]);
    }
}

// ---------------- Taster: TPU-Kappe, Halter, Stoessel ----------------
module tastenkappe() {   // z = 0: Unterseite Flansch = Druckbett
    cylinder(d = cap_stem_d, h = cap_h);
    rotate_extrude() {
        translate([cap_stem_d / 2 - 0.1, 0]) square([arch_r - arch_rad - cap_stem_d / 2 + 0.2, arch_t]);   // Anschluss an den Stoessel
        translate([arch_r, arch_t / 2]) intersection() {                                                   // Falte
            difference() { circle(r = arch_rad + arch_t / 2); circle(r = arch_rad - arch_t / 2); }
            translate([-2, 0]) square([4, 2]);
        }
        translate([cap_flange_r[0], 0]) square([cap_flange_r[1] - cap_flange_r[0], cap_flange_t]);        // Flansch
    }
}
module tastenhalter() {   // z = 0: Unterseite Platte
    ring_h = ret_boss_h - (cap_flange_t - pocket_p) + 0.3;
    difference() {
        union() {
            hull() for (b = ret_boss) translate([b[0], b[1], 0]) cylinder(d = 8, h = ret_t);
            translate([0, 0, ret_t - 0.01]) difference() { cylinder(r = ring_r[1], h = ring_h); cylinder(r = ring_r[0], h = ring_h + 1); }
        }
        translate([0, 0, -1]) cylinder(d = plunger_d + 0.5, h = ret_t + 2);
        for (b = ret_boss) translate([b[0], b[1], -1]) cylinder(d = 3.4, h = ret_t + 2);
    }
}
function plunger_len() = (H - (cap_flange_t - pocket_p)) - head_t - (sw_top + plunger_gap);
module stoessel() {
    cylinder(d = plunger_d, h = plunger_len());
    translate([0, 0, plunger_len()]) cylinder(d = head_d, h = head_t);
}

// ---------------- Kleinteile ----------------
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
    translate([sw_c[0], sw_c[1], H - (cap_flange_t - pocket_p)]) tastenkappe();
    translate([sw_c[0], sw_c[1], H - ret_boss_h - ret_t]) tastenhalter();
    translate([sw_c[0], sw_c[1], sw_top + plunger_gap]) stoessel();
}

// ---------------- Platzhalter fuer die Kollisionspruefung ----------------
module platine_dummy() {
    translate([bx0, by0, pcb_z]) cube([pcb_w, pcb_h, pcb_t]);
    z = pcb_z + pcb_t;
    parts = [ // [x, y Modulkoordinaten (Mitte), Breite, Hoehe(y), Bauhoehe, z-Start]
        [11.43, 8.9, 25.6, 34.2, 5.5, 8.5],
        [0, 8.89, 2.6, 20.4, 8.5, 0], [22.86, 8.89, 2.6, 20.4, 8.5, 0],
        [19.05, 28.6, 10.6, 4.6, 20, 0], [19.05, 34.3, 10.6, 4.6, 20, 0],          // L7805, IRLB8721
        [5.08, 42.2, 10.2, 9.8, 13.8, 0], [17.78, 42.2, 10.2, 9.8, 13.8, 0],       // Klemmen
        [8.6, 31.04, 6.2, 6.2, 3.5, 0],
        [6.35, 19.05, 3, 10.2, 3, 0], [11.2, 22.88, 3, 4, 5, 0], [12.72, 16.51, 5.5, 5.5, 6, 0],
        [19.05, 13.97, 2.6, 10.2, 2.6, 0], [13.97, 6.35, 2.6, 10.2, 2.6, 0]];
    for (p = parts) { g = m2g([p[0], p[1]]); translate([g[0] - p[2] / 2, g[1] - p[3] / 2, z + p[5]]) cube([p[2], p[3], p[4]]); }
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
// Schraubendreher (D 3 mm) senkrecht auf die vier Klemmenschrauben, bei abgenommener Abdeckung
module schraubendreher() {
    for (x = [2.54, 7.62, 15.24, 20.32]) { g = m2g([x, 42.545 + 0.2]); translate([g[0], g[1], term_top]) cylinder(d = 3, h = 40); }
}
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
if (part == "unterteil") unterteil();
else if (part == "deckel") rotate([180, 0, 0]) translate([0, 0, -H - tl]) deckel();
else if (part == "klemmdeckel") rotate([180, 0, 0]) translate([0, 0, -H - tl]) klemmdeckel();
else if (part == "dichtung") dichtung();
else if (part == "linsendichtung") linsendichtung();
else if (part == "tastenkappe") tastenkappe();
else if (part == "tastenhalter") tastenhalter();
else if (part == "stoessel") rotate([180, 0, 0]) translate([0, 0, -plunger_len() - head_t]) stoessel();
else if (part == "regenschutz") regenschutz();
else if (part == "none") { }
// Kollisionspruefungen (muessen leer sein)
else if (part == "kollision") intersection() { union() { unterteil(); deckel(); klemmdeckel(); } union() { platine_dummy(); pir_dummy(); } }
else if (part == "kollision_schraubendreher") intersection() { union() { unterteil(); deckel(); } schraubendreher(); }
else if (part == "kollision_taster") intersection() { taster_baugruppe(); union() { platine_dummy(); pir_dummy(); unterteil(); klemmdeckel(); } }
else if (part == "kollision_deckel") intersection() { deckel(); union() { unterteil(); klemmdeckel(); } }
else if (part == "kollision_klemmdeckel") intersection() { klemmdeckel(); unterteil(); }
else {
    color("lightgray") unterteil();
    color("white", 0.7) translate([0, 0, 25]) { deckel(); taster_baugruppe(); }
    color("orange", 0.8) translate([0, 0, 40]) klemmdeckel();
    color("black") translate([0, 0, H - gd + 0.01]) dichtung();
    color("green") platine_dummy();
    color("ivory") translate([0, 0, 25]) pir_dummy();
}
