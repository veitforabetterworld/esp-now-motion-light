/*
 * Funklicht – vernetzte Bewegungsmelder-Lampen mit ESP-NOW (Wemos D1 mini / ESP8266)
 *
 * Funk ueber die Bibliothek QuickEspNow (German Martin, MIT):
 *   Nachrichten gehen gezielt (Unicast) an die gekoppelten Lampen. Der Empfaenger bestaetigt jede
 *   Nachricht, QuickEspNow wartet im synchronen Modus auf diese Bestaetigung. Fehlt sie, sendet die
 *   Firmware bis zu SENDEVERSUCHE-mal erneut – aehnlich wie TCP.
 *
 * Pairing (dynamisch, ueber die feste MAC-Adresse):
 *   Taster 1 s halten -> Pairing-Modus (LED blinkt schnell, 30 s). Wird eine zweite Lampe ebenfalls in
 *   den Pairing-Modus geschaltet, finden sich beide automatisch und speichern sich gegenseitig im Flash.
 *   Im Pairing-Modus blinkt die eigene Lampe schnell, alle bereits gekoppelten Lampen blinken langsam.
 *   Taster lang an einer langsam blinkenden Lampe -> diese Kopplung wird geloest (beide Seiten).
 *
 * Verhalten:
 *  - Gesendet werden nur Zustandswechsel, keine Wiederholungen:
 *      BEWEGUNG  Bewegung beginnt (bei Dauerbewegung alle AUFFRISCHEN_S einmal aufgefrischt)
 *      RUHE      NACHLAUF_NACHBAR_S ohne Bewegung
 *      FOLGE_AUS Person ist zu einer anderen Lampe weitergegangen
 *  - Bewegung am eigenen PIR: Lampe an (bis NACHLAUF_EIGEN_S nach der letzten Bewegung), BEWEGUNG an die Partner.
 *  - Partner meldet BEWEGUNG: Lampe leuchtet vor, bis er RUHE (sofort aus) oder FOLGE_AUS meldet.
 *  - Laeuft man von Lampe A zu Lampe B weiter, geht A (und was A hat vorleuchten lassen) nach
 *    FOLGE_AUS_S aus -> das Licht "folgt" der Person. Sieht As PIR die Person dabei noch, geht A
 *    erst nach dem Abfallen seines PIR frueher aus. Weitere Meldungen von B lassen A nicht wieder
 *    vorleuchten (bis RICHTUNG_MERKEN_S nach Bs letzter Meldung), ausser die Person kam von woanders zu B.
 *  - Taster kurz: wie Bewegung am PIR (Licht an, Partner werden informiert). Taster lang: Pairing.
 *
 * Alle Nachrichten sind mit HMAC-SHA256 signiert (Schluessel FUNKLICHT_KEY in Secrets.h);
 * nur Lampen mit demselben Schluessel koennen sich koppeln und schalten.
 *
 * Platine: Projekte/Funklicht/hardware (v1.2). Einstellungen: config.h
 * Board: "LOLIN(WEMOS) D1 R2 & mini" (esp8266:esp8266:d1_mini)
 * Bibliothek: QuickEspNow 0.8.1 (libraries/QuickEspNow)
 */
#include <ESP8266WiFi.h>
#include <EEPROM.h>
#include <QuickEspNow.h>
#include <bearssl/bearssl.h>
#include <Secrets.h>     // FUNKLICHT_KEY
#include "config.h"

extern "C" {
#include <espnow.h>
}

#ifndef FUNKLICHT_KEY
#error "FUNKLICHT_KEY fehlt in libraries/Secrets/src/Secrets.h"
#endif

