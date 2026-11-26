/*
 * Funklicht – Einstellungen
 *
 * Keine feste Lampentabelle mehr: Lampen werden per Taster miteinander gekoppelt (Pairing),
 * die Partner (MAC-Adressen) stehen dauerhaft im Flash.
 */
#pragma once
#include <Arduino.h>

// ---------------- Pins (Platine Funklicht v1.2) ----------------
const uint8_t PIN_LAMP = 5;     // D1  -> IRLB8721 -> Lampe
const uint8_t PIN_PIR  = 12;    // D6  <- HC-SR501 OUT
const uint8_t PIN_BTN  = 14;    // D5  <- Taster nach GND
const uint8_t PIN_LED  = 2;     // D4  blaue LED auf dem D1 mini (LOW = an)

// ---------------- Zeiten ----------------
const uint32_t NACHLAUF_EIGEN_S   = 60;    // eigene Bewegung: so lange bleibt das Licht an
const uint32_t NACHLAUF_NACHBAR_S = 30;    // so lange nach der letzten eigenen Bewegung leuchten die Partner noch vor
                                           // (dann wird RUHE gesendet)
const uint32_t FOLGE_AUS_S        = 8;     // Person ist weitergegangen: Licht hinter ihr geht frueher aus
const uint32_t PIR_ANLAUF_S       = 60;    // HC-SR501 braucht nach dem Einschalten ca. 1 Minute
const uint32_t PIR_ENTPRELL_MS    = 100;   // Signal muss so lange anstehen (gegen Funkstoerungen)
const uint32_t RICHTUNG_MERKEN_S  = 120;   // so lange nach der letzten Meldung der Lampe, zu der die Person
                                           // weitergegangen ist, nicht wieder vorleuchten

// ---------------- Taster ----------------
// kurz: wie Bewegung am PIR (Licht an, Partner informieren); lang: Pairing-Modus
const uint32_t PAIRING_HALTEN_MS  = 1000;  // ab so langem Halten: Pairing-Modus
const uint32_t PAIRING_DAUER_S    = 30;    // so lange sucht die Lampe nach einem Partner

// ---------------- Lampe ----------------
const bool     DIMMEN       = true;   // weiches Ein-/Ausblenden per PWM (bei Problemen mit LED-Treibern: false)
const uint16_t PWM_FREQ_HZ  = 1000;
const uint16_t HELLIGKEIT   = 1023;   // 0..1023, Volllicht
const uint16_t EINBLENDEN_MS = 400;
const uint16_t AUSBLENDEN_MS = 2000;

// ---------------- Funk ----------------
const uint8_t  WIFI_KANAL        = 1;     // alle Lampen auf demselben Kanal
const float    SENDELEISTUNG_DBM = 17.0;  // max. 20.5; kleiner = weniger Fehlausloeser am PIR
const uint8_t  MAX_PARTNER       = 8;     // gekoppelte Lampen je Lampe
const uint8_t  SENDEVERSUCHE     = 4;     // ohne Empfangsbestaetigung so oft wiederholen
const uint32_t LEBENSZEICHEN_S   = 300;   // alle 5 Minuten Verbindung zu den Partnern pruefen
// Gesendet werden nur Zustandswechsel (Bewegung beginnt / Ruhe / Person weiter), keine Wiederholungen.
const uint32_t AUFFRISCHEN_S     = 120;   // nur bei ununterbrochener Bewegung: Meldung einmal auffrischen
const uint32_t NACHBAR_MAX_S     = 300;   // Sicherheit: ohne Ruhe-Meldung (Partner ausgefallen) spaetestens dann aus
