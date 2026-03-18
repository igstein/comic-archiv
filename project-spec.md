# Comic-Archiv - Projekt-Spezifikation

## 📋 Projekt-Übersicht

**Name:** Comic-Archiv  
**Plattform:** macOS (native App)  
**Technologie:** Swift + SwiftUI  
**Ziel:** Desktop-Anwendung zur Verwaltung einer persönlichen Comic-Sammlung mit flexiblem Listen-System und Drag & Drop Funktionalität

---

## 🎯 Haupt-Features

### 1. Comic-Verwaltung
- Comics zur Sammlung hinzufügen, bearbeiten und löschen
- Detailansicht für jeden Comic
- Cover-Bild Upload und Anzeige

### 2. Flexibles Listen-System
- Haupt-Archiv: "Meine Sammlung" (enthält alle Comics)
- Benutzerdefinierte Listen erstellen, umbenennen und löschen
- Comics können in mehreren Listen gleichzeitig sein
- Beispiele: "Gelesen", "Noch zu lesen", "Marvel", "DC", "Favoriten"

### 3. Drag & Drop
- Comics zwischen Listen per Drag & Drop verschieben
- Intuitive Bedienung nach macOS-Standard
- Visuelles Feedback beim Ziehen

### 4. Datenpersistenz
- Lokale Speicherung aller Daten
- Cover-Bilder lokal gespeichert
- Automatisches Speichern bei Änderungen

---

## 📊 Datenmodell

### Comic
```swift
struct Comic {
    id: UUID
    titel: String
    autor: String
    zeichner: String
    verlag: String
    erscheinungsdatum: Date
    nummer: String              // Band/Ausgabe-Nummer
    coverBild: Data?            // Optional - Bild als Data
    gelesen: Bool               // Gelesen/Ungelesen Status
    erstelltAm: Date
}
```

### Liste
```swift
struct ComicListe {
    id: UUID
    name: String
    icon: String?               // Optional - SF Symbol Name
    comicIDs: [UUID]            // Referenzen zu Comics
    erstelltAm: Date
    istHauptliste: Bool         // "Meine Sammlung" kann nicht gelöscht werden
}
```

---

## 🎨 UI/UX Design

### Layout-Struktur
```
┌─────────────────────────────────────────────────────────┐
│  Comic-Archiv                                    [+]    │
├───────────────┬─────────────────────────────────────────┤
│               │                                         │
│  📚 Listen    │         Comic-Grid/Liste               │
│               │                                         │
│  • Meine      │    ┌────┐  ┌────┐  ┌────┐            │
│    Sammlung   │    │📖  │  │📖  │  │📖  │            │
│               │    │    │  │    │  │    │            │
│  • Gelesen    │    └────┘  └────┘  └────┘            │
│               │                                         │
│  • Noch zu    │    ┌────┐  ┌────┐  ┌────┐            │
│    lesen      │    │📖  │  │📖  │  │📖  │            │
│               │    │    │  │    │  │    │            │
│  • Marvel     │    └────┘  └────┘  └────┘            │
│               │                                         │
│  [+ Neue      │                                         │
│     Liste]    │                                         │
│               │                                         │
└───────────────┴─────────────────────────────────────────┘
```

### Hauptansicht
- **Sidebar (links)**: Liste aller benutzerdefinierten Listen
- **Hauptbereich (rechts)**: Grid-Ansicht der Comics in der ausgewählten Liste
- **Toolbar (oben)**: "Comic hinzufügen" Button, Suchfeld (später)

### Comic-Karte (Grid-Element)
- Cover-Bild (falls vorhanden, sonst Placeholder)
- Titel
- Autor
- Nummer
- Gelesen-Status (z.B. grüner Haken oder Badge)

### Detail-Ansicht (beim Klick auf Comic)
- Größeres Cover-Bild
- Alle Daten editierbar
- "Gelesen"-Toggle
- "Löschen"-Button
- "Speichern"/"Abbrechen"-Buttons

### Listen-Verwaltung
- Neue Liste erstellen: Modal/Sheet mit Name-Eingabe
- Liste umbenennen: Kontextmenü oder Doppelklick
- Liste löschen: Kontextmenü (außer "Meine Sammlung")

