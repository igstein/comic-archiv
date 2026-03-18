# Comic Archiv - Polishing & Verbesserungen

## 🎨 Quick Wins (ca. 1 Stunde)

### 1. Default Erscheinungsdatum ändern
**Problem:** Aktuell wird `Date()` (heute) als Standard verwendet
**Lösung:** Spezielles Datum wie `01.01.1900` oder erkennbar leeres Datum
**Aufwand:** 5 Minuten

### 2. System-Listen oben fixieren
**Problem:** "Meine Sammlung" und "Wishlist" sind nicht immer ganz oben
**Lösung:** Feste Reihenfolge in Sidebar:
1. Meine Sammlung
2. Wishlist
3. Normale Listen
4. Reading Orders (eigene Section)
**Aufwand:** 15 Minuten

### 3. Erste App-Start: Nur Default-Listen
**Problem:** Test-Daten werden beim ersten Start geladen
**Lösung:** Nur "Meine Sammlung" + "Wishlist" erstellen, keine Dummy-Comics/Listen
**Aufwand:** 5 Minuten

### 4. Löschen-Button Styling
**Problem:** Löschen-Button im Comic-Detail nicht optimal positioniert/gestylt
**Lösung:** 
- Position: Mittig oder unten zentriert
- Farbe: Rot (`.destructive` Button-Style) oder App-Farben
**Aufwand:** 5 Minuten

### 5. Icon-Picker verbessern
**Problem:** 
- "list.bullet" sollte nicht für normale Listen wählbar sein (nur Reading Orders)
- Icon-Namen werden angezeigt statt visuelle Icons
**Lösung:**
- Filtered Icon-Liste je nach Listen-Typ
- Visual Picker mit tatsächlichen Icons
**Aufwand:** 30 Minuten

### 6. Padding-Problem in "Neue Reading Order" Sheet
**Problem:** Platzhalter-Text "z.B. DC Rebirth Timeline" wird vom TextField überlappiert
**Lösung:** 
- Mehr Abstand zwischen "Name" Label und TextField
- ODER Platzhalter als `prompt` Parameter im TextField (innerhalb des Feldes)
**Aufwand:** 5 Minuten

---

## ⭐ Hauptfeature: Drag & Drop Comics → Reading Order (1-2h)

### Konzept
Comics aus normalen Listen per Drag & Drop zu Reading Orders hinzufügen

### Entscheidungen:
**✅ COPY-Modus:** Comic bleibt in ursprünglicher Liste UND wird zur Reading Order hinzugefügt
**✅ Drop-Position:** Immer am Ende einfügen (als letzter Entry)
**✅ Duplikat-Handling:** Fehler-Meldung zeigen: "Comic bereits in der Liste"

### Technische Umsetzung:
1. ComicCard draggable machen (bereits vorhanden für Listen)
2. Reading Order Entry-Liste als Drop-Zone
3. Drop-Handler:
   - Comic-ID aus Drag-Data extrahieren
   - Neuen ReadingOrderEntry erstellen
   - An gewünschter Position einfügen
   - Positionen neu berechnen

**Aufwand:** 1-2 Stunden

---

## ✅ Alle Entscheidungen getroffen!

### Drag & Drop Feature - Finales Design:
- **COPY-Modus:** Comic bleibt in ursprünglicher Liste
- **Drop-Position:** Immer am Ende (als letzter Entry)
- **Duplikat-Handling:** Alert zeigen: "Comic bereits in der Liste"

### Padding-Problem:
- **Identifiziert:** "Neue Reading Order" Sheet
- **Problem:** Platzhalter-Text wird vom TextField überlappiert
- **Lösung:** Spacing erhöhen oder Platzhalter ins TextField

---

## 🚀 Implementation-Reihenfolge

### Session 1: Quick Wins (1h)
1. Default Datum
2. System-Listen fixieren
3. Keine Test-Daten
4. Löschen-Button
5. Icon-Picker
6. Padding-Fix (nach Screenshot)

### Session 2: Drag & Drop (1-2h)
1. Drop-Zones implementieren
2. Drop-Handler Logik
3. Position-Berechnung
4. Duplikat-Handling
5. Visuelles Feedback
6. Testing

**Gesamtaufwand:** 2-3 Stunden

---

**Status:** ✅ Bereit für Implementation!
**Nächster Schritt:** Implementation-Prompt erstellen und loslegen