// ======================= Protokoll =======================
enum Typ : uint8_t {
  PAIR_ANFRAGE = 1,   // Broadcast im Pairing-Modus
  PAIR_OK      = 2,   // Antwort an die gefundene Lampe
  BEWEGUNG     = 3,   // Bewegung beginnt (bzw. seltene Auffrischung); vorher = Lampe, die mich vorleuchten liess
  FOLGE_AUS    = 4,   // Bewegung vorbei, Person ist zu einer anderen Lampe weiter -> Partner gehen nach FOLGE_AUS_S aus
  LEBENSZEICHEN = 7,
  RUHE         = 8,   // Bewegung vorbei (NACHLAUF_NACHBAR_S ohne Bewegung) -> Partner hoeren auf vorzuleuchten
  PAIR_ZEIGEN  = 9,   // "ich bin im Pairing-Modus" an alle Partner -> sie blinken (zeigen: wir sind gekoppelt)
  PAIR_ENDE    = 10,  // Pairing-Modus vorbei -> Partner hoeren auf zu blinken
  ENTKOPPELN   = 11   // Taster lang an einer blinkenden Partnerlampe -> beide loesen die Kopplung
};
const uint8_t PROTOKOLL = 3;   // Lampen mit anderer Protokollversion werden ignoriert

struct __attribute__((packed)) Nachricht {
  char     magic[2];   // 'F','L'
  uint8_t  version;    // PROTOKOLL
  uint8_t  typ;
  uint8_t  ursprung[6];  // MAC der Lampe, von der die Nachricht ausging
  uint8_t  vorher[6];    // BEWEGUNG: Lampe, die den Ursprung vorleuchten liess (00.. = keine)
  uint32_t bootId;     // Zufallszahl je Neustart des Ursprungs
  uint32_t seq;        // laufende Nummer des Ursprungs
  uint8_t  hmac[8];    // gekuerzte HMAC-SHA256 ueber alle Bytes davor
};
const size_t SIGNIERT = offsetof(Nachricht, hmac);
const uint8_t NULL_MAC[6] = {0, 0, 0, 0, 0, 0};

// ======================= Zustand =======================
enum Grund : uint8_t { AUS = 0, EIGEN = 1, NACHBAR = 2 };
const char *GRUND_TEXT[] = {"aus", "eigene Bewegung", "Nachbar"};

uint8_t meineMac[6];
uint32_t bootId, seqZaehler = 0;

Grund grund = AUS;
uint8_t vorleuchtVon[6] = {0};
uint32_t ausUm = 0;
float helligkeit = 0;

// Richtung: Person ist von mir zu dieser Lampe weitergegangen. Deren weitere Meldungen lassen mich
// nicht wieder vorleuchten (sonst ginge das Licht hinter der Person wieder an).
uint8_t weiterZu[6] = {0};
uint32_t weiterBis = 0;
bool folgeAusAusstehend = false;   // eigener PIR sah noch Bewegung -> erst beim Abfallen frueher aus

// Eigene Meldung: nur Zustandswechsel werden gesendet (Bewegung beginnt / Ruhe), kein Dauerfeuer
bool gemeldet = false;             // Partner wissen: hier ist Bewegung
uint32_t letzteBewegung = 0;       // zuletzt hat der eigene PIR Bewegung gesehen

// Zustand der Partner (Index wie partner.mac)
uint32_t aktivBis[MAX_PARTNER] = {0};    // Partner meldet Bewegung (Sicherheitsgrenze, falls RUHE verloren geht)
uint32_t aktivSeit[MAX_PARTNER] = {0};

bool pirAktiv = false, pirRoh = false;
uint32_t pirSeit = 0, letzteMeldung = 0, letztesLebenszeichen = 0;

bool pairing = false;
uint32_t pairingBis = 0, letzteAnfrage = 0;
uint8_t zeigenFuer[6] = {0};   // diese Partnerlampe ist im Pairing-Modus -> ich blinke (bis zeigenBis)
uint32_t zeigenBis = 0;
uint32_t ledMuster = 0;    // Bestaetigung: LED und Lampe leuchten bis zu diesem Zeitpunkt dauerhaft
uint32_t ledAusUm = 0;

// Partner (gekoppelte Lampen), dauerhaft im Flash
struct Speicher { uint32_t magic; uint8_t anzahl; uint8_t mac[MAX_PARTNER][6]; };
const uint32_t SPEICHER_MAGIC = 0x464C5031;   // "FLP1"
Speicher partner;

// Empfang: QuickEspNow ruft den Callback im Timer-Kontext auf -> nur kopieren, im loop() verarbeiten
struct Rx { uint8_t von[6]; Nachricht n; };
volatile uint8_t rxKopf = 0, rxEnde = 0;
Rx rxPuffer[8];

