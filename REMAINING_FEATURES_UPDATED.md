# Comic Archiv - Verbleibende Features & Roadmap

## ✅ FERTIG - Was bereits implementiert ist

### Reading Order System (Phase 1-4)

**Kernfunktionalität:**
- ✅ Reading Orders erstellen & verwalten
- ✅ Einträge hinzufügen (Comic oder Platzhalter)
- ✅ Drag & Drop Sortierung mit automatischer Positionierung
- ✅ Drei Status-Typen: ✅ Gelesen, 📖 Ungelesen, 🛒 Zu kaufen
- ✅ Fortschritts-Tracking ("3/8 gelesen, 2 zu kaufen")
- ✅ Context Menu (Bearbeiten, Löschen, Comic hinzufügen)
- ✅ Platzhalter → Comic konvertieren (automatisch)
- ✅ Cover-Anzeige in vertikaler Liste
- ✅ Smart Autocomplete beim Hinzufügen (One-Click)
- ✅ Gelesen-Status direkt togglen
- ✅ Automatische Position-Neuberechnung beim Löschen

**UI/UX:**
- ✅ Separate Sidebar-Section für Reading Orders
- ✅ Vertikale nummerierte Listenansicht
- ✅ Status-Icons und Badges
- ✅ Mini-Cover-Vorschau
- ✅ Hover-Effekte und Drag-Handle
- ✅ Empty State mit Call-to-Action

---

## 🚀 IN ARBEIT - Aktuelle Priorität

### Phase 4.5: Wishlist System ⭐⭐⭐⭐⭐
**Beschreibung:** Zentrale Verwaltung aller Comics die noch gekauft werden müssen

**Kernkonzept:**
Zwei feste System-Listen (nicht löschbar):
- 📚 **Meine Sammlung** (istHauptliste = true) - Alle Comics die du besitzt
- 🛒 **Wishlist** (istWishlist = true) - Alle Comics die du noch kaufen willst

**Features:**

#### 1. Automatische Synchronisation
- ✨ Platzhalter in Reading Order erstellt → Automatisch zur Wishlist hinzugefügt
- ✨ Comic zur Sammlung hinzugefügt → Aus Wishlist entfernt
- ✨ Comic zur Sammlung hinzugefügt → Alle Platzhalter mit diesem Namen → Comic konvertiert
- ✨ Platzhalter aus Reading Order gelöscht → Bleibt in Wishlist erhalten

#### 2. Direkte Wishlist-Verwaltung
- ➕ Comics direkt zur Wishlist hinzufügen (ohne Reading Order)
- 🗑️ Comics aus Wishlist entfernen
- 📋 "Zur Sammlung hinzufügen" Flow (Titel vorausgefüllt)
- 📊 Übersicht wo Platzhalter in Reading Orders vorkommen

#### 3. Wishlist-Ansicht
- 🎨 Grid-Ansicht mit Platzhalter-Cards
- 🛒 Status-Badge "Zu kaufen"
- 📷 Leere Cover-Rahmen für Platzhalter
- ⚡ Context Menu: "Zur Sammlung hinzufügen", "Löschen", "In Reading Orders"

#### 4. Migration
- 🔄 Beim ersten App-Start: Alle existierenden Platzhalter zur Wishlist hinzufügen
- ✅ System-Listen (Hauptliste + Wishlist) automatisch erstellen falls nicht vorhanden

**Technische Umsetzung:**

**Datenmodell:**
```swift
// Neues Model für gemeinsame Platzhalter
@Model
final class PlaceholderComic {
    var id: UUID
    var name: String
    var erstelltAm: Date
    
    // Beziehungen
    @Relationship(deleteRule: .nullify)
    var readingOrderEntries: [ReadingOrderEntry]
    
    var inWishlist: Bool = true
}

// ComicListe erweitern
@Model
final class ComicListe {
    var istHauptliste: Bool = false
    var istWishlist: Bool = false      // ← NEU
    var istReadingOrder: Bool = false
}

// ReadingOrderEntry erweitern
@Model
final class ReadingOrderEntry {
    var comic: Comic?                  // Echter Comic
    var placeholder: PlaceholderComic? // ODER Platzhalter ← NEU
    var placeholderName: String?       // ← DEPRECATED, durch placeholder ersetzt
}
```

**Auto-Sync Flows:**

