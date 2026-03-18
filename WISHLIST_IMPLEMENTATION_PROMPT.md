# Implementation Chat Starter-Prompt: Wishlist System

Kopiere den folgenden Text in einen neuen Chat und füge die relevanten Code-Dateien bei:

---

Hallo! Ich arbeite an meiner Comic-Archiv App (Swift/SwiftUI mit SwiftData) und möchte ein wichtiges neues Feature implementieren: **Wishlist System**.

## Aktueller Stand:
✅ Reading Order System komplett implementiert (Phase 1-4)
- Comics verwalten, Listen erstellen, Drag & Drop
- Reading Orders mit nummerierten Einträgen
- Platzhalter-System für Comics die noch nicht in der Sammlung sind
- Status-System: ✅ Gelesen, 📖 Ungelesen, 🛒 Zu kaufen

## Problem:
Aktuell sind Platzhalter nur als String (`placeholderName`) in `ReadingOrderEntry` gespeichert. Das führt zu:
- ❌ Duplikaten wenn derselbe Comic in mehreren Reading Orders vorkommt
- ❌ Keine zentrale Übersicht was noch gekauft werden muss
- ❌ Manuelle Arbeit beim Konvertieren von Platzhalter → Comic

## Ziel: Wishlist System (Phase 4.5)

### Konzept:
**Zwei feste System-Listen (nicht löschbar):**
- 📚 **Meine Sammlung** (`istHauptliste = true`) - Alle Comics die ich besitze
- 🛒 **Wishlist** (`istWishlist = true`) - Alle Comics die ich noch kaufen will

### Kernfunktionen:

**1. Automatische Synchronisation:**
```
Platzhalter in Reading Order erstellt
   ↓
Automatisch zur Wishlist hinzugefügt

Comic zur Sammlung hinzugefügt
   ↓
Aus Wishlist entfernt + Alle Platzhalter mit diesem Namen → Comic konvertiert

Platzhalter aus Reading Order gelöscht
   ↓
Bleibt in Wishlist erhalten (kann in anderen Reading Orders sein)
```

**2. Shared Placeholder Model:**
Statt String-Namen ein eigenes Model:
```swift
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
```

**3. Wishlist-Ansicht:**
- Grid-View mit allen Platzhalter-Comics
- Context Menu: "Zur Sammlung hinzufügen", "Löschen", "In Reading Orders"
- Direkt Comics zur Wishlist hinzufügen (ohne Reading Order)

**4. Migration:**
Beim App-Start: Alle existierenden `placeholderName` Einträge → `PlaceholderComic` konvertieren

---

## Technische Details:

### Datenmodell-Änderungen:

**ComicListe.swift erweitern:**
```swift
@Model
final class ComicListe {
    var istHauptliste: Bool = false
    var istWishlist: Bool = false      // ← NEU
    var istReadingOrder: Bool = false
    // ... rest bleibt gleich
}
```

**Neues Model: PlaceholderComic.swift:**
```swift
@Model
final class PlaceholderComic {
    var id: UUID
    var name: String
    var erstelltAm: Date
    
    @Relationship(deleteRule: .nullify, inverse: \ReadingOrderEntry.placeholder)
    var readingOrderEntries: [ReadingOrderEntry]
    
    var inWishlist: Bool
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.erstelltAm = Date()
        self.inWishlist = true
        self.readingOrderEntries = []
    }
}
```

**ReadingOrderEntry.swift erweitern:**
```swift
@Model
final class ReadingOrderEntry {
    // ... existing properties ...
    
    @Relationship(deleteRule: .nullify, inverse: \Comic.readingOrderEntries)
    var comic: Comic?
    
    @Relationship(deleteRule: .nullify)
    var placeholder: PlaceholderComic?  // ← NEU
    
    var placeholderName: String?        // ← DEPRECATED, wird durch Migration ersetzt
    
    // ... rest ...
    
    var isPlaceholder: Bool {
        placeholder != nil || placeholderName != nil
    }
    
    var displayName: String {
        comic?.titel ?? placeholder?.name ?? placeholderName ?? "Unbekannt"
    }
}
```

**Comic.swift erweitern:**
```swift
@Model
final class Comic {
    // ... existing properties ...
    
    @Relationship(deleteRule: .nullify)
    var readingOrderEntries: [ReadingOrderEntry]?  // ← Falls noch nicht vorhanden
    
    // ... rest ...
}
```

---

## Implementation-Phasen:

### Phase A: Datenmodell (2-3h)
1. ✅ `PlaceholderComic` Model erstellen
2. ✅ `ComicListe.istWishlist` hinzufügen
3. ✅ `ReadingOrderEntry.placeholder` Beziehung hinzufügen
4. ✅ SwiftData Relationships testen

### Phase B: System-Listen Setup (1h)
1. ✅ Beim App-Start: Wishlist prüfen/erstellen
2. ✅ System-Listen (Hauptliste + Wishlist) nicht löschbar machen
3. ✅ Sidebar: Wishlist-Eintrag hinzufügen

### Phase C: Migration (1h)
1. ✅ Alle bestehenden `placeholderName` Strings finden
2. ✅ `PlaceholderComic` Objekte erstellen
3. ✅ `ReadingOrderEntry.placeholder` Links setzen
4. ✅ Zur Wishlist hinzufügen

### Phase D: Auto-Sync Logik (2h)
1. ✅ Platzhalter erstellen → `PlaceholderComic` + Wishlist
2. ✅ Comic zur Sammlung → Wishlist entfernen + Platzhalter konvertieren
3. ✅ Platzhalter löschen → Wishlist-Status prüfen

### Phase E: Wishlist UI (2h)
1. ✅ Wishlist-Ansicht (Grid mit Platzhalter-Cards)
2. ✅ Context Menu Implementation
3. ✅ "Zur Sammlung hinzufügen" Flow

**Gesamtaufwand:** 7-8 Stunden

---

## Meine Frage:

Ich möchte mit **Phase A** starten: Das Datenmodell erweitern.

Kannst du dir bitte meine aktuellen Models anschauen und mir helfen:
1. Das neue `PlaceholderComic` Model korrekt zu erstellen
2. Die Beziehungen in `ReadingOrderEntry`, `Comic`, und `ComicListe` anzupassen
3. SwiftData Relationships richtig zu konfigurieren (deleteRule, inverse)

**Relevante Dateien sind im Project verfügbar:**
- `/mnt/project/Comic.swift`
- `/mnt/project/ComicListe.swift`
- `/mnt/project/ReadingOrderEntry.swift`

Oder ich lade sie hier hoch: [Dateien anhängen]

Lass uns sicherstellen, dass die Datenmodell-Änderungen sauber und SwiftData-konform sind, bevor wir mit der Logik weitermachen!

---

## Erwartetes Ergebnis nach Phase A:

```swift
// Neue Platzhalter erstellen können:
let placeholder = PlaceholderComic(name: "Superman vol. 1")
modelContext.insert(placeholder)

let entry = ReadingOrderEntry(position: 1, placeholder: placeholder)
entry.liste = readingOrder
modelContext.insert(entry)

// Testen:
print(entry.isPlaceholder)  // true
print(entry.displayName)    // "Superman vol. 1"
print(placeholder.readingOrderEntries.count)  // 1
```

Bereit zum Loslegen! 🚀