// Doppelte Nachrichten (Wiederholungen, Weiterleitungen) erkennen
struct Gesehen { uint8_t mac[6]; uint32_t bootId, seq; };
Gesehen gesehen[16];
uint8_t gesehenNaechster = 0;

// ======================= Hilfsfunktionen =======================
inline bool vorbei(uint32_t zeit) { return (int32_t)(millis() - zeit) >= 0; }
inline bool macGleich(const uint8_t *a, const uint8_t *b) { return memcmp(a, b, 6) == 0; }

String macText(const uint8_t *m) {
  char s[18];
  snprintf(s, sizeof(s), "%02X:%02X:%02X:%02X:%02X:%02X", m[0], m[1], m[2], m[3], m[4], m[5]);
  return String(s);
}

int partnerIndex(const uint8_t *mac) {
  for (uint8_t i = 0; i < partner.anzahl; i++) if (macGleich(partner.mac[i], mac)) return i;
  return -1;
}

void partnerSpeichern() {
  EEPROM.put(0, partner);
  EEPROM.commit();
}

void partnerLaden() {
  EEPROM.begin(sizeof(Speicher));
  EEPROM.get(0, partner);
  if (partner.magic != SPEICHER_MAGIC || partner.anzahl > MAX_PARTNER) {
    memset(&partner, 0, sizeof(partner));
    partner.magic = SPEICHER_MAGIC;
  }
}

void peerAnmelden(const uint8_t *mac) {   // fuer Unicast beim ESP8266-SDK registrieren
  if (!esp_now_is_peer_exist((uint8_t *)mac)) esp_now_add_peer((uint8_t *)mac, ESP_NOW_ROLE_COMBO, WIFI_KANAL, NULL, 0);
}

bool partnerHinzufuegen(const uint8_t *mac) {
  if (partnerIndex(mac) >= 0) { Serial.printf("%s ist schon gekoppelt\n", macText(mac).c_str()); return true; }
  if (partner.anzahl >= MAX_PARTNER) { Serial.println(F("Keine freien Plaetze fuer weitere Partner")); return false; }
  memcpy(partner.mac[partner.anzahl++], mac, 6);
  partnerSpeichern();
  peerAnmelden(mac);
  Serial.printf("Gekoppelt mit %s (%u Partner)\n", macText(mac).c_str(), partner.anzahl);
  return true;
}

void partnerEntfernen(const uint8_t *mac) {
  int i = partnerIndex(mac);
  if (i < 0) return;
  for (uint8_t k = i; k + 1 < partner.anzahl; k++) {   // Luecke schliessen (Zustand wandert mit)
    memcpy(partner.mac[k], partner.mac[k + 1], 6);
    aktivBis[k] = aktivBis[k + 1];
    aktivSeit[k] = aktivSeit[k + 1];
  }
  partner.anzahl--;
  aktivBis[partner.anzahl] = 0;
  memset(partner.mac[partner.anzahl], 0, 6);
  partnerSpeichern();
  esp_now_del_peer((uint8_t *)mac);
  Serial.printf("Entkoppelt von %s (%u Partner)\n", macText(mac).c_str(), partner.anzahl);
}

void led(uint16_t ms) { digitalWrite(PIN_LED, LOW); ledAusUm = millis() + ms; }

void hmacBerechnen(const Nachricht &n, uint8_t *aus8) {
  static br_hmac_key_context kc;
  static bool init = false;
  if (!init) { br_hmac_key_init(&kc, &br_sha256_vtable, FUNKLICHT_KEY, strlen(FUNKLICHT_KEY)); init = true; }
  br_hmac_context hc;
  uint8_t voll[32];
  br_hmac_init(&hc, &kc, 0);
  br_hmac_update(&hc, &n, SIGNIERT);
  br_hmac_out(&hc, voll);
  memcpy(aus8, voll, 8);
}

bool hmacPruefen(const Nachricht &n) {
  uint8_t soll[8];
  hmacBerechnen(n, soll);
  uint8_t d = 0;
  for (int i = 0; i < 8; i++) d |= soll[i] ^ n.hmac[i];   // Vergleich in konstanter Zeit
  return d == 0;
}