**Flow 1: Platzhalter erstellen**
```
Reading Order → "Superman vol. 1" als Platzhalter hinzufügen
   ↓
1. PlaceholderComic erstellen
2. ReadingOrderEntry mit placeholder-Link erstellen
3. PlaceholderComic.inWishlist = true setzen
```

**Flow 2: Comic zur Sammlung hinzufügen**
```
Wishlist → Context Menu → "Zur Sammlung hinzufügen"
   ↓
1. Comic-Objekt mit Details erstellen
2. Zur "Meine Sammlung" hinzufügen
3. PlaceholderComic finden (gleicher Name)
4. Alle ReadingOrderEntries aktualisieren:
   - entry.placeholder = nil
   - entry.comic = neuerComic
5. PlaceholderComic.inWishlist = false
6. PlaceholderComic aus DB löschen (oder behalten für History?)
```

**Flow 3: Platzhalter löschen**
```
Reading Order → Entry löschen
   ↓
1. ReadingOrderEntry löschen
2. PlaceholderComic prüfen:
   - Noch andere ReadingOrderEntries? → Nichts tun
   - Keine anderen Entries mehr? → PlaceholderComic bleibt (inWishlist = true)
```

**UI-Layout:**

**Sidebar:**
```
📚 Listen
├─ 📖 Meine Sammlung (50) [FEST]
├─ 🛒 Wishlist (12)       [FEST] ← NEU
├─ ⭐ Favoriten (8)
└─ 🏷️ Marvel (23)

📖 Reading Orders
├─ DC Rebirth (25)
└─ Infinity Saga (18)
```

**Wishlist-Ansicht:**
```
🛒 Wishlist (12 Comics)

┌───────────┬───────────┬───────────┐
│ [  ] 🛒   │ [  ] 🛒   │ [  ] 🛒   │
│ Superman  │ Batman    │ Flash     │
│ vol. 1    │ vol. 5    │ vol. 2    │
│           │           │           │
│ Zu kaufen │ Zu kaufen │ Zu kaufen │
└───────────┴───────────┴───────────┘

Context Menu:
- ➕ "Zur Sammlung hinzufügen"
- 🗑️ "Aus Wishlist entfernen"
- 📋 "In Reading Orders" (Zeigt wo dieser Comic vorkommt)
```

**Use Cases:**

**Szenario 1: Reading Order erstellen**
```
1. Reading Order "DC Rebirth" erstellen
2. Platzhalter "Superman vol. 1" hinzufügen
   → PlaceholderComic erstellt
   → Erscheint in Reading Order als 🛒
   → Erscheint in Wishlist

3. Später: Comic kaufen und zur Sammlung hinzufügen
   → Wishlist → Context Menu → "Zur Sammlung hinzufügen"
   → Comic-Details eingeben
   → Automatisch:
      ✅ Zur "Meine Sammlung"
      ✅ Aus Wishlist entfernt
      ✅ Platzhalter in "DC Rebirth" → Comic (🛒 → 📖)
```

**Szenario 2: Direkt zur Wishlist**
```
1. Wishlist öffnen
2. [+ Comic hinzufügen]
3. "Spider-Man vol. 10" eingeben
4. Als Platzhalter speichern
   → PlaceholderComic erstellt (ohne ReadingOrderEntry)
   → Erscheint nur in Wishlist
5. Später in Reading Order verwenden oder direkt kaufen
```

**Aufwand:** 7-8 Stunden

**Priorität:** ⭐⭐⭐⭐⭐ (Must-Have - Kernfunktion)

**ROI:** Sehr hoch - Macht Reading Orders viel praktischer und eliminiert redundante Dateneingabe

---

## 🔨 FEHLT NOCH - Optionale Erweiterungen

### A. Text-Import (Bulk-Eingabe)
**Beschreibung:** Liste aus Apple Notes/Textdatei kopieren & einfügen

**Features:**
- 📋 Mehrzeiliger Text-Input
- 🚀 Bulk-Import: Viele Titel auf einmal hinzufügen
- 🔍 Auto-Matching: Prüft, ob Comics bereits in Sammlung existieren
- 📝 Format: "Titel 1\nTitel 2\nTitel 3..."
- ✂️ Smart Parsing: Erkennt Nummern, Sonderzeichen, etc.

