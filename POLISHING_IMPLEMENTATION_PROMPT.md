# Implementation-Prompt: Polishing & Verbesserungen

Kopiere den folgenden Text in einen neuen Chat:

---

Hallo! Ich arbeite an meiner Comic-Archiv App (Swift/SwiftUI mit SwiftData) und möchte eine Reihe von **Polishing-Verbesserungen** umsetzen.

## Aktueller Stand:
✅ Reading Order System fertig (Phase 1-4)
✅ Wishlist System fertig (Phase 4.5)
- App funktioniert komplett
- Jetzt geht es um Feinschliff und kleine Verbesserungen

## Was ich umsetzen will:

### Session 1: Quick Fixes (ca. 1 Stunde)

**1. Default Erscheinungsdatum ändern**
- **Problem:** Neuer Comic hat `Date()` (heute) als Standard
- **Lösung:** Sinnvolles Platzhalter-Datum wie `01.01.1900`
- **Datei:** `AddComicSheet.swift`, `Comic.swift` (init)

**2. System-Listen oben fixieren**
- **Problem:** "Meine Sammlung" und "Wishlist" nicht immer ganz oben
- **Lösung:** Feste Sortierung in Sidebar:
  1. Meine Sammlung
  2. Wishlist
  3. Normale Listen
  4. Reading Orders (eigene Section)
- **Datei:** `SidebarView.swift`

**3. Erste App-Start: Nur Default-Listen**
- **Problem:** Test-Daten werden geladen (Dummy-Comics)
- **Lösung:** Bei leerem Start nur "Meine Sammlung" + "Wishlist" erstellen
- **Datei:** `MainView.swift` (loadTestData entfernen/anpassen)

**4. Löschen-Button Styling**
- **Problem:** Button im Comic-Detail nicht optimal
- **Lösung:** 
  - Position: Mittig/Unten zentriert
  - Style: `.destructive` (rot)
- **Datei:** `ComicDetailView.swift`

**5. Icon-Picker verbessern**
- **Problem:** 
  - "list.bullet" sollte nicht für normale Listen wählbar sein
  - Icon-Namen statt visuelle Icons
- **Lösung:**
  - Filtered Icon-Liste (je nach `istReadingOrder`)
  - Visual Picker mit SF Symbols
- **Datei:** `AddListeSheet.swift`, `EditListeSheet.swift`

**6. Padding-Problem: "Neue Reading Order" Sheet**
- **Problem:** Platzhalter-Text "z.B. DC Rebirth Timeline" wird vom TextField überlappiert
- **Lösung:** Mehr Spacing zwischen Label und TextField ODER Platzhalter als `prompt` Parameter
- **Datei:** `AddReadingOrderSheet.swift`

---

### Session 2: Drag & Drop Feature (1-2 Stunden)

**Feature:** Comics aus normalen Listen per Drag & Drop zu Reading Orders hinzufügen

**Design-Entscheidungen:**
- ✅ **COPY-Modus:** Comic bleibt in ursprünglicher Liste
- ✅ **Drop-Position:** Immer am Ende einfügen (als letzter Entry)
- ✅ **Duplikat-Handling:** Alert zeigen: "Comic bereits in dieser Reading Order"

**Workflow:**
```
Normal-Liste (Grid)              Reading Order (Liste)
┌─────────┐                      
│ [📷]    │                       1. [📷] Batman vol. 1
│ Wonder  │  ─drag→               2. [📷] Superman vol. 1
│ Woman   │                       3. [📷] Flash vol. 1
└─────────┘                       4. [📷] Wonder Woman ← hier eingefügt
```

**Technische Umsetzung:**

1. **ComicCard bereits draggable** (funktioniert zwischen Listen)
   - Muss auch für Reading Orders funktionieren

2. **Reading Order View als Drop-Zone**
   - `ReadingOrderContentView` oder Entry-Liste als Drop-Target
   - `.onDrop` Handler hinzufügen

3. **Drop-Handler Logik:**
```swift
func handleComicDrop(providers: [NSItemProvider], liste: ComicListe) -> Bool {
    guard liste.istReadingOrder else { return false }
    
    // 1. Comic-ID aus Drag-Data extrahieren
    // 2. Prüfen ob Comic bereits in Reading Order
    //    → Falls ja: Alert zeigen, return false
    // 3. Neuen ReadingOrderEntry erstellen
    //    - position = max(existingPositions) + 1
    //    - comic = gefundener Comic
    // 4. Entry zur Liste hinzufügen
    // 5. modelContext.save()
    
    return true
}
```

4. **Duplikat-Check:**
```swift
let existingComicIDs = liste.readingOrderEntries.compactMap { $0.comic?.id }
if existingComicIDs.contains(comic.id) {
    // Alert zeigen
    showAlert = true
    alertMessage = "Comic bereits in dieser Reading Order"
    return false
}
```

5. **Visuelles Feedback:**
   - Drop-Zone Highlighting beim Hover
   - Animation beim erfolgreichen Drop

**Dateien:**
- `ReadingOrderContentView.swift` - Drop-Handler
- `ComicCardView.swift` - Drag bereits vorhanden, evtl. anpassen
- `ComicViewModel.swift` - Helper-Funktion `addComicToReadingOrder`

---

## Meine Frage:

Ich möchte mit **Session 1** starten - die 6 Quick Fixes.

Kannst du mir bitte helfen:
1. Die Änderungen in den entsprechenden Dateien vorzunehmen
2. Sicherstellen dass System-Listen korrekt sortiert werden
3. Icon-Picker mit visuellem Feedback zu verbessern
4. Padding-Problem im Sheet zu beheben

**Relevante Dateien sind im Project verfügbar:**
- `/mnt/project/MainView.swift`
- `/mnt/project/SidebarView.swift`
- `/mnt/project/AddListeSheet.swift`
- `/mnt/project/EditListeSheet.swift`
- `/mnt/project/AddReadingOrderSheet.swift`
- `/mnt/project/ComicDetailView.swift`
- `/mnt/project/Comic.swift`

Oder ich lade sie hier hoch: [Dateien anhängen]

Lass uns mit den Quick Fixes starten, dann machen wir Session 2 (Drag & Drop)!

---

## Erwartetes Ergebnis nach Session 1:

✅ Neue Comics haben sinnvolles Default-Datum
✅ Sidebar zeigt immer: Meine Sammlung → Wishlist → Normale Listen → Reading Orders
✅ Erster App-Start ohne Test-Daten
✅ Löschen-Button rot und zentriert
✅ Icon-Picker zeigt echte Icons, "list.bullet" nur für Reading Orders
✅ "Neue Reading Order" Sheet hat korrektes Padding

Bereit zum Loslegen! 🚀