Nachricht neueNachricht(Typ typ, const uint8_t *vorher = NULL_MAC) {
  Nachricht n = {};
  n.magic[0] = 'F'; n.magic[1] = 'L'; n.version = PROTOKOLL; n.typ = typ;
  memcpy(n.ursprung, meineMac, 6);
  memcpy(n.vorher, vorher, 6);
  n.bootId = bootId; n.seq = ++seqZaehler;
  hmacBerechnen(n, n.hmac);
  return n;
}

// Unicast mit Empfangsbestaetigung; ohne Bestaetigung bis zu SENDEVERSUCHE-mal wiederholen
bool sendeAn(const uint8_t *mac, const Nachricht &n) {
  for (uint8_t versuch = 1; versuch <= SENDEVERSUCHE; versuch++) {
    comms_send_error_t r = quickEspNow.send(mac, (const uint8_t *)&n, sizeof(n));
    if (r == COMMS_SEND_OK) return true;
    if (r == COMMS_SEND_QUEUE_FULL_ERROR) delay(5);
    else delay(3 + versuch * 4);
  }
  Serial.printf("Keine Bestaetigung von %s\n", macText(mac).c_str());
  return false;
}

void anAllePartner(const Nachricht &n, const uint8_t *ausser = NULL_MAC) {
  for (uint8_t i = 0; i < partner.anzahl; i++)
    if (!macGleich(partner.mac[i], ausser)) sendeAn(partner.mac[i], n);
  led(30);
}

bool schonGesehen(const Nachricht &n) {
  for (Gesehen &g : gesehen)
    if (macGleich(g.mac, n.ursprung) && g.bootId == n.bootId && g.seq == n.seq) return true;
  Gesehen &g = gesehen[gesehenNaechster];
  gesehenNaechster = (gesehenNaechster + 1) % 16;
  memcpy(g.mac, n.ursprung, 6); g.bootId = n.bootId; g.seq = n.seq;
  return false;
}

// ======================= Lampe =======================
void setzeGrund(Grund g, uint32_t dauerMs, const uint8_t *von = NULL_MAC) {
  if (g != grund || !macGleich(von, vorleuchtVon))
    Serial.printf("Licht: %s%s%s\n", GRUND_TEXT[g], g == NACHBAR ? " von " : "", g == NACHBAR ? macText(von).c_str() : "");
  grund = g;
  memcpy(vorleuchtVon, von, 6);
  if (g != AUS) ausUm = millis() + dauerMs;
}

void verlaengere(uint32_t dauerMs) {
  uint32_t neu = millis() + dauerMs;
  if ((int32_t)(neu - ausUm) > 0) ausUm = neu;
}

void verkuerze(uint32_t dauerMs) {
  uint32_t neu = millis() + dauerMs;
  if ((int32_t)(ausUm - neu) > 0) { ausUm = neu; Serial.println(F("Person weitergegangen -> Licht geht frueher aus")); }
}

// Zustandswechsel an alle Partner melden (mit Empfangsbestaetigung)
void melden(Typ typ, const uint8_t *vorher = NULL_MAC) {
  anAllePartner(neueNachricht(typ, vorher));
  letzteMeldung = millis();
  gemeldet = (typ == BEWEGUNG);
}

bool partnerAktiv(uint8_t i) { return aktivBis[i] != 0 && !vorbei(aktivBis[i]); }
bool weiterAktiv() { return !vorbei(weiterBis); }

// Vorleuchten, solange eine gekoppelte Lampe Bewegung meldet – ausser der Lampe, zu der die Person
// von mir aus weitergegangen ist. Wird in jedem loop() aufgerufen.
void vorleuchtenPruefen() {
  if (grund == EIGEN) return;
  int neuester = -1;
  uint32_t bis = 0;
  for (uint8_t i = 0; i < partner.anzahl; i++) {
    if (!partnerAktiv(i) || (weiterAktiv() && macGleich(partner.mac[i], weiterZu))) continue;
    if (neuester < 0 || (int32_t)(aktivSeit[i] - aktivSeit[neuester]) > 0) neuester = i;
    if (bis == 0 || (int32_t)(aktivBis[i] - bis) > 0) bis = aktivBis[i];
  }
  if (neuester < 0) return;   // kein Partner aktiv: Licht laeuft mit der zuletzt gesetzten Zeit aus
  if (grund != NACHBAR || !macGleich(vorleuchtVon, partner.mac[neuester])) setzeGrund(NACHBAR, 0, partner.mac[neuester]);
  ausUm = bis;
}

