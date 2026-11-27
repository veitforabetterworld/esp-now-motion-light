# Funklicht – vernetzter Außen-Bewegungsmelder mit 12-V-Lampe

Wemos D1 mini (ESP8266, Funk per ESP-NOW) + HC-SR501 + MOSFET auf einer **einseitigen THT-Platine (28,5 × 57 mm, v1.2)**,
in einem 3D-gedruckten, **spritzwassergeschützten Gehäuse**. Pro Board: 1 Bewegungsmelder, 1 Lampe, 1 Taster.

## Ordner

| Pfad | Inhalt |
|---|---|
| `hardware/Funklicht.kicad_pro` | KiCad-10-Projekt (Schaltplan + Platine), ERC/DRC fehlerfrei |
| `hardware/jlcpcb/Funklicht_JLCPCB_Gerber.zip` | **Fertig zum Hochladen bei JLCPCB** |
| `hardware/jlcpcb/Stueckliste.csv` | Stückliste |
| `hardware/Funklicht_Schaltplan.pdf`, `Funklicht_3D_*.png`, `Funklicht_Platine.step` | Schaltplan, Ansichten, 3D-Modell |
| `hardware/lib/` | Projekt-Footprints (D1 mini auf Buchsenleisten, Lötaugen PIR, M3-Loch). PIR-Maße nach dem 3D-Modell von [ccadic/HC-SR501](https://github.com/ccadic/HC-SR501) |
| `hardware/scripts/` | Python-Skripte, die Schaltplan und Platine erzeugen (mit KiCads `python.exe` ausführen) |
| `firmware/Funklicht/` | Firmware (ESP-NOW), Einstellungen und Lampentabelle in `config.h` |
| `gehaeuse/Funklicht_Gehaeuse.scad` | Parametrisches Gehäuse (OpenSCAD) |
| `gehaeuse/stl/` | Druckdateien |

## Schaltung

```
12V ─┬──────────────────────────────── Lampe +        Lampe − ── Drain IRLB8721 ── Source ── GND
     ├── HC-SR501 VCC (12 V)                                       Gate ── 220 Ω ── D1 (GPIO5)
     └── 1N4007 ── L7805 ── 5V D1 mini                                     └ 10 kΩ ── GND
```

| D1 mini | Funktion |
|---|---|
| D1 (GPIO5) | MOSFET → Lampe (10 kΩ Pull-down: Lampe bleibt beim Booten aus) |
| D6 (GPIO12) | PIR-Ausgang (3,3 V) |
| D5 (GPIO14) | Taster nach GND (`INPUT_PULLUP`) |
| D4 (GPIO2) | blaue Onboard-LED (Status) |

- **Klemmen** an der Stirnseite: J1 = `+12V | GND` (Einspeisung), J2 = `+ | −` (Lampe).
- **PIR**: 3 Lötaugen `V O G` (VCC, OUT, GND) – Kabel direkt anlöten. Der PIR bekommt 12 V vor der
  Verpolschutzdiode; der HC-SR501 hat selbst eine Schutzdiode, trotzdem **Polarität beim Anschließen prüfen**.
- **Lampenstrom** bis ca. 3 A (Leiterbahnen 1,5 mm, Versorgung 0,8 mm, Signale 0,5 mm; MOSFET ohne Kühlkörper). Keine Freilaufdiode: nur für
  LED-/Halogenlampen gedacht, nicht für Motoren/Relais.

## Stückliste (pro Board)

| Anz. | Teil | Hinweis |
|---|---|---|
| 1 | Wemos D1 mini (ESP8266) | auf **2 × 8-polige Buchsenleisten 8,5 mm** stecken |
| 1 | HC-SR501 | Jumper auf **H** (wiederauslösend), Zeit-Poti auf Minimum |
| 1 | L7805 (TO-220) | stehend |
| 1 | IRLB8721PBF (TO-220) | Logic-Level-MOSFET, stehend |
| 1 | 1N4007 | Verpolschutz |
| 1 | 220 Ω, 1 | 10 kΩ | Widerstände 1/4 W |
| 1 | 1 µF Keramik, RM 2,5 | |
| 1 | 10 µF / 16 V Elko, Ø 5 mm, **max. 6 mm hoch** (z. B. 5 × 5) | sitzt **unter** dem D1 mini |
| 2 | Schraubklemme 2-polig, RM 5,08 | |
| 1 | Taster 6 × 6 × 5 mm, 4 Pins | Höhe 5 mm (Tastenstift ist darauf abgestimmt) |
| 11 | Einschmelzmutter M3 (z. B. M3 × 5,7, Bohrung 4,0 mm) | 4 Bodendeckel, 4 Klemmendeckel, 3 Platine |
| 4 | Senkkopfschraube M3 × 10 (DIN 7991) | Bodendeckel, bündig |
| 4 | Senkkopfschraube M3 × 8 (DIN 7991) | Klemmendeckel, bündig |
| 3 | Zylinderschraube M3 × 6 | Platine |
| 2 | Schneidschraube M2 × 6 (für Kunststoff) | PIR an die Front |
| 2 | Kabelverschraubung M12 × 1,5 | Kabel 3–6,5 mm |

## Platine bestellen (JLCPCB)

`hardware/jlcpcb/Funklicht_JLCPCB_Gerber.zip` hochladen. Einstellungen: **2 Lagen** (gleicher Preis wie 1 Lage,
durchkontaktierte Lötaugen lassen sich besser löten – Leiterbahnen liegen trotzdem nur unten), FR-4, 1,6 mm,
HASL. Kein Bestückungsservice nötig.

**Bestückungsdruck nur auf der Unterseite** (Lötseite), die Oberseite bleibt ohne Druck. Jedes Bauteil ist dort
mit Umriss, Symbol und Wert an seiner echten Position eingezeichnet. Die Platine lässt sich allein danach bestücken:
- Widerstände mit Wert (10 kΩ, 220 Ω), Diode 1N4007 mit Ring zur Kathode
- Elko 10 µF mit `+` am eckigen Pad, 1 µF-Kondensator
- L7805 und IRLB8721: Doppellinie = Kühlfahne (Metallseite)
- D1-mini-Buchsenleisten mit Pin-1-Pfeil (RST) und „Antenne hier“
- Taster, PIR-Lötaugen `V O G`, Klemmen `+12V GND` und Lampe `+ −`

Von unten gesehen ist alles spiegelbildlich zur Oberseite. Die Bauteile also von oben einstecken und an der Markierung
auf der Unterseite ausrichten.

**Bestücken** (flach nach hoch): R1, R2, D1, C1, C2 (unter dem D1 mini!), Taster, Buchsenleisten,
Klemmen, L7805, IRLB8721. PIR-Kabel (ca. 10 cm) an `V O G` löten. Danach D1 mini aufstecken.
Unter dem D1 mini nur Bauteile bis 6 mm Höhe. Die Lötaugen `V O G` liegen in der Aussparung des D1 mini.
**Zwei Befestigungsschrauben liegen unter dem D1 mini** – Platine erst festschrauben, dann den D1 mini aufstecken.

Befestigungslöcher (Platinenkoordinaten, Ursprung oben links): H1 (4,07 / 41,39), H2 (24,0 / 32,0), H3 (7,88 / 11,54).
Der Schaltplan (`Funklicht_Schaltplan.pdf`) ist durchgehend verdrahtet: Versorgung links, D1 mini in der Mitte,
Lampenschaltung rechts, +12V-Schiene oben, GND-Schiene unten.

## Gehäuse (v2.0)

Außen ca. 42 × 81,5 × 43 mm (ohne Wandlaschen). **Öffnung nach hinten zur Wand:**

- **Gehäuse** (Haube): Seitenwände und Front aus einem Stück. In der Front sitzen das PIR-Fenster und der Taster.
  Hinten ist das Gehäuse über den vollen Innenquerschnitt (34 × 73,5 mm) offen. Die Platine passt in Einbaulage gerade
  hindurch (geprüft, auch mit L7805/MOSFET).
- **Bodendeckel** (Wandseite): trägt die Platine auf drei Domen (Ø 6,5 mm, berühren keine Lötstelle) und die beiden
  Wandlaschen. Die Laschen haben gerundete Ecken und je ein Langloch (Ø 4,8 mm, 3 mm Verschiebeweg), um 45° gedreht und
  oben/unten spiegelbildlich (`/` und `\`). Zusammen gleichen die beiden Langlöcher ungenau gebohrte Wandlöcher in jeder Richtung aus.
  Der Bodendeckel wird mit 4 M3-Senkkopfschrauben von hinten bündig an das Gehäuse geschraubt. Die Schrauben greifen in
  Einschmelzmuttern in den vier Eckblöcken am hinteren Rand. Die Eckblöcke liegen außerhalb des Platinenumrisses.
- **Dichtung**: TPU-Schnur in einer Nut im hinteren Gehäuserand, innerhalb der Schrauben, rundum geschlossen.
  Die Dichtfläche liegt an der geschützten Wandseite, nicht mehr an der Front. Ein Zentrierkragen am Bodendeckel führt
  ihn ins Gehäuse.
- **PIR** (HC-SR501, Platine 32 × 24 mm): sitzt mittig auf der Front hinter dem Klemmendeckel. Er wird mit seinen
  **2 Befestigungslöchern** (Ø 2 mm, Abstand 28 mm, am Bauteil gemessen) von innen an zwei kurze Dome in der Front
  geschraubt (M2 × 6, Kunststoff-Schneidschraube / Blechschraube 2,2 mm). Die Löcher in den Domen (Ø 1,7 mm) sind
  Sacklöcher und von außen nicht sichtbar. Die Linsendichtung liegt zwischen Linsenplatte und Front.
- **Taster** bei geschlossenem Gehäuse: nur zwei Teile, die Front mit Führungsrohr und ein Tastenstift.
  - Das Loch in der Front ist als **Rohr** (außen Ø 7,6 mm, Bohrung Ø 4,4 mm) bis 1 mm über den Stiftkopf nach innen
    verlängert, rund 21 mm lange Führung.
  - Der **Tastenstift** (Ø 4 mm) hat unten einen Kopf (Ø 6,5 mm), der auf dem Taster aufliegt. Er steht in Ruhe 1 mm aus
    der Front; der Ring auf der Front markiert die Stelle. Der Kopf verhindert, dass der Stift nach außen herausfällt.
  - Die Stiftdurchführung ist **nicht gedichtet** (0,2 mm Spiel rundum). Bei senkrechter Front und waagrechtem Rohr
    kommt kaum Wasser hinein, ganz dicht wie die Deckel ist sie aber nicht.
- **Kabelverschraubungen** (2 × M12 × 1,5) in der unteren Stirnseite, 16 mm über der Dichtfläche und damit nahe an den
  Klemmeneingängen. Zwischen den Kontermuttern innen und den Klemmen bleiben knapp 4 mm, kein Leerraum mehr. Die
  Kontermuttern (SW 15) mit einer Schlüsselfläche zur Seitenwand drehen; so sind sie frei (geprüft, `kollision_kontermutter`).
- **Klemmendeckel** vorne über den Schraubklemmen: kleiner Schraubdeckel mit 4 M3-Senkkopfschrauben (bündig) und
  eigener TPU-Dichtung. Ein **Quersteg** direkt hinter den Klemmen trennt den Klemmenraum vorne ab und trägt die Dichtung.
  Bei abgenommenem Deckel kommt ein Schraubendreher (Ø 3 mm) senkrecht an alle vier Klemmenschrauben (geprüft).
  Kabel lassen sich so anschließen, ohne das Gehäuse von der Wand zu nehmen. Weil auch dieser Deckel gedichtet ist,
  ist der ganze Innenraum dicht.

Kollisionsprüfungen in der SCAD-Datei (`part` = `kollision`, `kollision_taster`, `kollision_bodendeckel`,
`kollision_klemmdeckel`, `kollision_schraubendreher`, `kollision_kontermutter`, `kollision_einbau`) liefern nur Flächenkontakte bzw. ein leeres
Objekt. `kollision_einbau` prüft, dass die bestückte Platine von hinten bis in ihre Endlage geschoben werden kann.

| Teil (`gehaeuse/stl/`) | Material | Druck |
|---|---|---|
| `gehaeuse.stl` | PETG | Front aufs Bett (schon gedreht), ohne Stützen (Eckblöcke mit 45°-Fase) |
| `bodendeckel.stl` | PETG | Wandseite aufs Bett |
| `klemmdeckel.stl` | PETG | Außenseite aufs Bett (schon gedreht) |
| `tastenstift.stl` | PETG | Kopf aufs Bett |
| `regenschutz.stl` (optional) | PETG | flach, über die Linse kleben |
| `dichtung.stl` | TPU 95A | flach, 100 % Infill (Bodendeckel) |
| `klemmdichtung.stl` | TPU 95A | flach, 100 % Infill (Klemmendeckel, gleiche Schnur 1,8 mm) |
| `linsendichtung.stl` | TPU 95A | flach |

**Montage**:
1. Einschmelzmuttern M3 mit dem Lötkolben setzen: 4 im hinteren Gehäuserand, 4 für den Klemmendeckel,
   3 in den Platinendomen des Bodendeckels.
2. Von hinten ins Gehäuse: PIR mit Linsendichtung auf die Dome schrauben. Gehäuse mit der Front nach unten legen und
   den Tastenstift (Spitze voran) ins Rohr stecken.
3. Platine auf den Bodendeckel schrauben, dann den D1 mini aufstecken.
4. Dichtung in die hintere Nut legen, Bodendeckel einsetzen und mit 4 M3 × 10 Senkkopfschrauben von hinten verschrauben.
5. Das Gehäuse **mit den Kabelverschraubungen nach unten** über die Laschen des Bodendeckels an die Wand schrauben.
6. Kabel durch die Verschraubungen führen und durch die vordere Öffnung anklemmen. Klemmdichtung in die Nut legen und
   den Klemmendeckel mit 4 M3 × 8 Senkkopfschrauben aufschrauben.

## Firmware (ESP-NOW)

`firmware/Funklicht/Funklicht.ino` ist eine Firmware für alle Lampen. Board: **LOLIN(WEMOS) D1 R2 & mini**.
Benötigte Bibliothek: **QuickEspNow 0.8.1** (German Martín, MIT), über den Bibliotheksverwalter der Arduino-IDE installieren.

**Schlüssel anlegen:** Die Firmware erwartet eine Arduino-Bibliothek `Secrets` mit dem gemeinsamen Schlüssel.
Sie ist absichtlich nicht im Repository. Anlegen unter `<Sketchbook>/libraries/Secrets/`:

```
libraries/Secrets/library.properties   name=Secrets
                                        version=1.0.0
libraries/Secrets/src/Secrets.h        #pragma once
                                        #define FUNKLICHT_KEY "eigener-langer-zufaelliger-schluessel"
```

Alle Lampen einer Anlage brauchen denselben Schlüssel.

**Funk mit Empfangsbestätigung**:
- Nachrichten gehen gezielt (Unicast) an die gekoppelten Lampen.
- Der Empfänger bestätigt jede Nachricht, und QuickEspNow wartet im synchronen Modus auf diese Bestätigung.
- Fehlt sie, sendet die Firmware bis zu 4-mal erneut, ähnlich wie TCP. Danach meldet sie im seriellen Monitor `Keine Bestaetigung von …`.
- Gesendet werden nur Zustandswechsel, keine Wiederholungen: je Lampe und Durchgang eine Meldung „Bewegung beginnt“ und eine Meldung „Ruhe“ bzw. „Person weiter“ an jeden Partner.
  Nur bei mehr als 2 Minuten ununterbrochener Bewegung wird die Meldung einmal aufgefrischt.
  Fällt eine Lampe aus, bevor sie „Ruhe“ melden kann, gehen ihre Nachbarn nach spätestens 5 Minuten aus.
- Alle 5 Minuten prüft jede Lampe, ob ihre Partner noch antworten.
- Protokollversion 3: Alle Lampen müssen dieselbe Firmware haben.

**Pairing (Lampen koppeln)**, dynamisch über die feste MAC-Adresse, ohne Neu-Kompilieren:

1. An Lampe A den Taster **1 s halten**. As Lampe blinkt schnell, und A sucht 30 s lang einen Partner.
   Alle Lampen, die schon mit A gekoppelt sind, **blinken langsam** mit. So sieht man sofort, welche gekoppelt sind.
2. An einer **nicht blinkenden** Lampe B den Taster 1 s halten: A und B finden sich automatisch und speichern sich
   gegenseitig im Flash. Zur Bestätigung leuchten beide Lampen 1,5 s lang, danach ist der Pairing-Modus beendet.
3. An einer **langsam blinkenden** Lampe den Taster 1 s halten: Die Kopplung zu A wird auf beiden Seiten gelöst.
   Beide leuchten 1,5 s zur Bestätigung. A bleibt im Pairing-Modus (wieder 30 s), so lassen sich mehrere Lampen nacheinander entkoppeln.

Die blaue LED auf dem D1 mini zeigt dasselbe Muster wie die Lampe.

Jede Lampe kann bis zu 8 Partner haben. Gekoppelt werden **benachbarte** Lampen, also die, die bei Bewegung mit vorleuchten sollen (z. B. Garage links ↔ Garage Mitte ↔ Garage rechts ↔ Haustür).
Koppeln können sich nur Lampen mit demselben Schlüssel
(`FUNKLICHT_KEY` in `libraries/Secrets/src/Secrets.h`, alle Nachrichten sind mit HMAC-SHA256 signiert).

**Verhalten**:

| Ereignis | Reaktion |
|---|---|
| Bewegung am eigenen PIR | Licht an bis 60 s nach der letzten Bewegung. Die gekoppelten Lampen bekommen **eine** Meldung „Bewegung beginnt“ |
| 30 s keine Bewegung mehr | Meldung „Ruhe“ an die gekoppelten Lampen, diese gehen aus |
| Gekoppelte Lampe meldet Bewegung | Licht leuchtet vor, bis diese Lampe „Ruhe“ oder „Person weiter“ meldet |
| Person geht von Lampe A zu Lampe B weiter | A meldet „Person weiter“. A und die von A vorgeleuchteten Lampen gehen nach 8 s aus, das Licht folgt der Person. Sieht As PIR die Person noch, erst wenn er abfällt. Weitere Meldungen von B lassen A nicht wieder vorleuchten |
| Taster kurz | wie Bewegung am PIR: Licht an, gekoppelte Lampen werden informiert |
| Taster lang (ab 1 s) | Pairing-Modus. Blinkt die Lampe gerade langsam (Partner ist im Pairing-Modus): Kopplung lösen |

Weitere Eigenschaften:
- Die Lampe wird weich per PWM ein- und ausgeblendet. Flackert ein LED-Treiber, `DIMMEN = false` setzen.
- Der PIR wird 60 s lang ignoriert, solange er anläuft; in dieser Zeit blinkt die LED langsam.
- Ein PIR-Signal zählt erst, wenn es 100 ms ansteht.
- Die Sendeleistung ist auf 17 dBm reduziert.

Alle Einstellungen stehen in `config.h`. Den seriellen Monitor mit 115200 Baud öffnen: Dort zeigt jede Lampe ihre MAC, ihre Partner und alle Funkereignisse.
## Hinweise / offen

- **Fehlauslöser durch Funk:** Der PIR sitzt nah am ESP8266. Gegenmaßnahmen:
  - Der PIR wird mit 12 V versorgt und ist so von der 5-V-Versorgung des ESP getrennt.
  - Der PIR sitzt über dem USB-Ende des Moduls, von der Antenne weg.
  - In der Firmware lässt sich die Sendeleistung reduzieren (`WiFi.setOutputPower()`), eine Entprellung von ca. 100 ms einbauen und die ersten 60 s nach dem Start ignorieren.
- **Ungeprüfte Annahmen:**
  - Die PIR-Maße stammen aus dem 3D-Modell und sind nicht nachgemessen.
  - Die Bauteilhöhen sind Schätzwerte.
  - Vor dem ersten Druck einmal PIR-Platine, Linsendurchmesser (Lochabstand 28 mm ist gemessen) nachmessen. Die Werte stehen oben in der `.scad` (`pir_hole_dx`).
- **Firmware:** kompiliert fehlerfrei, ist aber noch nicht auf echter Hardware mit mehreren Lampen getestet.

## Lizenz

[PolyForm Noncommercial 1.0.0](LICENSE): frei nutzbar, veränderbar und weitergebbar, aber nur nicht kommerziell. Keine Gewährleistung, keine Haftung.