**Use Case:**
Du hast eine bestehende Liste in Apple Notes mit 50 Comic-Titeln und willst nicht jeden einzeln manuell eingeben.

**Aufwand:** 1-2 Stunden

---

### B. UI Polish & Details
**Beschreibung:** Feinschliff der Benutzeroberfläche

**Verbesserungen:**
- 🎨 Spacing/Padding optimieren (konsistente Abstände)
- ✨ Animationen verbessern
  - Smooth Drag & Drop Transitions
  - Entry-Hinzufügen Animation
  - Status-Wechsel Animation
- 🎭 Hover-Effekte verfeinern
- 📐 Konsistente Abstände zwischen allen Elementen
- 🌈 Farbschema harmonisieren
- 💅 Rounded Corners und Shadows optimieren

**Use Case:**
App sieht bereits gut aus, aber professioneller Feinschliff für Production-Ready Look.

**Aufwand:** 2-3 Stunden

---

### C. Keyboard Shortcuts
**Beschreibung:** Power-User Features für schnellere Navigation

**Shortcuts:**
- ⌫ **Delete-Key** → Entry löschen (mit Bestätigung)
- ⏎ **Enter** beim Suchen → Sofort hinzufügen
- ⌘N → Neuer Entry
- ⌘E → Entry bearbeiten
- ⌘↑/↓ → Entry nach oben/unten verschieben
- Space → Gelesen-Status togglen
- Esc → Sheet/Dialog schließen

**Use Case:**
Du verwaltest große Reading Orders und willst schneller arbeiten ohne Maus.

**Aufwand:** 1 Stunde

---

### D. Erweiterte Entry-Features
**Beschreibung:** Mehr Metadaten und Funktionen pro Entry

**Features:**

#### D1. Notizen pro Entry
- 📝 Eigene Anmerkungen zu jedem Entry
- 💭 Z.B. "Wichtig für Storyline X", "Optionales Crossover"
- 📄 Multiline-Textfeld
- **Aufwand:** 1 Stunde

#### D2. Release-Datum
- 📅 Wann erscheint der Comic?
- ⏰ Countdown für kommende Releases
- 🔔 Optional: Erinnerung X Tage vorher
- **Aufwand:** 1-2 Stunden

#### D3. Links & Referenzen
- 🔗 URLs zu Shops, Reviews, Wikis
- 🌐 Mehrere Links pro Entry
- 🛒 Direktlink zum Kauf-Shop
- **Aufwand:** 1 Stunde

#### D4. Preis-Tracking
- 💰 Preis pro Comic eingeben
- 💵 Gesamtpreis der Reading Order berechnen
- 📊 "Noch zu kaufen: 120€"
- **Aufwand:** 1 Stunde

#### D5. Tags
- 🏷️ Freie Tags: "Crossover", "Event", "Standalone", "Optional"
- 🎨 Farbcodierung
- 🔍 Filter nach Tags
- **Aufwand:** 2 Stunden

**Use Case:**
Du willst mehr Kontext und Organisation für deine Reading Orders.

**Gesamtaufwand D:** 6-8 Stunden (je nach Auswahl)

---

### E. Import/Export
**Beschreibung:** Daten portabel machen

**Features:**

#### E1. Export
- 📤 Reading Order als CSV exportieren
- 📄 Als JSON exportieren (strukturiert)
- 📝 Als Text exportieren (für Sharing)
- 🖨️ Als PDF Report (mit Covers und Fortschritt)
- **Aufwand:** 2 Stunden

#### E2. Import
- 📥 Aus CSV importieren
- 📦 Aus JSON importieren
- 🔄 Aus anderen Comic-Apps importieren
- **Aufwand:** 2 Stunden

#### E3. Backup
- 💾 Komplettes Backup aller Reading Orders
- 🔄 Wiederherstellen aus Backup
- ☁️ Optional: iCloud Sync
- **Aufwand:** 2-3 Stunden

**Use Case:**
Du willst deine Reading Orders teilen, sichern oder auf anderen Geräten nutzen.

**Gesamtaufwand E:** 6-7 Stunden

---

### F. Lesemodus
**Beschreibung:** Optimiert für tägliches Lesen und Tracking

**Features:**

#### F1. "Next Up" Widget
- 📖 Zeigt nächsten ungelesenen Entry prominent
- 🎯 Großes Cover, Titel, Position
- ➡️ "Weiter zum nächsten" Button
- **Aufwand:** 1 Stunde