void lampeAktualisieren() {
  static uint32_t letzterSchritt = 0;
  uint32_t jetzt = millis();
  if (grund != AUS && vorbei(ausUm)) setzeGrund(AUS, 0);
  // Pairing sichtbar machen: eigene Lampe blinkt schnell, gekoppelte Lampen blinken langsam,
  // Bestaetigung (gekoppelt/entkoppelt): 1,5 s dauerhaft an
  bool muster = !vorbei(ledMuster) || pairing || zeigenAktiv();
  if (muster) {
    bool an = !vorbei(ledMuster) ? true : pairing ? (jetzt / 150) % 2 : (jetzt / 500) % 2;
    helligkeit = an ? HELLIGKEIT : 0;
    if (DIMMEN) analogWrite(PIN_LAMP, an ? HELLIGKEIT : 0);
    else digitalWrite(PIN_LAMP, an ? HIGH : LOW);
    return;
  }
  float ziel = grund != AUS ? HELLIGKEIT : 0;
  if (!DIMMEN) { digitalWrite(PIN_LAMP, ziel > 0 ? HIGH : LOW); helligkeit = ziel; return; }
  uint32_t dt = jetzt - letzterSchritt;
  if (dt < 5) return;
  letzterSchritt = jetzt;
  float schritt = (float)HELLIGKEIT * dt / (ziel > helligkeit ? EINBLENDEN_MS : AUSBLENDEN_MS);
  if (helligkeit < ziel) helligkeit = min(ziel, helligkeit + schritt);
  else if (helligkeit > ziel) helligkeit = max(ziel, helligkeit - schritt);
  analogWrite(PIN_LAMP, (uint16_t)(helligkeit * helligkeit / HELLIGKEIT));   // quadratisch: gleichmaessiger fuers Auge
}

// ======================= Ereignisse =======================
// Steigende Flanke am eigenen PIR oder kurzer Tastendruck.
// Gesendet wird nur, wenn die Partner noch nichts von der Bewegung wissen.
void eigeneBewegung() {
  letzteBewegung = millis();
  weiterBis = millis();          // Person ist (wieder) hier -> Richtung vergessen
  folgeAusAusstehend = false;
  uint8_t vorher[6];
  memcpy(vorher, grund == NACHBAR ? vorleuchtVon : NULL_MAC, 6);
  setzeGrund(EIGEN, NACHLAUF_EIGEN_S * 1000UL);
  if (!gemeldet) melden(BEWEGUNG, vorher);
}

// Waehrend Bewegung: Licht an halten. Danach: nach NACHLAUF_NACHBAR_S Ruhe melden.
// Nur bei sehr langer Bewegung (AUFFRISCHEN_S) wird zwischendurch einmal aufgefrischt.
void meldungAktualisieren() {
  if (pirAktiv) {
    letzteBewegung = millis();
    if (grund == EIGEN) verlaengere(NACHLAUF_EIGEN_S * 1000UL);
  }
  if (!gemeldet) return;
  if (!pirAktiv && millis() - letzteBewegung >= NACHLAUF_NACHBAR_S * 1000UL) melden(RUHE);
  else if (millis() - letzteMeldung >= AUFFRISCHEN_S * 1000UL) melden(BEWEGUNG);
}

// Person ist bei weiterZu: eigenes Licht frueher aus, und die Partner hoeren auf vorzuleuchten
void folgeAus() {
  folgeAusAusstehend = false;
  if (grund == EIGEN) verkuerze(FOLGE_AUS_S * 1000UL);
  if (gemeldet) melden(FOLGE_AUS);
}