---

## 🔧 Technische Details

### Technologie-Stack
- **Sprache**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Datenpersistenz**: Core Data oder SwiftData (je nach macOS Version)
- **Bildverwaltung**: FileManager für lokale Speicherung
- **Min. macOS Version**: macOS 13.0 (Ventura)

### Architektur
- **MVVM Pattern**: Model-View-ViewModel
- **SwiftUI App Lifecycle**
- **Environment Objects** für geteilten State
- **ObservableObject** für Daten-Manager

### Datei-Struktur
```
ComicArchiv/
├── App/
│   └── ComicArchivApp.swift
├── Models/
│   ├── Comic.swift
│   └── ComicListe.swift
├── ViewModels/
│   └── ComicViewModel.swift
├── Views/
│   ├── MainView.swift
│   ├── SidebarView.swift
│   ├── ComicGridView.swift
│   ├── ComicDetailView.swift
│   └── Components/
│       ├── ComicCard.swift
│       └── ListeRow.swift
├── Services/
│   ├── DataManager.swift
│   └── ImageManager.swift
└── Resources/
    └── Assets.xcassets
```

---

## 📅 Entwicklungs-Roadmap

### Phase 1: Grundgerüst (Woche 1)
- [x] Projekt-Setup in Xcode
- [ ] Basis-Datenmodelle (Comic, Liste)
- [ ] Haupt-Layout mit Sidebar + Grid
- [ ] Dummy-Daten zum Testen

### Phase 2: Daten-Management (Woche 2)
- [ ] Comic hinzufügen/bearbeiten/löschen
- [ ] Listen erstellen/umbenennen/löschen
- [ ] Datenpersistenz implementieren (Core Data/SwiftData)
- [ ] Comic-zu-Liste Zuordnung

### Phase 3: Drag & Drop (Woche 3)
- [ ] Drag & Drop zwischen Listen
- [ ] Visuelles Feedback
- [ ] Drop-Zonen gestalten

### Phase 4: Cover-Bilder (Woche 4)
- [ ] Bild-Upload Funktion
- [ ] Lokale Bild-Speicherung
- [ ] Bild-Anzeige in Grid und Detail
- [ ] Placeholder für Comics ohne Cover

### Phase 5: Polish & Features (Woche 5+)
- [ ] UI-Verbesserungen
- [ ] Animationen
- [ ] Gelesen-Status System verfeinern
- [ ] Fehlerbehandlung
- [ ] App-Icon

### Zukünftige Features (Optional)
- [ ] Suchfunktion
- [ ] Filter (nach Verlag, Autor, etc.)
- [ ] Sortierung (Titel, Datum, etc.)
- [ ] Export (CSV, PDF)
- [ ] Bewertungssystem (Sterne)
- [ ] Notizen pro Comic
- [ ] Dark Mode Support
- [ ] iCloud Sync

---

## 🎓 Lern-Ziele

Durch dieses Projekt lernst du:
- ✅ Swift Grundlagen und Best Practices
- ✅ SwiftUI für moderne Mac-Apps
- ✅ Daten-Management und Persistenz
- ✅ Drag & Drop in SwiftUI
- ✅ Bild-Handling in macOS
- ✅ MVVM Architektur-Pattern
- ✅ App-Struktur und Organisation
- ✅ **AI-gestütztes Programmieren mit Claude**

---

## 📝 Wichtige Hinweise

### Code-Style
- Swift Naming Conventions folgen
- Dokumentation für komplexe Funktionen
- Aussagekräftige Variable- und Funktionsnamen (auf Deutsch für Fachbegriffe, auf Englisch für Code)

### Testing
- Regelmäßig testen nach jedem Feature
- Edge Cases beachten (leere Listen, keine Cover-Bilder, etc.)
- Mit echten Comic-Daten testen

### Versionierung
- Regelmäßige Commits sinnvoll (später, wenn du Git nutzt)
- Features in Branches entwickeln (später)

---

**Version:** 1.0  
**Erstellt:** Januar 2026  
**Autor:** Igy (mit Claude AI)