#### F2. Quick-Mark als gelesen
- ✅ Großer "Gelesen" Button in Detail-View
- 🚀 Automatisch zum nächsten Entry springen
- ⏩ "Überspringen" Option
- **Aufwand:** 30 Minuten

#### F3. Progress Bar
- 📈 Visueller Fortschrittsbalken im Header
- 🟩🟩🟩⬜⬜⬜⬜⬜ (3/8 gelesen)
- 🎨 Farblich: Grün = gelesen, Orange = zu kaufen
- **Aufwand:** 1 Stunde

#### F4. Reading Session Tracking
- ⏱️ "Reading Session starten"
- 📊 Statistik: Wie viele Comics heute gelesen
- 🏆 Streak-Counter: "5 Tage in Folge gelesen"
- **Aufwand:** 2 Stunden

#### F5. Auto-Advance
- ⚡ Nach "Als gelesen markieren" → automatisch nächster Entry
- 🔄 Optional: Abfrage "Weiter zum nächsten?"
- **Aufwand:** 30 Minuten

**Use Case:**
Du liest täglich Comics aus deiner Reading Order und willst den Flow optimieren.

**Gesamtaufwand F:** 5-6 Stunden

---

### G. Reading Order Templates
**Beschreibung:** Vorgefertigte Reading Orders

**Features:**

#### G1. Template-System
- 📚 Vorgefertigte Templates: "DC Rebirth", "Marvel Civil War", etc.
- 📥 Template laden → automatisch alle Entries erstellt (als Platzhalter)
- ✏️ Eigene Templates erstellen und speichern
- **Aufwand:** 2 Stunden

#### G2. Online-Import
- 🌐 Import von Comic-Datenbanken (Comic Vine, League of Comic Geeks)
- 🔍 Suche: "DC Rebirth Reading Order" → automatisch laden
- 📊 Community-Templates teilen
- **Aufwand:** 4-5 Stunden (API-Integration komplex)

#### G3. Template-Sharing
- 📤 Reading Order als Template exportieren
- 📧 Per E-Mail/Link teilen
- 👥 Community-Hub (später)
- **Aufwand:** 2 Stunden

**Use Case:**
Du willst bekannte Reading Orders schnell nachbauen statt alles manuell einzugeben.

**Gesamtaufwand G:** 8-9 Stunden

---

### H. Multiple Reading Orders pro Comic
**Beschreibung:** Ein Comic kann in mehreren Reading Orders vorkommen

**Features:**
- 🔗 Comic in mehreren Orders gleichzeitig
  - Z.B. Batman in "Batman Timeline" UND "Justice League Timeline"
- 📊 Übersicht: "Dieser Comic ist in 3 Reading Orders"
- 🎯 Quick-Navigation zwischen Orders
- ⚠️ Gelesen-Status synchronisiert (global)

**Use Case:**
Crossover-Comics, die in mehrere Storylines gehören.

**Aufwand:** 2 Stunden

---

### I. Visuelle Verbesserungen

#### I1. List vs. Grid Toggle
- 🔲 Umschalten zwischen vertikaler Liste und Grid
- 📱 Grid: Mehr Übersicht, größere Covers
- 📝 Liste: Mehr Details sichtbar
- **Aufwand:** 1 Stunde

#### I2. Cover-Zoom
- 🔍 Hover über Cover → Vergrößerte Preview
- 🖼️ Klick auf Cover → Fullscreen-View
- **Aufwand:** 1 Stunde

#### I3. Dark Mode Optimierung
- 🌙 Feintuning für Dark Mode
- 🎨 Spezielle Farben für besseren Kontrast
- **Aufwand:** 30 Minuten

**Gesamtaufwand I:** 2-3 Stunden

---

## 🎯 AKTUALISIERTE ROADMAP

### Phase 4.5: Wishlist System (CURRENT - Must-Have) ⭐⭐⭐⭐⭐
**Priorität:** HÖCHSTE - Kernfunktion
- **Wishlist System** (zentrale Platzhalter-Verwaltung)
- **Auto-Sync** (Platzhalter ↔ Comics ↔ Reading Orders)
- **Migration** (bestehende Platzhalter importieren)

**Aufwand gesamt:** 7-8 Stunden  
**Nutzen:** Essentiell - Macht Reading Orders praktisch nutzbar, eliminiert redundante Dateneingabe