// Gekoppelte Lampe meldet Bewegung, die Person kam von mir
void personWeiter(const uint8_t *zu) {
  memcpy(weiterZu, zu, 6);
  weiterBis = millis() + RICHTUNG_MERKEN_S * 1000UL;
  if (pirAktiv) folgeAusAusstehend = true;   // Person ist noch in meinem Bereich -> beim Abfallen des PIR
  else folgeAus();
}

// Partner meldet Ruhe bzw. "Person weiter": nicht mehr wegen ihm vorleuchten
void partnerRuhe(int i, uint32_t nachlaufMs) {
  aktivBis[i] = 0;
  if (grund == NACHBAR && macGleich(vorleuchtVon, partner.mac[i])) {
    uint32_t neu = millis() + nachlaufMs;
    if ((int32_t)(ausUm - neu) > 0) ausUm = neu;   // vorleuchtenPruefen() uebernimmt, falls ein anderer Partner aktiv ist
  }
}

void verarbeite(const uint8_t *von, const Nachricht &n) {
  switch (n.typ) {
    case PAIR_ANFRAGE:
      if (pairing && !macGleich(von, meineMac)) {
        Serial.printf("Pairing-Anfrage von %s\n", macText(von).c_str());
        if (partnerHinzufuegen(von)) {
          peerAnmelden(von);
          sendeAn(von, neueNachricht(PAIR_OK));
          pairingBeenden("gekoppelt");
        }
      }
      break;
    case PAIR_OK:
      if (pairing || partnerIndex(von) >= 0) {
        if (partnerHinzufuegen(von) && pairing) pairingBeenden("gekoppelt");
      }
      break;
    case PAIR_ZEIGEN:   // Partner ist im Pairing-Modus: blinken, Taster lang wuerde entkoppeln
      if (partnerIndex(von) < 0) break;
      Serial.printf("%s ist im Pairing-Modus -> blinken (Taster lang = entkoppeln)\n", macText(von).c_str());
      memcpy(zeigenFuer, von, 6);
      zeigenBis = millis() + PAIRING_DAUER_S * 1000UL;
      break;
    case PAIR_ENDE:
      if (macGleich(von, zeigenFuer)) zeigenBis = millis();
      break;
    case ENTKOPPELN:
      if (partnerIndex(von) < 0) break;
      partnerEntfernen(von);
      ledMuster = millis() + 1500;
      if (pairing) {   // weitere Lampen koennen entkoppelt werden: Zeit neu starten, Partner blinken weiter
        pairingBis = millis() + PAIRING_DAUER_S * 1000UL;
        anAllePartner(neueNachricht(PAIR_ZEIGEN));
      }
      break;
    case BEWEGUNG: {
      int i = partnerIndex(von);
      if (i < 0) break;   // nur gekoppelte Lampen
      Serial.printf("Bewegung bei %s\n", macText(von).c_str());
      if (!partnerAktiv(i)) aktivSeit[i] = millis();
      aktivBis[i] = millis() + NACHBAR_MAX_S * 1000UL;
      if (macGleich(n.vorher, meineMac)) {
        // Person ist von mir zu dieser Lampe gegangen -> mein Licht und meine Vorleuchter gehen frueher aus
        personWeiter(von);
      } else if (weiterAktiv() && macGleich(von, weiterZu)) {
        // Lampe, zu der die Person ging, meldet erneut: kam die Person von woanders dorthin, ist es eine
        // neue Situation -> wieder normal vorleuchten. Sonst ist es dieselbe Person -> dunkel bleiben.
        if (macGleich(n.vorher, NULL_MAC)) weiterBis = millis() + RICHTUNG_MERKEN_S * 1000UL;
        else weiterBis = millis();
      }
      vorleuchtenPruefen();
      break;
    }
    case FOLGE_AUS:
    case RUHE: {
      int i = partnerIndex(von);
      if (i < 0) break;
      Serial.printf("%s bei %s\n", n.typ == RUHE ? "Ruhe" : "Person weiter", macText(von).c_str());
      partnerRuhe(i, n.typ == FOLGE_AUS ? FOLGE_AUS_S * 1000UL : 0);
      if (weiterAktiv() && macGleich(von, weiterZu)) weiterBis = millis() + RICHTUNG_MERKEN_S * 1000UL;
      break;
    }
    default:   // LEBENSZEICHEN: nur Empfangsbestaetigung
      break;
  }
}

void empfangen(uint8_t *von, uint8_t *daten, uint8_t laenge, signed int rssi, bool broadcast) {   // Timer-Kontext!
  (void)rssi; (void)broadcast;
  if (laenge != sizeof(Nachricht)) return;
  uint8_t naechster = (rxKopf + 1) % 8;
  if (naechster == rxEnde) return;
  memcpy(rxPuffer[rxKopf].von, von, 6);
  memcpy(&rxPuffer[rxKopf].n, daten, sizeof(Nachricht));
  rxKopf = naechster;
}

void empfangVerarbeiten() {
  while (rxEnde != rxKopf) {
    Rx rx = rxPuffer[rxEnde];
    rxEnde = (rxEnde + 1) % 8;
    const Nachricht &n = rx.n;
    if (n.magic[0] != 'F' || n.magic[1] != 'L' || n.version != PROTOKOLL) continue;
    if (macGleich(n.ursprung, meineMac)) continue;
    if (!hmacPruefen(n)) { Serial.println(F("Nachricht mit falscher Signatur verworfen")); continue; }
    if (schonGesehen(n)) continue;
    led(15);
    verarbeite(rx.von, n);
  }
}

void pirAbfragen() {
  if (millis() < PIR_ANLAUF_S * 1000UL) return;
  bool roh = digitalRead(PIN_PIR) == HIGH;
  if (roh != pirRoh) { pirRoh = roh; pirSeit = millis(); }
  bool stabil = millis() - pirSeit >= PIR_ENTPRELL_MS;
  if (stabil && roh && !pirAktiv) { pirAktiv = true; Serial.println(F("PIR: Bewegung")); eigeneBewegung(); }
  else if (stabil && !roh && pirAktiv) { pirAktiv = false; if (folgeAusAusstehend) folgeAus(); }
}

bool zeigenAktiv() { return !vorbei(zeigenBis); }

void pairingStarten() {
  pairing = true;
  zeigenBis = millis();
  pairingBis = millis() + PAIRING_DAUER_S * 1000UL;
  letzteAnfrage = 0;
  Serial.printf("Pairing-Modus fuer %lu s – zweite Lampe ebenfalls in den Pairing-Modus schalten\n", (unsigned long)PAIRING_DAUER_S);
  anAllePartner(neueNachricht(PAIR_ZEIGEN));   // gekoppelte Lampen blinken mit
}

void pairingBeenden(const char *grundText) {
  pairing = false;
  Serial.printf("Pairing-Modus beendet: %s\n", grundText);
  if (strcmp(grundText, "gekoppelt") == 0) ledMuster = millis() + 1500;
  anAllePartner(neueNachricht(PAIR_ENDE));
}

// Taster lang: blinkt diese Lampe fuer eine Partnerlampe im Pairing-Modus, wird entkoppelt, sonst gekoppelt
void tasterLang() {
  if (zeigenAktiv() && partnerIndex(zeigenFuer) >= 0) {
    uint8_t mac[6];
    memcpy(mac, zeigenFuer, 6);
    zeigenBis = millis();
    sendeAn(mac, neueNachricht(ENTKOPPELN));   // Gegenstelle loest die Kopplung auch
    partnerEntfernen(mac);
    ledMuster = millis() + 1500;
  } else {
    pairingStarten();
  }
}

void pairingAbarbeiten() {
  if (!pairing) return;
  if (vorbei(pairingBis)) { pairingBeenden("Zeit abgelaufen"); return; }
  if (millis() - letzteAnfrage >= 500) {        // alle 0,5 s rufen
    letzteAnfrage = millis();
    Nachricht n = neueNachricht(PAIR_ANFRAGE);
    quickEspNow.sendBcast((const uint8_t *)&n, sizeof(n));
  }
}