---

### Phase 5: Produktivität (Must-Have) ⭐⭐⭐⭐⭐
**Priorität:** Sehr hoch
- **A. Text-Import** (wenn du viele bestehende Listen hast)
- **F1-F3. Basis-Lesemodus** (Next Up, Quick-Mark, Progress Bar)
- **C. Keyboard Shortcuts** (grundlegende: Delete, Enter, Esc)

**Aufwand gesamt:** 4-5 Stunden  
**Nutzen:** Macht die tägliche Nutzung 10x schneller

---

### Phase 6: Polish (Nice-to-Have) ⭐⭐⭐⭐
**Priorität:** Hoch
- **B. UI Polish** (Spacing, Animationen)
- **I3. Dark Mode** (Optimierung)
- **D1. Notizen** (einfache Anmerkungen)

**Aufwand gesamt:** 3-4 Stunden  
**Nutzen:** App sieht professionell aus, fühlt sich polished an

---

### Phase 7: Erweiterte Features (Optional) ⭐⭐⭐
**Priorität:** Mittel
- **D2-D5.** Weitere Entry-Features (nach Bedarf)
- **E1. Export** (für Backup)
- **F4-F5.** Erweiterte Lesemodus-Features
- **H. Multiple Orders** (bei Bedarf)

**Aufwand gesamt:** 8-12 Stunden  
**Nutzen:** Power-User Features, aber nicht essentiell

---

### Phase 8: Community & Sharing (Zukunft) ⭐⭐
**Priorität:** Niedrig
- **G. Templates & Online-Import**
- **E2-E3. Import & Cloud Sync**

**Aufwand gesamt:** 12-15 Stunden  
**Nutzen:** Wenn du die App mit anderen teilen/veröffentlichen willst

---

## 💡 QUICKSTART für nächsten Chat

**Aktueller Fokus - Wishlist System:**
```
"Hallo! Reading Order Feature ist fertig (Phase 1-4).
Ich möchte jetzt das Wishlist System implementieren (Phase 4.5):

ZIEL: Zentrale Verwaltung aller Comics die noch gekauft werden müssen

FEATURES:
1. Zwei feste System-Listen: "Meine Sammlung" + "Wishlist"
2. Auto-Sync: Platzhalter in Reading Order → automatisch zur Wishlist
3. Comic zur Sammlung → aus Wishlist entfernt + Platzhalter konvertiert
4. Wishlist-Ansicht (Grid mit Platzhalter-Cards)
5. Migration: Bestehende Platzhalter importieren

TECHNISCH:
- Neues Model: PlaceholderComic (shared zwischen Reading Orders)
- ComicListe.istWishlist Property
- ReadingOrderEntry.placeholder Link statt placeholderName String

Relevante Dateien im Project verfügbar."
```

---

## 📊 Aktualisierte Zeitaufwand-Übersicht

| Feature | Priorität | Aufwand | ROI |
|---------|-----------|---------|-----|
| **Phase 4.5: Wishlist System** | ⭐⭐⭐⭐⭐ | 7-8h | **SEHR HOCH** |
| **A. Text-Import** | ⭐⭐⭐⭐⭐ | 1-2h | Sehr hoch |
| **F1-F3. Basis-Lesemodus** | ⭐⭐⭐⭐⭐ | 2-3h | Sehr hoch |
| **C. Keyboard Shortcuts** | ⭐⭐⭐⭐ | 1h | Hoch |
| **B. UI Polish** | ⭐⭐⭐⭐ | 2-3h | Hoch |
| **D1. Notizen** | ⭐⭐⭐ | 1h | Mittel |
| **E1. Export** | ⭐⭐⭐ | 2h | Mittel |
| **D2-D5. Erweiterte Entry-Features** | ⭐⭐ | 5-7h | Niedrig-Mittel |
| **G. Templates** | ⭐⭐ | 8-9h | Niedrig |
| **H. Multiple Orders** | ⭐⭐ | 2h | Niedrig |

---

## 🐛 Bekannte Issues

*(Aktuell keine - alles funktioniert!)*

---

**Stand:** 29. Januar 2026  
**Version:** Phase 1-4 abgeschlossen  
**Nächste Schritte:** Phase 4.5 (Wishlist System) - CURRENT PRIORITY