// Taster: kurz = wie Bewegung am PIR (Licht an, Partner informieren), lang = Pairing-Modus
void tasterAbfragen() {
  static bool gedrueckt = false, pairingAusgeloest = false;
  static uint32_t seit = 0, letzteAenderung = 0;
  bool jetzt = digitalRead(PIN_BTN) == LOW;
  if (jetzt != gedrueckt && millis() - letzteAenderung > 30) {     // entprellen
    letzteAenderung = millis();
    gedrueckt = jetzt;
    if (gedrueckt) { seit = millis(); pairingAusgeloest = false; }
    else if (!pairingAusgeloest) { Serial.println(F("Taster: wie Bewegung")); eigeneBewegung(); }
  }
  if (gedrueckt && !pairingAusgeloest && millis() - seit >= PAIRING_HALTEN_MS) {
    pairingAusgeloest = true;
    tasterLang();
  }
}

void ledAktualisieren() {
  bool an;
  if (!vorbei(ledMuster)) an = true;                                                 // Bestaetigung: lange an
  else if (pairing) an = (millis() / 100) % 2;                                       // Pairing: schnell blinken
  else if (zeigenAktiv()) an = (millis() / 500) % 2;                                 // Partner im Pairing: langsam
  else if (millis() < PIR_ANLAUF_S * 1000UL) an = (millis() / 500) % 2;              // PIR-Anlauf: langsam
  else an = !vorbei(ledAusUm);                                                       // kurz bei Funkverkehr
  digitalWrite(PIN_LED, an ? LOW : HIGH);
}

// ======================= Setup / Loop =======================
void setup() {
  pinMode(PIN_LAMP, OUTPUT);
  digitalWrite(PIN_LAMP, LOW);
  pinMode(PIN_LED, OUTPUT);
  digitalWrite(PIN_LED, HIGH);
  pinMode(PIN_PIR, INPUT);
  pinMode(PIN_BTN, INPUT_PULLUP);
  if (DIMMEN) { analogWriteRange(HELLIGKEIT); analogWriteFreq(PWM_FREQ_HZ); analogWrite(PIN_LAMP, 0); }

  Serial.begin(115200);
  delay(100);
  Serial.println(F("\n\nFunklicht (ESP-NOW, QuickEspNow)"));

  WiFi.persistent(false);
  WiFi.mode(WIFI_STA);
  WiFi.disconnect(false);
  WiFi.setOutputPower(SENDELEISTUNG_DBM);
  WiFi.macAddress(meineMac);
  bootId = ESP.random();

  quickEspNow.onDataRcvd(empfangen);
  quickEspNow.begin(WIFI_KANAL, WIFI_IF_STA, true);   // synchron: send() wartet auf die Empfangsbestaetigung
  esp_now_set_self_role(ESP_NOW_ROLE_COMBO);

  partnerLaden();
  for (uint8_t i = 0; i < partner.anzahl; i++) peerAnmelden(partner.mac[i]);
  Serial.printf("Diese Lampe: %s, Kanal %u, %u gekoppelte Lampe(n)\n", macText(meineMac).c_str(), WIFI_KANAL, partner.anzahl);
  for (uint8_t i = 0; i < partner.anzahl; i++) Serial.printf("  Partner %u: %s\n", i + 1, macText(partner.mac[i]).c_str());
  if (partner.anzahl == 0) Serial.println(F("Noch keine Partner: Taster 1 s halten zum Koppeln"));
  Serial.printf("PIR-Anlaufzeit %lu s ...\n", (unsigned long)PIR_ANLAUF_S);
}

void loop() {
  empfangVerarbeiten();
  pirAbfragen();
  meldungAktualisieren();
  tasterAbfragen();
  pairingAbarbeiten();
  vorleuchtenPruefen();
  lampeAktualisieren();
  ledAktualisieren();

  if (partner.anzahl && millis() - letztesLebenszeichen >= LEBENSZEICHEN_S * 1000UL) {
    letztesLebenszeichen = millis();
    Nachricht n = neueNachricht(LEBENSZEICHEN);
    for (uint8_t i = 0; i < partner.anzahl; i++)
      if (!sendeAn(partner.mac[i], n)) Serial.printf("Warnung: Partner %s antwortet nicht\n", macText(partner.mac[i]).c_str());
  }
  yield();
}
